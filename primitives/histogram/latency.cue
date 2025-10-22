package histogram

// Standard histogram buckets for latency measurements
// All values are in seconds

// HTTP/API Latency (Standard)
// Use for: HTTP requests, REST API calls, GraphQL queries
// Range: 5ms to 10s (covers most web traffic)
// Reasoning: Most requests < 100ms, but need visibility up to 10s for slow requests
#HTTPBuckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]

// HTTP/API Latency (Strict SLA)
// Use for: High-performance APIs with strict SLA requirements
// Range: 1ms to 1s
// Reasoning: For services where >1s is unacceptable
#HTTPStrictBuckets: [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1]

// Database Query Latency (General)
// Use for: SQL queries, database operations
// Range: 100µs to 5s
// Reasoning: Simple queries should be <10ms, complex queries up to seconds
#DatabaseBuckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]

// Database Query Latency (OLTP)
// Use for: Transactional databases, high-frequency queries
// Range: 100µs to 500ms
// Reasoning: OLTP queries should be fast, >500ms indicates a problem
#DatabaseOLTPBuckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5]

// Database Query Latency (OLAP)
// Use for: Analytical queries, data warehouse, reporting
// Range: 10ms to 5min
// Reasoning: Analytical queries can be slow, need visibility up to minutes
#DatabaseOLAPBuckets: [0.01, 0.05, 0.1, 0.5, 1, 5, 10, 30, 60, 120, 300]

// Cache Operation Latency
// Use for: Redis, Memcached, in-memory cache operations
// Range: 100µs to 100ms
// Reasoning: Cache should be fast, >100ms indicates network/server issues
#CacheBuckets: [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1]

// gRPC/RPC Latency
// Use for: gRPC calls, internal service-to-service communication
// Range: 1ms to 30s
// Reasoning: RPC should be faster than HTTP, but some calls can be slow
#GRPCBuckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30]

// Message Queue Processing Latency
// Use for: Kafka, RabbitMQ message processing time
// Range: 10ms to 5min
// Reasoning: Message processing varies widely by workload
#MessageQueueBuckets: [0.01, 0.05, 0.1, 0.5, 1, 2.5, 5, 10, 30, 60, 120, 300]

// Rate Limiter Delay
// Use for: Rate limiting, throttling delays
// Range: 1ms to 60s
// Reasoning: Rate limiters typically delay from milliseconds to a minute
#RateLimitBuckets: [0.001, 0.01, 0.1, 0.5, 1, 5, 10, 30, 60]

// GC Pause Duration (Go)
// Use for: Garbage collection pause times
// Range: 10µs to 100ms
// Reasoning: GC pauses should be sub-millisecond, but can spike
#GCPauseBuckets: [0.00001, 0.0001, 0.0005, 0.001, 0.005, 0.01, 0.025, 0.05, 0.1]
