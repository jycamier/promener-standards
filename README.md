# Promener Standards

Standard metric definitions for [Promener](https://github.com/jycamier/promener) - reusable, validated, and language-agnostic.

## Overview

This repository provides a curated collection of **standard Prometheus metric definitions** organized by domain (HTTP, database, cache, gRPC, runtime, etc.). These standards can be imported and composed in your projects to ensure consistency and best practices across your observability stack.

**Benefits:**
- **Consistency**: Same metric names, labels, and buckets across all services
- **Validation**: CUE ensures your metric definitions are correct before code generation
- **Composition**: Mix and match standard metrics for your specific use case
- **Multi-language**: Works with any language supported by Promener (Go, .NET, Node.js, etc.)

## Repository Structure

```
promener-standards/
├── schemas/              # CUE schemas defining the promener format
│   └── promener.cue      # Main schema
├── metrics/              # Business/domain metric standards
│   ├── http/
│   │   ├── server.cue    # HTTP server metrics
│   │   └── client.cue    # HTTP client metrics
│   ├── database/
│   │   └── sql.cue       # SQL database metrics
│   ├── grpc/
│   │   └── server.cue    # gRPC server metrics
│   ├── cache/
│   │   └── cache.cue     # Cache metrics (Redis, Memcached, etc.)
│   └── runtime/
│       └── go.cue        # Go runtime metrics
├── primitives/           # Technical primitives (reusable components)
│   ├── histogram/
│   │   ├── latency.cue   # Latency buckets (HTTP, DB, cache, gRPC, etc.)
│   │   ├── duration.cue  # Long duration buckets (jobs, batches, sessions)
│   │   └── size.cue      # Size buckets (payload, memory, files)
│   └── summary/
│       └── objectives.cue # Summary objectives/percentiles
└── examples/
    ├── using-standard-buckets.cue  # How to use histogram/summary primitives
    └── go-webapp/
        └── metrics.cue             # Example composition
```

## Available Standards

### Metrics by Domain

#### HTTP
- **`metrics/http/server.cue`**: HTTP server metrics (requests, latency, size, inflight)
- **`metrics/http/client.cue`**: HTTP client metrics (outgoing requests, latency)

#### Database
- **`metrics/database/sql.cue`**: SQL database metrics (connection pool, query performance, transactions)

#### gRPC
- **`metrics/grpc/server.cue`**: gRPC server metrics (requests, latency, message size)

#### Cache
- **`metrics/cache/cache.cue`**: Cache metrics (hit/miss rate, operations, evictions)

#### Runtime
- **`metrics/runtime/go.cue`**: Go runtime metrics (goroutines, memory, GC)

### Primitives (Technical Standards)

#### Histogram Buckets

**`primitives/histogram/latency.cue`** - Latency measurement buckets

- **`#HTTPBuckets`**: 5ms to 10s (most web traffic)
- **`#HTTPStrictBuckets`**: 1ms to 1s (high-performance APIs)
- **`#DatabaseBuckets`**: 100µs to 5s (general SQL)
- **`#DatabaseOLTPBuckets`**: 100µs to 500ms (transactional queries)
- **`#DatabaseOLAPBuckets`**: 10ms to 5min (analytical queries)
- **`#CacheBuckets`**: 100µs to 100ms (Redis, Memcached)
- **`#GRPCBuckets`**: 1ms to 30s (RPC calls)
- **`#MessageQueueBuckets`**: 10ms to 5min (Kafka, RabbitMQ)
- **`#RateLimitBuckets`**: 1ms to 60s (rate limiter delays)
- **`#GCPauseBuckets`**: 10µs to 100ms (Go GC pauses)

**`primitives/histogram/duration.cue`** - Long-running duration buckets

- **`#BackgroundJobBuckets`**: 100ms to 1 hour (async jobs)
- **`#BatchBuckets`**: 1s to 6 hours (ETL, batch processing)
- **`#LongQueryBuckets`**: 1s to 30 minutes (report generation)
- **`#SessionBuckets`**: 1min to 24 hours (user sessions)

**`primitives/histogram/size.cue`** - Size measurement buckets (bytes)

- **`#StandardSizeBuckets`**: 100B to 100MB (HTTP, gRPC messages)
- **`#SmallSizeBuckets`**: 10B to 1MB (cache entries, small messages)
- **`#LargeSizeBuckets`**: 1KB to 10GB (file uploads)
- **`#MemorySizeBuckets`**: 1KB to 10GB (memory allocations)
- **`#DatabaseRowSizeBuckets`**: 100B to 10MB (database row sizes)

#### Summary Objectives

**`primitives/summary/objectives.cue`** - Summary quantile objectives

- **`#StandardObjectives`**: p50, p90, p99 (API monitoring)
- **`#StrictObjectives`**: p50, p90, p99, p99.9 (critical systems)
- **`#BasicObjectives`**: p50, p90, p95 (general monitoring)
- **`#HighPercentileObjectives`**: p90, p99, p99.9, p99.99 (long tail visibility)

See [`docs/histogram-vs-summary.md`](docs/histogram-vs-summary.md) for guidance on choosing between histograms and summaries, and how to select appropriate buckets.

## Usage

### 1. Direct Copy (Simple)

Export a standard to YAML and copy it into your project:

```bash
# Export HTTP server metrics to YAML
cue export metrics/http/server.cue > my-project/metrics.yaml

# Use with promener
cd my-project
promener generate go --input metrics.yaml --output ./metrics
```

### 2. Composition (Recommended)

Create a custom metrics file that composes multiple standards:

```cue
package main

import (
    httpserver "github.com/jycamier/promener-standards/metrics/http:server"
    goruntime "github.com/jycamier/promener-standards/metrics/runtime:go"
    "github.com/jycamier/promener-standards/metrics/database:sql"
)

version: "1.0"

info: {
    title:   "My Application"
    version: "1.0.0"
    package: "metrics"
}

metrics: {
    // Import standard HTTP server metrics
    for name, metric in httpserver.HTTPServerMetrics.metrics {
        "\(name)": metric
    }

    // Import Go runtime metrics
    for name, metric in goruntime.GoRuntimeMetrics.metrics {
        "\(name)": metric
    }

    // Import database metrics
    for name, metric in sql.SQLDatabaseMetrics.metrics {
        "\(name)": metric
    }

    // Add your custom business metrics
    orders_total: {
        namespace: "app"
        subsystem: "business"
        type:      "counter"
        help:      "Total orders processed"
        labels: {
            status: {
                description: "Order status"
            }
        }
    }
}
```

Then export and generate:

```bash
cue export my-metrics.cue > metrics.yaml
promener generate go --input metrics.yaml --output ./metrics
```

### 3. With Customization

You can customize imported metrics with additional labels or configuration:

```cue
metrics: {
    // Import and customize HTTP metrics
    for name, metric in httpserver.HTTPServerMetrics.metrics {
        "\(name)": metric & {
            // Add environment label to all HTTP metrics
            constLabels: {
                environment: {
                    value:       "${ENVIRONMENT:production}"
                    description: "Deployment environment"
                }
            }
        }
    }
}
```

### 4. Using Standard Buckets

Use predefined bucket definitions for consistent histogram metrics:

```cue
package main

import "github.com/jycamier/promener-standards/primitives/histogram"

version: "1.0"

info: {
    title:   "My Application"
    version: "1.0.0"
    package: "metrics"
}

metrics: {
    // HTTP API with standard latency buckets
    http_request_duration_seconds: {
        namespace: "api"
        type:      "histogram"
        help:      "HTTP request duration"
        labels: {
            method: description:  "HTTP method"
            handler: description: "Handler name"
        }
        // Use standard HTTP latency buckets (5ms to 10s)
        buckets: histogram.#HTTP
    }

    // Database with OLTP buckets (fast queries)
    db_query_duration_seconds: {
        namespace: "db"
        type:      "histogram"
        help:      "Database query duration"
        labels: {
            operation: description: "SQL operation"
        }
        // Use OLTP buckets (100µs to 500ms)
        buckets: histogram.#DatabaseOLTP
    }

    // Cache with sub-millisecond buckets
    cache_operation_duration_seconds: {
        namespace: "cache"
        type:      "histogram"
        help:      "Cache operation duration"
        labels: {
            operation: description: "Operation type"
        }
        // Use cache buckets (100µs to 100ms)
        buckets: histogram.#Cache
    }
}
```

See [`examples/using-standard-buckets.cue`](examples/using-standard-buckets.cue) for more examples.

## Validation

Validate your metrics definitions against the schema:

```bash
# Validate a standard
cue vet standards/http/server.cue schemas/promener.cue

# Validate your custom metrics
cue vet my-metrics.cue schemas/promener.cue

# Format all CUE files
cue fmt -s ./...
```

## Contributing

To add new standards:

1. Create a new CUE file in the appropriate `standards/` subdirectory
2. Follow the schema defined in `schemas/promener.cue`
3. Include comprehensive labels, examples, and alerts
4. Validate with `cue vet`
5. Submit a PR

## Examples

See the `examples/` directory for complete examples:
- **`examples/go-webapp/`**: Full-stack Go web application with HTTP, database, cache, and runtime metrics

## License

MIT

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details
