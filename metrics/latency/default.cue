package latency

import (
	"github.com/jycamier/promener-standards/schemas"
	"github.com/jycamier/promener-standards/primitives/histogram"
)

// C4 Latency Metrics
// Standard latency metrics with C4 architecture labels
// These metrics provide comprehensive latency monitoring across different layers
// of the application stack, aligned with C4 model architecture principles

#DefaultLatencyMetrics: {
	// #commonLabels is a parameter that should be set when composing these metrics
	#commonLabels: [string]: schemas.#Label
	metrics: {

		// HTTP Request Latency (End-to-End)
	// Measures complete request processing time from container perspective
	// Use: SLO basis - "95% of /checkout calls < 300ms"
	request_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "http"
		type:      "histogram"
		help:      "Complete HTTP request latency including all processing (headers + body) measured from inside the container"
		labels: #commonLabels & {
			method: description: "HTTP method (GET, POST, PUT, DELETE, etc.)"
			route: description:  "HTTP route pattern (e.g., /api/v1/checkout)"
			status: description: "HTTP status code (200, 404, 500, etc.)"
		}
		buckets: histogram.#HTTPBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_request_seconds_bucket{route=\"/checkout\"}[5m]))"
					description: "P95 latency for /checkout endpoint - SLO basis"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_request_seconds_bucket[5m])) by (route)"
					description: "P99 latency by route to identify slow endpoints"
				},
				{
					query:       "sum(rate(latency_request_seconds_count[5m])) by (status, route)"
					description: "Request rate by status and route"
				},
			]
			alerts: [
				{
					name:        "HighRequestLatency"
					expr:        "histogram_quantile(0.95, rate(latency_request_seconds_bucket[5m])) > 0.3"
					description: "95th percentile request latency is above 300ms"
					for:         "5m"
					severity:    "warning"
				},
				{
					name:        "CriticalRequestLatency"
					expr:        "histogram_quantile(0.95, rate(latency_request_seconds_bucket[5m])) > 1"
					description: "95th percentile request latency is above 1 second"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}

	// Middleware Processing Latency
	// Measures time spent in middleware (auth, rate-limiting, etc.)
	// Use: Quantify middleware overhead before/after deployment
	middleware_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "http"
		type:      "histogram"
		help:      "Time spent in middleware processing (rate-limiter, JWT validator, etc.)"
		labels: #commonLabels & {
			middleware: description: "Middleware name (e.g., auth, rate-limiter, cors)"
			phase: description:      "Middleware phase (before, after, error)"
		}
		buckets: histogram.#HTTPBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_http_middleware_seconds_bucket{middleware=\"auth\"}[5m]))"
					description: "P95 authentication middleware latency"
				},
				{
					query:       "sum(rate(latency_http_middleware_seconds_sum[5m])) by (middleware) / sum(rate(latency_http_middleware_seconds_count[5m])) by (middleware)"
					description: "Average latency by middleware to identify bottlenecks"
				},
			]
			alerts: [
				{
					name:        "SlowMiddleware"
					expr:        "histogram_quantile(0.95, rate(latency_http_middleware_seconds_bucket[5m])) > 0.1"
					description: "Middleware is adding more than 100ms to requests"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Database Query Latency
	// Measures database operation time
	// Use: Correlate with request latency to determine % time spent in DB
	query_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "db"
		type:      "histogram"
		help:      "Database query execution time"
		labels: #commonLabels & {
			query_type: description: "Query type (select, insert, update, delete, transaction)"
			table: description:      "Target table name"
		}
		buckets: histogram.#DatabaseBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.99, rate(latency_db_query_seconds_bucket{table=\"cart_items\"}[5m]))"
					description: "P99 latency for cart_items table queries"
				},
				{
					query:       "histogram_quantile(0.95, rate(latency_db_query_seconds_bucket[5m])) by (query_type, table)"
					description: "P95 latency by query type and table to find slow queries"
				},
				{
					query:       "sum(rate(latency_db_query_seconds_sum[5m])) / sum(rate(latency_http_request_seconds_sum[5m]))"
					description: "Percentage of request time spent in database"
				},
			]
			alerts: [
				{
					name:        "SlowDatabaseQueries"
					expr:        "histogram_quantile(0.95, rate(latency_db_query_seconds_bucket[5m])) > 0.5"
					description: "Database queries are taking more than 500ms at P95"
					for:         "10m"
					severity:    "warning"
				},
				{
					name:        "CriticalDatabaseLatency"
					expr:        "histogram_quantile(0.99, rate(latency_db_query_seconds_bucket{query_type=\"select\"}[5m])) > 2"
					description: "SELECT queries are critically slow (>2s at P99)"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}

	// Cache Operation Latency
	// Measures cache read/write time
	// Use: Detect silent cache performance degradation
	operation_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "cache"
		type:      "histogram"
		help:      "Cache operation latency (get, set, delete)"
		labels: #commonLabels & {
			cache_name: description: "Cache instance name (e.g., redis-primary, memcached-sessions)"
			operation: description:  "Cache operation (get, set, delete, mget, mset)"
		}
		buckets: histogram.#CacheBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_cache_operation_seconds_bucket{operation=\"get\"}[5m]))"
					description: "P95 cache GET operation latency"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_cache_operation_seconds_bucket[5m])) by (cache_name, operation)"
					description: "P99 latency by cache instance and operation"
				},
			]
			alerts: [
				{
					name:        "SlowCacheOperations"
					expr:        "histogram_quantile(0.95, rate(latency_cache_operation_seconds_bucket{operation=\"get\"}[5m])) > 0.01"
					description: "Cache GET operations are slower than 10ms - cache may be degraded"
					for:         "5m"
					severity:    "warning"
				},
				{
					name:        "CacheAntiPattern"
					expr:        "histogram_quantile(0.95, rate(latency_cache_operation_seconds_bucket[5m])) > 0.1"
					description: "Cache latency exceeds 100ms - becoming an anti-pattern"
					for:         "10m"
					severity:    "critical"
				},
			]
		}
	}

	// Outbound HTTP Call Latency
	// Measures time spent calling external services
	// Use: Justify circuit breakers and identify slow dependencies
	call_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "http"
		type:      "histogram"
		help:      "Outbound HTTP call latency to external services/APIs"
		labels: #commonLabels & {
			target_system: description: "Target system/service name (e.g., bank-api, payment-gateway)"
			endpoint: description:      "Target endpoint (e.g., /api/v1/charge)"
		}
		buckets: histogram.#HTTPBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_http_call_seconds_bucket{target_system=\"bank-api\"}[5m]))"
					description: "P95 latency for calls to bank-api"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_http_call_seconds_bucket[5m])) by (target_system)"
					description: "P99 latency by target system to identify slow dependencies"
				},
				{
					query:       "sum(rate(latency_http_call_seconds_sum[5m])) / sum(rate(latency_http_request_seconds_sum[5m]))"
					description: "Percentage of request time spent in outbound calls"
				},
			]
			alerts: [
				{
					name:        "SlowExternalDependency"
					expr:        "histogram_quantile(0.95, rate(latency_http_call_seconds_bucket[5m])) > 1"
					description: "External service calls are slow (>1s at P95) - consider circuit breaker"
					for:         "10m"
					severity:    "warning"
				},
				{
					name:        "ExternalServiceTimeout"
					expr:        "histogram_quantile(0.95, rate(latency_http_call_seconds_bucket[5m])) > 5"
					description: "External service extremely slow - likely timing out"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}

	// Function Execution Latency
	// Measures individual function execution time
	// Use: Fine-grained performance tracking for specific algorithms
	execution_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "function"
		type:      "histogram"
		help:      "Individual function execution time for performance-critical code paths"
		labels: #commonLabels & {
			function: description: "Function name"
			class: description:    "Class/module name (if applicable)"
		}
		buckets: histogram.#HTTPStrictBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_function_execution_seconds_bucket{function=\"calculateTax\"}[5m]))"
					description: "P95 execution time for calculateTax function"
				},
				{
					query:       "rate(latency_function_execution_seconds_sum[5m]) / rate(latency_function_execution_seconds_count[5m])"
					description: "Average function execution time"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_function_execution_seconds_bucket[5m])) by (function)"
					description: "P99 latency by function to find bottlenecks"
				},
			]
			alerts: [
				{
					name:        "SlowFunctionExecution"
					expr:        "histogram_quantile(0.95, rate(latency_function_execution_seconds_bucket[5m])) > 0.1"
					description: "Function execution is slow (>100ms at P95)"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Queue Publish Latency
	// Measures time to publish messages to queue
	// Use: Detect when queue publishing impacts request latency
	publish_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "queue"
		type:      "histogram"
		help:      "Time to publish message to queue (Kafka, RabbitMQ, etc.)"
		labels: #commonLabels & {
			queue: description:      "Queue/topic name"
			event_type: description: "Event type being published"
		}
		buckets: histogram.#MessageQueueBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_queue_publish_seconds_bucket{queue=\"orders\"}[5m]))"
					description: "P95 time to publish to orders queue"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_queue_publish_seconds_bucket[5m])) by (queue)"
					description: "P99 publish latency by queue"
				},
			]
			alerts: [
				{
					name:        "SlowQueuePublish"
					expr:        "histogram_quantile(0.95, rate(latency_queue_publish_seconds_bucket[5m])) > 0.005"
					description: "Queue publish is slow (>5ms at P95) - consider async publishing"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Queue Processing Latency
	// Measures worker message processing time
	// Use: Scale worker pods when processing is too slow
	process_seconds: schemas.#Metric & {
		namespace: "latency"
		subsystem: "queue"
		type:      "histogram"
		help:      "Time to process a single message from queue"
		labels: #commonLabels & {
			queue: description:      "Queue/topic name"
			event_type: description: "Event type being processed"
		}
		buckets: histogram.#MessageQueueBuckets
		examples: {
			promql: [
				{
					query:       "histogram_quantile(0.95, rate(latency_queue_process_seconds_bucket{queue=\"payments\"}[5m]))"
					description: "P95 payment worker processing time"
				},
				{
					query:       "histogram_quantile(0.99, rate(latency_queue_process_seconds_bucket[5m])) by (queue, event_type)"
					description: "P99 processing time by queue and event type"
				},
				{
					query:       "sum(rate(latency_queue_process_seconds_count[5m])) by (queue)"
					description: "Message processing rate by queue"
				},
			]
			alerts: [
				{
					name:        "SlowMessageProcessing"
					expr:        "histogram_quantile(0.95, rate(latency_queue_process_seconds_bucket[5m])) > 1"
					description: "Message processing is slow (>1s at P95) - consider scaling workers"
					for:         "10m"
					severity:    "warning"
				},
				{
					name:        "CriticalMessageProcessing"
					expr:        "histogram_quantile(0.95, rate(latency_queue_process_seconds_bucket[5m])) > 5"
					description: "Message processing critically slow (>5s at P95) - queue lag likely"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}
	}
}

// Export the standard metrics
DefaultLatencyMetrics: #DefaultLatencyMetrics
