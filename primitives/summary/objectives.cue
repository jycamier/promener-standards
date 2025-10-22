package summary

// Standard summary objectives (quantiles with error margins)
//
// IMPORTANT: Summaries should be used rarely!
// Prefer histograms in almost all cases - they can be aggregated and allow flexible queries.
// Use summaries only when:
// - You need exact quantiles calculated client-side
// - You're monitoring a single instance (summaries can't aggregate)
// - You have streaming data that can't be bucketed
//
// See docs/histogram-vs-summary.md for detailed guidance

// Standard Percentiles
// Use for: API monitoring, general observability
// Percentiles: p50 (median), p90, p99
// Error margins: p50±5%, p90±1%, p99±0.1%
#StandardObjectives: {
	"0.5":  0.05  // p50 ±5%
	"0.9":  0.01  // p90 ±1%
	"0.99": 0.001 // p99 ±0.1%
}

// Strict Percentiles
// Use for: High-performance systems, low-latency requirements
// Percentiles: p50, p90, p99, p99.9
// Error margins: Tighter than standard (0.1-1%)
#StrictObjectives: {
	"0.5":   0.01  // p50 ±1%
	"0.9":   0.001 // p90 ±0.1%
	"0.99":  0.001 // p99 ±0.1%
	"0.999": 0.001 // p99.9 ±0.1%
}

// Basic Percentiles
// Use for: General monitoring, non-critical metrics
// Percentiles: p50, p90, p95
// Error margins: Relaxed (5%)
#BasicObjectives: {
	"0.5":  0.05 // p50 ±5%
	"0.9":  0.05 // p90 ±5%
	"0.95": 0.05 // p95 ±5%
}

// High Percentiles
// Use for: When you need visibility into long tail (p99.9, p99.99)
// Percentiles: p90, p99, p99.9, p99.99
// Error margins: Very tight for tail latencies
#HighPercentileObjectives: {
	"0.9":    0.001  // p90 ±0.1%
	"0.99":   0.001  // p99 ±0.1%
	"0.999":  0.0001 // p99.9 ±0.01%
	"0.9999": 0.0001 // p99.99 ±0.01%
}
