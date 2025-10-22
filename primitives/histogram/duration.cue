package histogram

// Standard histogram buckets for long-running durations
// All values are in seconds
// Use these for processes that can take minutes to hours

// Background Job/Task Duration
// Use for: Async jobs, cron tasks, background workers
// Range: 100ms to 1 hour
// Reasoning: Jobs can take a long time, need visibility across large range
#BackgroundJobBuckets: [0.1, 0.5, 1, 5, 10, 30, 60, 300, 600, 1800, 3600]

// Batch Processing Duration
// Use for: ETL jobs, data processing pipelines, batch imports
// Range: 1s to 6 hours
// Reasoning: Batch jobs often run for extended periods
#BatchBuckets: [1, 5, 10, 30, 60, 300, 600, 1800, 3600, 7200, 14400, 21600]

// Long-Running Query Duration
// Use for: Report generation, data exports, complex analytics
// Range: 1s to 30 minutes
// Reasoning: Reports can take time but shouldn't exceed 30min
#LongQueryBuckets: [1, 5, 10, 30, 60, 120, 300, 600, 900, 1200, 1800]

// Session Duration
// Use for: User session length, connection duration
// Range: 1min to 24 hours
// Reasoning: Sessions can be very long (days for some apps)
#SessionBuckets: [60, 300, 600, 1800, 3600, 7200, 14400, 28800, 43200, 86400]
