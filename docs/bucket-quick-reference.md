# Bucket Quick Reference Guide

Guide rapide pour choisir les bons buckets pour vos histogrammes.

## Sélection Rapide par Use Case

| Use Case | Bucket Standard | Plage | Quand utiliser |
|----------|----------------|-------|----------------|
| **API HTTP standard** | `#HTTPLatencyBuckets` | 5ms - 10s | La plupart des APIs web publiques |
| **API haute performance** | `#HTTPLatencyBucketsStrict` | 1ms - 1s | APIs internes, microservices rapides |
| **Requêtes SQL transactionnelles** | `#DatabaseQueryLatencyBucketsOLTP` | 100µs - 500ms | SELECT, INSERT, UPDATE simples |
| **Requêtes SQL analytiques** | `#DatabaseQueryLatencyBucketsOLAP` | 10ms - 5min | Reports, aggregations, data warehouse |
| **Requêtes SQL génériques** | `#DatabaseQueryLatencyBuckets` | 100µs - 5s | Mix OLTP/OLAP |
| **Opérations cache** | `#CacheLatencyBuckets` | 100µs - 100ms | Redis, Memcached, in-memory cache |
| **Appels gRPC** | `#GRPCLatencyBuckets` | 1ms - 30s | Communication service-to-service |
| **Message queue processing** | `#MessageProcessingLatencyBuckets` | 10ms - 5min | Kafka, RabbitMQ consumers |
| **Jobs asynchrones** | `#BackgroundJobLatencyBuckets` | 100ms - 1h | Cron, workers, batch jobs |
| **GC pauses (Go)** | `#GCPauseBuckets` | 10µs - 100ms | Garbage collection monitoring |
| **Tailles HTTP/gRPC** | `#PayloadSizeBuckets` | 100B - 100MB | Request/response body sizes |
| **Tailles cache** | `#PayloadSizeBucketsSmall` | 10B - 1MB | Cache entries, small messages |
| **Upload fichiers** | `#PayloadSizeBucketsLarge` | 1KB - 10GB | File uploads, video, large data |

## Exemples d'Utilisation

### API REST Standard

```cue
http_request_duration_seconds: {
    type: "histogram"
    buckets: standards.#HTTPLatencyBuckets
    // [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
}
```

**Interprétation:**
- < 5ms: Excellent (cache hits, très simple)
- 5-50ms: Bon (requêtes DB simples)
- 50-250ms: Acceptable (quelques queries, business logic)
- 250ms-1s: Lent (besoin d'optimisation)
- > 1s: Problème (investigate!)

### Database OLTP

```cue
db_query_duration_seconds: {
    type: "histogram"
    buckets: standards.#DatabaseQueryLatencyBucketsOLTP
    // [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5]
}
```

**Interprétation:**
- < 1ms: Excellent (index hits, primary key lookups)
- 1-10ms: Bon (simple JOINs, small scans)
- 10-50ms: Acceptable (complex queries)
- 50-100ms: Lent (needs optimization)
- > 100ms: Problème (missing index, full scans)

### Cache Operations

```cue
cache_get_duration_seconds: {
    type: "histogram"
    buckets: standards.#CacheLatencyBuckets
    // [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1]
}
```

**Interprétation:**
- < 1ms: Excellent (local cache, in-memory)
- 1-5ms: Bon (Redis local network)
- 5-25ms: Acceptable (Redis remote, some network latency)
- > 25ms: Problème (network issues, cache server overloaded)

## Décisions Rapides

### Vous avez un SLA?

**Oui, SLA = 200ms pour p95:**
```cue
// Assurez-vous d'avoir des buckets autour de 200ms
buckets: [0.005, 0.01, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 1, 2.5, 5]
//                                      ^^^  SLA bucket
```

**Requête de validation:**
```promql
# % requests under SLA
sum(rate(metric_bucket{le="0.2"}[5m]))
/
sum(rate(metric_count[5m]))
> 0.95  # Should be > 95%
```

### Vous ne connaissez pas la distribution?

1. **Démarrez avec un summary temporaire:**
```cue
temp_metric: {
    type: "summary"
    objectives: standards.#StandardPercentiles
}
```

2. **Mesurez pendant quelques heures**

3. **Analysez les quantiles:**
```promql
temp_metric{quantile="0.5"}   # p50
temp_metric{quantile="0.9"}   # p90
temp_metric{quantile="0.99"}  # p99
```

4. **Créez des buckets appropriés:**
- Min bucket: ~p1 / 2
- Max bucket: ~p99 * 2
- Plus de détails autour p50-p95

### Règles d'Or

✅ **DO:**
- Mesurer avant de choisir
- Couvrir toute la plage (min à max)
- Plus de buckets près des SLA
- 10-15 buckets pour équilibrer cardinality/précision

❌ **DON'T:**
- Trop de buckets (>20 = cardinality explosion)
- Gaps énormes (0.01, 10 = no visibility 0.01-10)
- Tous les buckets sous/sur les valeurs réelles
- Deviner sans données

## Validation de vos Buckets

### Test 1: Distribution

```promql
# Voir la distribution par bucket
sum by (le) (rate(your_metric_bucket[5m]))
```

**Problème:** Tout dans le premier bucket → buckets trop larges
**Problème:** Tout dans +Inf → buckets trop petits
**OK:** Distribution uniforme ou normale

### Test 2: Quantiles

```promql
# p95 latency
histogram_quantile(0.95, rate(your_metric_bucket[5m]))
```

**Problème:** Toujours 0 ou +Inf → mauvais buckets
**OK:** Valeur cohérente avec vos observations

### Test 3: SLA Compliance

```promql
# % requests under 200ms
sum(rate(your_metric_bucket{le="0.2"}[5m]))
/
sum(rate(your_metric_count[5m]))
```

**Problème:** Pas de bucket à exactement 0.2 → ajouter le bucket SLA
**OK:** Vous pouvez mesurer votre SLA

## Patterns Communs

### Pattern: Latence avec Tiers

```cue
// Granularité fine pour requests rapides
// Grossière pour requests lentes
buckets: [
    // Tier 1: Excellent (granularité fine)
    0.005, 0.01, 0.025, 0.05,
    // Tier 2: Acceptable (granularité moyenne)
    0.1, 0.25, 0.5,
    // Tier 3: Lent (granularité large)
    1, 2.5, 5, 10
]
```

### Pattern: Tailles Logarithmiques

```cue
// Pour les tailles: croissance exponentielle
buckets: [
    100,      // 100 bytes
    1000,     // 1 KB (10x)
    10000,    // 10 KB (10x)
    100000,   // 100 KB (10x)
    1000000,  // 1 MB (10x)
    10000000  // 10 MB (10x)
]
```

### Pattern: Seuils Métier

```cue
// Basé sur des seuils business
buckets: [
    0.05,   // "instant" user perception
    0.1,    // "fast" threshold
    0.5,    // Company SLA
    1.0,    // User patience limit
    5.0,    // Timeout warning
    10.0    // Actual timeout
]
```

## Ressources

- **Documentation complète:** [`docs/histogram-vs-summary.md`](histogram-vs-summary.md)
- **Définitions CUE:** [`standards/buckets.cue`](../standards/buckets.cue)
- **Exemples:** [`examples/using-standard-buckets.cue`](../examples/using-standard-buckets.cue)
- **Prometheus Best Practices:** https://prometheus.io/docs/practices/histograms/
