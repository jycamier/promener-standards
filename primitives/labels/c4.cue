package labels

// C4 Architecture Labels
// Standard label definitions for C4 model alignment
// These labels provide hierarchical observability from System → Container → Component

// #C4Labels defines the mandatory C4 architecture labels for metrics
// Use these labels to ensure consistent observability across your entire system
// The ... allows for additional metric-specific labels to be added
#C4Labels: {
	system: {
		description: "Level 1 - The high-level system boundary (e.g., ecommerce, payment-platform, user-management)"
		inherited:   "Injected from pod label 'system' via Prometheus relabeling rules"
	}
	container: {
		description: "Level 2 - The deployable unit using <applicationname>-<type> format (e.g., checkout-api, payment-worker)"
		inherited:   "Injected from pod label 'container' via Prometheus relabeling rules"
	}
	component: {
		description: "Level 3 - The logical component within the container (e.g., payment-handler, cart-manager, auth-middleware)"
		inherited:   "Injected from pod label 'component' via Prometheus relabeling rules"
	}
	...
}

// Export the standard C4 labels
C4Labels: #C4Labels
