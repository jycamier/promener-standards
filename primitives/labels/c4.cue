package labels

// C4 Architecture Labels
// Standard label definitions for C4 model alignment
// These labels provide hierarchical observability from System → Container → Component

// #C4Labels defines the mandatory C4 architecture labels for metrics
// Use these labels to ensure consistent observability across your entire system
// The ... allows for additional metric-specific labels to be added
#C4Labels: {
	system: description:    "Level 1 - The high-level system boundary (e.g., ecommerce, payment-platform, user-management)"
	container: description: "Level 2 - The deployable unit using <applicationname>-<type> format (e.g., checkout-api, payment-worker)"
	component: description: "Level 3 - The logical component within the container (e.g., payment-handler, cart-manager, auth-middleware)"
	...
}

// Container types - Standard suffixes for container naming
// Format: <applicationname>-<type>
// Example: checkout-api, payment-worker, notification-daemon

// #ContainerTypes defines the standard container type suffixes
#ContainerTypes: {
	// API/Web Services
	api:     "HTTP/REST API service"
	graphql: "GraphQL API service"
	grpc:    "gRPC service"
	web:     "Web frontend application"

	// Background Processing
	worker:   "Background worker/consumer"
	cron:     "Scheduled job runner"
	daemon:   "Long-running daemon process"
	consumer: "Message queue consumer"

	// Data & Storage
	db:    "Database instance"
	cache: "Cache instance (Redis, Memcached)"
	queue: "Message queue/broker"

	// Infrastructure
	proxy:   "Reverse proxy/load balancer"
	gateway: "API gateway"
	router:  "Request router/dispatcher"

	// Batch & Analytics
	batch:     "Batch processing job"
	etl:       "ETL pipeline"
	analytics: "Analytics/reporting service"

	// CLI & Tools
	cli:  "Command-line interface tool"
	task: "One-off task/migration"
}

// Export the standard C4 labels
C4Labels: #C4Labels

// Export container types reference
ContainerTypes: #ContainerTypes
