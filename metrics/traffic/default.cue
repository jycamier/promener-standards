package traffic

import (
	"github.com/jycamier/promener-standards/schemas"
)

// C4 Traffic Metrics
// Standard traffic/throughput metrics with C4 architecture labels
// These metrics provide comprehensive traffic monitoring across different layers
// of the application stack, aligned with C4 model architecture principles

#DefaultTrafficMetrics: {
	// #commonLabels is a parameter that should be set when composing these metrics
	#commonLabels: [string]: schemas.#Label

	metrics: {

		// HTTP Request Total
	// Counts all HTTP requests received by the container
	// Use: Calculate throughput (req/s) and error rates for SLI
	http_requests_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "http"
		type:      "counter"
		help:      "Total number of HTTP requests received, tagged by method, route, and status"
		labels: #commonLabels & {
			method: description: "HTTP method (GET, POST, PUT, DELETE, etc.)"
			route: description:  "HTTP route pattern (e.g., /api/v1/checkout)"
			status: description: "HTTP status code (200, 404, 500, etc.)"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_http_requests_total{route=\"/checkout\"}[5m])"
					description: "Request rate (req/s) for /checkout endpoint - throughput SLI"
				},
				{
					query:       "sum(rate(traffic_http_requests_total{status=~\"5..\"}[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Error rate (5xx) - error budget basis"
				},
				{
					query:       "sum(rate(traffic_http_requests_total[5m])) by (route, status)"
					description: "Request rate by route and status to identify traffic patterns"
				},
			]
			alerts: [
				{
					name:        "HighErrorRate"
					expr:        "sum(rate(traffic_http_requests_total{status=~\"5..\"}[5m])) / sum(rate(traffic_http_requests_total[5m])) > 0.05"
					description: "Error rate exceeds 5% - SLO breach"
					for:         "5m"
					severity:    "critical"
				},
				{
					name:        "UnexpectedTrafficSpike"
					expr:        "rate(traffic_http_requests_total[5m]) > 2 * rate(traffic_http_requests_total[30m] offset 1h)"
					description: "Traffic is 2x higher than usual - possible attack or viral event"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// HTTP Middleware Calls Total
	// Counts middleware executions (auth, rate-limiting, CORS, etc.)
	// Use: Quantify middleware overhead and detect rate-limiting impact
	http_middleware_calls_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "http"
		type:      "counter"
		help:      "Total middleware invocations, indicating volume processed by each middleware layer"
		labels: #commonLabels & {
			middleware: description: "Middleware name (e.g., auth, rate-limiter, cors)"
			phase: description:      "Middleware phase (before, after, error)"
			outcome: description:    "Outcome (success, rejected, error)"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_http_middleware_calls_total{middleware=\"rate-limiter\",outcome=\"rejected\"}[5m])"
					description: "Rate of requests rejected by rate-limiter"
				},
				{
					query:       "sum(rate(traffic_http_middleware_calls_total{outcome=\"rejected\"}[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Percentage of requests rejected by middleware"
				},
				{
					query:       "sum(rate(traffic_http_middleware_calls_total[5m])) by (middleware, outcome)"
					description: "Middleware call rate by name and outcome"
				},
			]
			alerts: [
				{
					name:        "HighRateLimitRejection"
					expr:        "rate(traffic_http_middleware_calls_total{middleware=\"rate-limiter\",outcome=\"rejected\"}[5m]) / rate(traffic_http_requests_total[5m]) > 0.1"
					description: "Rate limiter is rejecting >10% of requests - may need adjustment"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Database Queries Total
	// Counts all database operations (SELECT, INSERT, UPDATE, DELETE)
	// Use: Correlate with latency metrics to detect N+1 query problems
	database_queries_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "database"
		type:      "counter"
		help:      "Total database queries executed, by operation type and table"
		labels: #commonLabels & {
			query_type: description: "Query type (select, insert, update, delete, transaction)"
			table: description:      "Target table name"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_database_queries_total{table=\"cart_items\"}[5m])"
					description: "Query rate for cart_items table"
				},
				{
					query:       "sum(rate(traffic_database_queries_total[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Average number of DB queries per HTTP request - detects N+1 problems"
				},
				{
					query:       "sum(rate(traffic_database_queries_total[5m])) by (query_type, table)"
					description: "Query rate by type and table"
				},
			]
			alerts: [
				{
					name:        "ExcessiveDatabaseQueries"
					expr:        "sum(rate(traffic_database_queries_total[5m])) / sum(rate(traffic_http_requests_total[5m])) > 50"
					description: "More than 50 queries per request on average - likely N+1 problem"
					for:         "10m"
					severity:    "warning"
				},
				{
					name:        "DatabaseQuerySpike"
					expr:        "rate(traffic_database_queries_total[5m]) > 2 * rate(traffic_database_queries_total[30m] offset 1h)"
					description: "Database query rate is 2x higher than usual"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Cache Operations Total
	// Counts cache operations (get, set, delete) with hit/miss tracking
	// Use: Calculate cache hit ratio and justify cache sizing/TTL decisions
	cache_operations_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "cache"
		type:      "counter"
		help:      "Total cache operations, tracking hits and misses for ratio calculation"
		labels: #commonLabels & {
			cache_name: description: "Cache instance name (e.g., redis-primary, memcached-sessions)"
			operation: description:  "Cache operation (get, set, delete, mget, mset)"
			hit: description:        "Cache hit status (hit, miss, n/a)"
		}
		examples: {
			promql: [
				{
					query:       "sum(rate(traffic_cache_operations_total{operation=\"get\",hit=\"hit\"}[5m])) / sum(rate(traffic_cache_operations_total{operation=\"get\"}[5m]))"
					description: "Cache hit ratio - key metric for cache effectiveness"
				},
				{
					query:       "rate(traffic_cache_operations_total{operation=\"get\",hit=\"miss\"}[5m])"
					description: "Cache miss rate - indicates cold cache or insufficient TTL"
				},
				{
					query:       "sum(rate(traffic_cache_operations_total[5m])) by (cache_name, operation)"
					description: "Operation rate by cache instance and operation type"
				},
			]
			alerts: [
				{
					name:        "LowCacheHitRatio"
					expr:        "sum(rate(traffic_cache_operations_total{operation=\"get\",hit=\"hit\"}[5m])) / sum(rate(traffic_cache_operations_total{operation=\"get\"}[5m])) < 0.7"
					description: "Cache hit ratio below 70% - cache may be undersized or TTL too short"
					for:         "15m"
					severity:    "warning"
				},
				{
					name:        "CriticalCacheHitRatio"
					expr:        "sum(rate(traffic_cache_operations_total{operation=\"get\",hit=\"hit\"}[5m])) / sum(rate(traffic_cache_operations_total{operation=\"get\"}[5m])) < 0.5"
					description: "Cache hit ratio below 50% - cache is ineffective"
					for:         "10m"
					severity:    "critical"
				},
			]
		}
	}

	// HTTP Outbound Requests Total
	// Counts outbound HTTP calls to external services/APIs
	// Use: Detect retry loops, partner saturation, and dependency issues
	http_outbound_requests_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "http"
		type:      "counter"
		help:      "Total outbound HTTP requests to external services, by target and status"
		labels: #commonLabels & {
			target_system: description: "Target system/service name (e.g., bank-api, payment-gateway)"
			endpoint: description:      "Target endpoint (e.g., /api/v1/charge)"
			method: description:        "HTTP method (GET, POST, PUT, DELETE, etc.)"
			status: description:        "HTTP status code (200, 404, 500, etc.)"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_http_outbound_requests_total{target_system=\"bank-api\"}[5m])"
					description: "Request rate to bank-api"
				},
				{
					query:       "sum(rate(traffic_http_outbound_requests_total{status=~\"5..\"}[5m])) by (target_system)"
					description: "Error rate by target system - identify failing dependencies"
				},
				{
					query:       "sum(rate(traffic_http_outbound_requests_total[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Average number of outbound calls per inbound request"
				},
			]
			alerts: [
				{
					name:        "HighOutboundErrorRate"
					expr:        "sum(rate(traffic_http_outbound_requests_total{status=~\"5..\"}[5m])) by (target_system) / sum(rate(traffic_http_outbound_requests_total[5m])) by (target_system) > 0.1"
					description: "Outbound call error rate >10% for a target system"
					for:         "5m"
					severity:    "critical"
				},
				{
					name:        "OutboundRetryLoop"
					expr:        "rate(traffic_http_outbound_requests_total[5m]) > 5 * rate(traffic_http_requests_total[5m])"
					description: "Making 5x more outbound calls than inbound - possible retry loop"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}

	// Function Calls Total
	// Counts executions of performance-critical functions
	// Use: Validate A/B tests, refactorings, and optimization impact
	function_calls_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "function"
		type:      "counter"
		help:      "Total executions of instrumented functions, for critical code path analysis"
		labels: #commonLabels & {
			function: description: "Function name"
			class: description:    "Class/module name (if applicable)"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_function_calls_total{function=\"calculatePrice\"}[5m])"
					description: "Call rate for calculatePrice function"
				},
				{
					query:       "sum(rate(traffic_function_calls_total[5m])) by (function)"
					description: "Call rate by function - identify hot paths"
				},
				{
					query:       "sum(rate(traffic_function_calls_total[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Average function calls per request"
				},
			]
			alerts: [
				{
					name:        "UnexpectedFunctionCallSpike"
					expr:        "rate(traffic_function_calls_total[5m]) > 2 * rate(traffic_function_calls_total[30m] offset 1h)"
					description: "Function call rate is 2x higher than usual - possible code issue"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}

	// Queue Published Total
	// Counts messages published to queues/topics
	// Use: Detect event storms, validate producer is not spamming the queue
	queue_published_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "queue"
		type:      "counter"
		help:      "Total messages published to queues, by queue and event type"
		labels: #commonLabels & {
			queue: description:      "Queue/topic name"
			event_type: description: "Event type being published"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_queue_published_total{queue=\"orders\"}[5m])"
					description: "Message publish rate for orders queue"
				},
				{
					query:       "sum(rate(traffic_queue_published_total[5m])) by (queue, event_type)"
					description: "Publish rate by queue and event type"
				},
				{
					query:       "sum(rate(traffic_queue_published_total[5m])) / sum(rate(traffic_http_requests_total[5m]))"
					description: "Average messages published per HTTP request"
				},
			]
			alerts: [
				{
					name:        "QueueEventStorm"
					expr:        "rate(traffic_queue_published_total[5m]) > 5 * rate(traffic_queue_published_total[30m] offset 1h)"
					description: "Publishing rate is 5x higher than usual - possible event storm"
					for:         "5m"
					severity:    "critical"
				},
			]
		}
	}

	// Queue Processed Total
	// Counts messages processed by workers (ack/nack)
	// Use: Calculate queue lag (publish rate - process rate)
	queue_processed_total: schemas.#Metric & {
		namespace: "traffic"
		subsystem: "queue"
		type:      "counter"
		help:      "Total messages processed from queues, by queue, event type, and result"
		labels: #commonLabels & {
			queue: description:      "Queue/topic name"
			event_type: description: "Event type being processed"
			result: description:     "Processing result (success, retry, dead_letter)"
		}
		examples: {
			promql: [
				{
					query:       "rate(traffic_queue_processed_total{queue=\"payments\",result=\"success\"}[5m])"
					description: "Successful payment processing rate"
				},
				{
					query:       "rate(traffic_queue_published_total[5m]) - rate(traffic_queue_processed_total[5m])"
					description: "Queue lag rate - if positive and growing, queue is backing up"
				},
				{
					query:       "sum(rate(traffic_queue_processed_total{result!=\"success\"}[5m])) / sum(rate(traffic_queue_processed_total[5m]))"
					description: "Message processing failure rate"
				},
				{
					query:       "sum(rate(traffic_queue_processed_total[5m])) by (queue, result)"
					description: "Processing rate by queue and result"
				},
			]
			alerts: [
				{
					name:        "QueueLagGrowing"
					expr:        "rate(traffic_queue_published_total[5m]) > rate(traffic_queue_processed_total[5m]) * 1.2"
					description: "Queue lag is growing - publish rate >20% higher than process rate"
					for:         "15m"
					severity:    "warning"
				},
				{
					name:        "CriticalQueueLag"
					expr:        "rate(traffic_queue_published_total[5m]) > rate(traffic_queue_processed_total[5m]) * 2"
					description: "Critical queue lag - publish rate is 2x process rate - scale workers"
					for:         "10m"
					severity:    "critical"
				},
				{
					name:        "HighMessageFailureRate"
					expr:        "sum(rate(traffic_queue_processed_total{result!=\"success\"}[5m])) / sum(rate(traffic_queue_processed_total[5m])) > 0.1"
					description: "Message processing failure rate >10%"
					for:         "10m"
					severity:    "warning"
				},
			]
		}
	}
	}
}

// Export the standard metrics
DefaultTrafficMetrics: #DefaultTrafficMetrics
