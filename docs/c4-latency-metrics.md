# C4 Latency Metrics

## Overview

The C4 Latency Metrics provide comprehensive latency monitoring aligned with the [C4 model](https://c4model.com/) architecture principles. These metrics enable precise performance tracking across different layers of your application stack with consistent C4 architectural labels.

## Metrics

| Metric | Description | When to Use |
|--------|-------------|-------------|
| `latency_http_request_seconds` | Complete HTTP request latency (headers + body) from inside the container | **SLO basis**: "95% of /checkout calls < 300ms". First metric to check when clients complain about slowness |
| `latency_http_middleware_seconds` | Time spent in middleware (auth, rate-limiter, etc.) | **Quantify middleware cost** before/after deployment. Identify if slowness is in auth middleware vs business logic |
| `latency_db_query_seconds` | Database query execution time | **Correlate with request latency** to determine what % of time is spent in database. Find which table/query is slow |
| `latency_cache_operation_seconds` | Cache operation latency (get, set, delete) | **Detect silent cache degradation**. A slow cache becomes an "anti-cache" |
| `latency_http_call_seconds` | Outbound HTTP calls to external services | **Justify circuit breakers** with data. Identify slow external dependencies |
| `latency_function_execution_seconds` | Individual function execution time | **Fine-grained tracking** for specific algorithms. Prove refactoring improvements commit-by-commit |
| `latency_queue_publish_seconds` | Time to publish message to queue | **Detect when queue publishing impacts request latency**. Verify publish time < 5ms |
| `latency_queue_process_seconds` | Worker message processing time | **Scale worker pods**: if P95 > 1s → scale out |

## Common C4 Labels

All metrics include these mandatory C4 architecture labels:

- **`system`**: System identifier (C4 System level) - e.g., "ecommerce", "payment-platform"
- **`container`**: Container identifier (C4 Container level) using `<applicationname>-<type>` format - e.g., "checkout-api", "payment-worker"
- **`component`**: Component name (C4 Component level) - e.g., "payment-handler", "cart-manager"

See [C4 Labels Documentation](c4-labels.md) for detailed guidance on label selection and naming standards.

## Metric-Specific Labels

Each metric adds specific labels for granular tracking:

### `latency_http_request_seconds`
- `method`: HTTP method (GET, POST, PUT, DELETE)
- `route`: HTTP route pattern (e.g., `/api/v1/checkout`)
- `status`: HTTP status code (200, 404, 500)

### `latency_http_middleware_seconds`
- `middleware`: Middleware name (e.g., auth, rate-limiter, cors)
- `phase`: Middleware phase (before, after, error)

### `latency_db_query_seconds`
- `query_type`: Query type (select, insert, update, delete, transaction)
- `table`: Target table name

### `latency_cache_operation_seconds`
- `cache_name`: Cache instance name (e.g., redis-primary, memcached-sessions)
- `operation`: Cache operation (get, set, delete, mget, mset)

### `latency_http_call_seconds`
- `target_system`: Target system/service name (e.g., bank-api, payment-gateway)
- `endpoint`: Target endpoint (e.g., `/api/v1/charge`)

### `latency_function_execution_seconds`
- `function`: Function name
- `class`: Class/module name (if applicable)

### `latency_queue_publish_seconds` / `latency_queue_process_seconds`
- `queue`: Queue/topic name
- `event_type`: Event type being published/processed

## Usage Examples

### 1. Define SLO for Critical Endpoint

```promql
# 95% of /checkout requests should complete in < 300ms
histogram_quantile(0.95,
  rate(latency_http_request_seconds_bucket{
    system="ecommerce",
    route="/api/v1/checkout"
  }[5m])
) < 0.3
```

### 2. Identify Middleware Bottlenecks

```promql
# Compare middleware overhead
histogram_quantile(0.95,
  rate(latency_http_middleware_seconds_bucket[5m])
) by (middleware)
```

### 3. Database Performance Analysis

```promql
# What % of request time is spent in database?
(
  sum(rate(latency_db_query_seconds_sum{component="payment-handler"}[5m]))
  /
  sum(rate(latency_http_request_seconds_sum{component="payment-handler"}[5m]))
) * 100
```

### 4. Cache Health Check

```promql
# Alert if cache GET operations exceed 10ms (cache degradation)
histogram_quantile(0.95,
  rate(latency_cache_operation_seconds_bucket{
    cache_name="redis-primary",
    operation="get"
  }[5m])
) > 0.01
```

### 5. External Dependency Tracking

```promql
# Identify slow external dependencies
histogram_quantile(0.99,
  rate(latency_http_call_seconds_bucket[5m])
) by (target_system)
```

### 6. Worker Scaling Decision

```promql
# Scale workers if message processing P95 > 1s
histogram_quantile(0.95,
  rate(latency_queue_process_seconds_bucket{
    queue="payment-events"
  }[5m])
) > 1
```

### 7. Function Performance Regression Detection

```promql
# Compare function performance before/after deployment
histogram_quantile(0.95,
  rate(latency_function_execution_seconds_bucket{
    function="calculateTax"
  }[5m])
)
```

## Alert Examples

### Critical Request Latency

```yaml
- alert: CriticalRequestLatency
  expr: |
    histogram_quantile(0.95,
      rate(latency_http_request_seconds_bucket[5m])
    ) > 1
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Request latency P95 > 1s"
    description: "95th percentile request latency is {{ $value }}s"
```

### Slow Database Queries

```yaml
- alert: SlowDatabaseQueries
  expr: |
    histogram_quantile(0.99,
      rate(latency_db_query_seconds_bucket{query_type="select"}[5m])
    ) > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "SELECT queries critically slow"
    description: "P99 SELECT query latency is {{ $value }}s (table: {{ $labels.table }})"
```

### Cache Anti-Pattern

```yaml
- alert: CacheAntiPattern
  expr: |
    histogram_quantile(0.95,
      rate(latency_cache_operation_seconds_bucket[5m])
    ) > 0.1
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "Cache latency exceeds 100ms - becoming anti-pattern"
    description: "Cache {{ $labels.cache_name }} operation {{ $labels.operation }} P95: {{ $value }}s"
```

### Slow External Dependency

```yaml
- alert: SlowExternalDependency
  expr: |
    histogram_quantile(0.95,
      rate(latency_http_call_seconds_bucket[5m])
    ) > 1
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "External service slow - consider circuit breaker"
    description: "Calls to {{ $labels.target_system }} P95: {{ $value }}s"
```

## Best Practices

### 1. Start with Request Latency
Always instrument `latency_http_request_seconds` first - it's the foundation for SLOs and the first place to look when investigating performance issues.

### 2. Add Granular Metrics Incrementally
Add more specific metrics (middleware, database, function) as needed to diagnose bottlenecks. Don't instrument everything upfront.

### 3. Use Consistent C4 Labels
Ensure all metrics use the same C4 label values across your organization:
- Use a central label registry or service mesh to inject labels automatically
- Document your C4 architecture and label conventions

### 4. Correlate Across Layers
Use the same `component` label value across different metric types to correlate:
```promql
# What % of payment-handler time is in database vs outbound calls?
sum(rate(latency_db_query_seconds_sum{component="payment-handler"}[5m]))
/
sum(rate(latency_http_request_seconds_sum{component="payment-handler"}[5m]))
```

### 5. Set Appropriate Percentiles
- **P50 (median)**: Typical performance
- **P95**: Good SLO target (most users have good experience)
- **P99**: Catch outliers before they become widespread
- **P99.9**: For ultra-critical paths only (expensive to track)

### 6. Choose the Right Buckets
The C4 latency metrics use standard histogram buckets optimized for each use case:
- HTTP/API: `#HTTPBuckets` (5ms - 10s)
- Database: `#DatabaseBuckets` (100µs - 5s)
- Cache: `#CacheBuckets` (100µs - 100ms)
- Function: `#HTTPStrictBuckets` (1ms - 1s)
- Queue: `#MessageQueueBuckets` (10ms - 5min)

See `primitives/histogram/latency.cue` for details on when to use each bucket set.

### 7. Monitor Cardinality
Watch out for label cardinality explosion:
- **Good**: `route="/api/v1/users"` (route pattern)
- **Bad**: `route="/api/v1/users/12345"` (route with ID)
- Use route patterns, not full paths with parameters

### 8. Baseline Before Optimizing
Always measure current performance before making changes:
```bash
# Capture baseline
curl -s http://localhost:9090/api/v1/query?query='histogram_quantile(0.95, rate(latency_http_request_seconds_bucket[5m]))'

# Make changes, deploy, compare
```

## Integration

### Go Example (Prometheus Client)

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    requestLatency = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Namespace: "latency",
            Subsystem: "http",
            Name:      "request_seconds",
            Help:      "Complete HTTP request latency",
            Buckets:   []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
        },
        []string{"system", "container", "component", "method", "route", "status"},
    )
)

func trackLatency(system, container, component, method, route string, statusCode int, duration float64) {
    requestLatency.WithLabelValues(
        system,
        container,
        component,
        method,
        route,
        strconv.Itoa(statusCode),
    ).Observe(duration)
}
```

### Python Example (prometheus_client)

```python
from prometheus_client import Histogram

request_latency = Histogram(
    'request_seconds',
    'Complete HTTP request latency',
    labelnames=['system', 'container', 'component', 'method', 'route', 'status'],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
    namespace='latency',
    subsystem='http',
)

def track_latency(system, container, component, method, route, status, duration):
    request_latency.labels(
        system=system,
        container=container,
        component=component,
        method=method,
        route=route,
        status=str(status),
    ).observe(duration)
```

## References

- [C4 Model](https://c4model.com/) - Architecture documentation standard
- [Prometheus Histogram Best Practices](https://prometheus.io/docs/practices/histograms/)
- [promener-standards histogram buckets](../primitives/histogram/latency.cue)
- [Choosing Histogram vs Summary](histogram-vs-summary.md)

## See Also

- [Standard HTTP Metrics](../metrics/http/) - Basic HTTP metrics without C4 labels
- [Database Metrics](../metrics/database/) - Database-specific metrics
- [Cache Metrics](../metrics/cache/) - Cache-specific metrics
- [Example Usage](../examples/c4-latency-example.cue) - Complete example
