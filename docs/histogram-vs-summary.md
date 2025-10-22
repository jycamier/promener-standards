# Histogram vs Summary: Guide de Décision

## Vue d'ensemble rapide

| Critère | Histogram | Summary |
|---------|-----------|---------|
| **Agrégation multi-instance** | ✅ Oui | ❌ Non |
| **Quantiles flexibles** | ✅ Serveur (any quantile) | ❌ Client (fixed) |
| **Précision** | Approximative | Exacte |
| **Cardinality** | Basée sur buckets | Basée sur objectives |
| **Performance client** | Très rapide | Plus lent |
| **Use case principal** | Infrastructure, latency | Streaming, exact quantiles |
| **Recommandation** | ⭐ **Preferred** | Rare |

## Histogram (Recommandé 95% du temps)

### Avantages
- **Agrégation**: Combine les métriques de plusieurs instances
- **Flexibilité**: Calcule n'importe quel quantile côté serveur avec `histogram_quantile()`
- **Recording rules**: Peut pré-calculer des agrégations
- **Grafana**: Excellente intégration
- **Performance**: Très rapide côté client (juste incrémenter des compteurs)

### Inconvénients
- **Précision**: Approximative (dépend des buckets choisis)
- **Cardinality**: Nombre de buckets × labels = cardinality
- **Buckets fixes**: Difficile de changer après coup

### Quand utiliser
- ✅ Latence HTTP/API
- ✅ Latence de requêtes DB
- ✅ Temps de traitement
- ✅ Tailles de messages/payloads
- ✅ Durées de jobs/tâches
- ✅ N'importe quelle métrique d'infrastructure

### Exemple
```yaml
http_request_duration_seconds:
  type: histogram
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
```

**Requête PromQL:**
```promql
# p95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Apdex score (requests under 100ms)
sum(rate(http_request_duration_seconds_bucket{le="0.1"}[5m]))
/
sum(rate(http_request_duration_seconds_count[5m]))
```

## Summary (Rare, cas spéciaux)

### Avantages
- **Précision exacte**: Quantiles calculés précisément
- **Streaming**: Pas besoin de connaître la distribution à l'avance
- **No bucket tuning**: Pas besoin de choisir des buckets

### Inconvénients
- ❌ **Pas d'agrégation**: Cannot aggregate across instances
- ❌ **Quantiles fixes**: Définis au démarrage, pas modifiables
- ❌ **Performance**: Plus lent côté client
- ❌ **Pas de recording rules**: Les summaries ne peuvent pas être pré-agrégées

### Quand utiliser
- Monitoring d'une seule instance (pas de scaling horizontal)
- Besoin de quantiles exactes (recherche, expérimentation)
- Données streaming sans distribution connue

### Exemple
```yaml
api_response_time_seconds:
  type: summary
  objectives:
    "0.5": 0.05   # p50 ±5%
    "0.9": 0.01   # p90 ±1%
    "0.99": 0.001 # p99 ±0.1%
```

**Requête PromQL:**
```promql
# p95 is pre-calculated (if defined in objectives)
api_response_time_seconds{quantile="0.95"}

# Cannot calculate new quantiles!
# Cannot aggregate across instances!
```

## Choisir des Buckets pour Histograms

### Règles d'or

1. **Mesurez d'abord**: Ne devinez pas, collectez des données réelles
2. **Couvrez la plage complète**: Du min au max observé
3. **Plus de détails aux seuils critiques**: Plus de buckets près de vos SLA
4. **Espacement exponentiel**: Pour des plages larges (1ms à 10s)
5. **10-15 buckets max**: Balance entre précision et cardinality

### Méthodologie

#### Étape 1: Comprendre votre distribution
```promql
# Observez les valeurs avec un summary temporaire
rate(my_metric_sum[5m]) / rate(my_metric_count[5m])
```

#### Étape 2: Identifiez les seuils importants
- SLA: "95% des requests < 200ms"
- Limites acceptables: "< 100ms = bon, > 1s = problème"
- Seuils business: "checkout doit être < 2s"

#### Étape 3: Choisissez des buckets
```
SLA = 200ms, acceptable = 100ms, problème = 1s

Buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.2, 0.5, 1, 2.5, 5]
         │                           │    │         │
         │                           │    │         └─ Problem threshold
         │                           │    └─────────── SLA
         │                           └──────────────── Acceptable
         └──────────────────────────────────────────── Fast requests
```

#### Étape 4: Validez avec des données réelles
```promql
# Vérifiez la distribution
sum by (le) (rate(http_request_duration_seconds_bucket[5m]))

# La plupart des valeurs doivent être dans les buckets du milieu
# Si tout est dans le premier bucket → buckets trop larges
# Si tout est dans +Inf → buckets trop petits
```

### Exemples par Use Case

#### HTTP API (SLA: p95 < 200ms)
```cue
buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.2, 0.5, 1, 2.5, 5]
//        fast   good  good   ok    SLA  SLA  slow ok  slow
```

#### Database OLTP (SLA: p99 < 50ms)
```cue
buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5]
//        very fast      fast   good  good  SLA   slow  problem
```

#### Cache (Redis/Memcached)
```cue
buckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1]
//        ideal  good    good   ok     slow  slow   problem
```

#### Background Jobs (wide range)
```cue
buckets: [0.1, 1, 5, 10, 30, 60, 300, 600, 1800, 3600]
//        fast   ok  ok  slow     minutes    hours
```

## Standards Réutilisables

Utilisez les définitions de `standards/buckets.cue`:

```cue
import "github.com/jycamier/promener-standards/standards"

http_request_duration_seconds: {
    type: "histogram"
    buckets: standards.#HTTPLatencyBuckets
    // [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
}

cache_operation_duration: {
    type: "histogram"
    buckets: standards.#CacheLatencyBuckets
    // [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1]
}
```

## Dépannage

### "Tous mes samples sont dans le premier bucket"
❌ Vos buckets sont trop larges
```
buckets: [1, 5, 10]  # Trop larges si la plupart des valeurs sont < 1s
```
✅ Ajoutez des buckets plus petits
```
buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 5, 10]
```

### "Tous mes samples sont dans +Inf"
❌ Vos buckets sont trop petits
```
buckets: [0.001, 0.005, 0.01]  # Trop petits si la plupart des valeurs sont > 10ms
```
✅ Étendez la plage
```
buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5]
```

### "Mes quantiles sont imprécis"
❌ Pas assez de buckets autour de la valeur du quantile
```
buckets: [0.01, 1, 10]  # Gap énorme entre 0.01 et 1
```
✅ Ajoutez des buckets intermédiaires
```
buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
```

### "Trop de cardinality"
❌ Trop de buckets × trop de labels
```
buckets: [0.001, 0.002, 0.003, ..., 9.999, 10]  # 10,000 buckets!
labels: {user_id, session_id, ...}              # High cardinality labels
```
✅ Réduisez les buckets et les labels
```
buckets: [0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10]  # 8 buckets
labels: {endpoint, status}                         # Low cardinality
```

## Checklist de Décision

- [ ] Ai-je besoin d'agréger plusieurs instances ? → **Histogram**
- [ ] Ai-je besoin de calculer différents quantiles ? → **Histogram**
- [ ] Est-ce une métrique d'infrastructure (latency, size) ? → **Histogram**
- [ ] Ai-je mesuré la distribution réelle ? → **Oui avant de choisir buckets**
- [ ] Mes buckets couvrent-ils min à max ? → **Oui**
- [ ] Ai-je des buckets près de mes SLA ? → **Oui**
- [ ] Ai-je 10-15 buckets maximum ? → **Oui**
- [ ] Est-ce que summary est vraiment nécessaire ? → **Probablement non**

## Ressources

- [Prometheus Histogram Best Practices](https://prometheus.io/docs/practices/histograms/)
- [When to use Summaries](https://prometheus.io/docs/practices/histograms/#summaries)
- [Apdex Score](https://en.wikipedia.org/wiki/Apdex)
