package histogram

// Standard histogram buckets for size measurements
// All values are in bytes
// Use logarithmic scale for wide ranges

// Standard Payload Size
// Use for: HTTP request/response sizes, gRPC messages, queue messages
// Range: 100 bytes to 100MB (logarithmic scale)
// Reasoning: Most payloads are small, but need to detect large outliers
#StandardSizeBuckets: [100, 1000, 10000, 100000, 1000000, 10000000, 100000000]

// Small Payload Size
// Use for: Redis values, cache entries, small messages
// Range: 10 bytes to 1MB
// Reasoning: Cache entries should be small for performance
#SmallSizeBuckets: [10, 100, 1000, 10000, 100000, 1000000]

// Large Payload Size
// Use for: File uploads, video processing, large data transfers
// Range: 1KB to 10GB
// Reasoning: File uploads can be very large
#LargeSizeBuckets: [1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000]

// Memory Size
// Use for: Memory allocations, buffer sizes, heap metrics
// Range: 1KB to 10GB
// Reasoning: Memory can range from small allocations to multi-GB heaps
#MemorySizeBuckets: [1024, 10240, 102400, 1048576, 10485760, 104857600, 1073741824, 10737418240]

// Database Row Size
// Use for: Row/document sizes in databases
// Range: 100 bytes to 10MB
// Reasoning: Most rows are small, but some can contain large BLOB/TEXT fields
#DatabaseRowSizeBuckets: [100, 1000, 10000, 100000, 1000000, 10000000]
