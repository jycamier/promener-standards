# C4 Architecture Labels

## Table of Contents

- [Introduction](#introduction)
- [The C4 Model](#the-c4-model)
- [Label Definitions](#label-definitions)
- [Container Naming Standard](#container-naming-standard)
- [Container Types Reference](#container-types-reference)
- [Label Selection Guide](#label-selection-guide)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [Real-World Examples](#real-world-examples)
- [Querying and Correlation](#querying-and-correlation)
- [Migration Strategy](#migration-strategy)

## Introduction

The C4 Architecture Labels provide a standardized, hierarchical labeling system for Prometheus metrics based on the [C4 model](https://c4model.com/) for visualizing software architecture. These three labels (`system`, `container`, `component`) enable:

- **Hierarchical observability** from high-level system view down to individual components
- **Consistent metrics** across all services and teams
- **Natural aggregation** at different architectural levels
- **Clear ownership boundaries** for monitoring and alerting
- **Architecture alignment** between diagrams and metrics

## The C4 Model

The C4 model provides a hierarchical way to visualize software architecture at four levels:

1. **System Context** - How your system fits into the world (users, external systems)
2. **Container** - High-level technology choices (applications, data stores, services)
3. **Component** - Major structural building blocks within a container
4. **Code** - Classes, functions (too granular for metrics labels)

Our label system aligns with levels 1-3, providing the right balance between granularity and cardinality.

```
┌─────────────────────────────────────────────────────┐
│ System: ecommerce                                    │  ← system label
│                                                      │
│  ┌──────────────────┐      ┌─────────────────────┐ │
│  │ Container:       │      │ Container:          │ │  ← container label
│  │ checkout-api     │──────│ payment-worker      │ │
│  │                  │      │                     │ │
│  │  ┌────────────┐  │      │  ┌──────────────┐  │ │
│  │  │ Component: │  │      │  │ Component:   │  │ │  ← component label
│  │  │ cart-mgr   │  │      │  │ stripe-svc   │  │ │
│  │  └────────────┘  │      │  └──────────────┘  │ │
│  └──────────────────┘      └─────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Label Definitions

### `system`

**Level**: C4 System Context

**Definition**: The top-level system or product boundary. This represents a complete, cohesive business capability or product.

**Purpose**:
- Group all containers and components that work together to deliver a business capability
- Enable cross-service observability for product-level SLOs
- Define ownership boundaries at the product/platform level

**Characteristics**:
- Stable over time (rarely changes)
- Maps to business domains or products
- Low cardinality (typically 5-50 systems in an organization)
- Should align with organizational structure (teams/squads)

**Examples**:
- `ecommerce` - The entire e-commerce platform
- `payment-platform` - Payment processing system
- `user-management` - User authentication and authorization
- `inventory-system` - Inventory tracking and management
- `analytics-platform` - Data analytics and reporting

**Anti-Examples** (too granular):
- ❌ `ecommerce-checkout` - This is likely a container, not a system
- ❌ `payment-stripe` - This is a component, not a system
- ❌ `api` - This describes a type, not a business system

### `container`

**Level**: C4 Container

**Definition**: A separately deployable/runnable unit (application, service, database, etc.) that executes code or stores data.

**Naming Standard**: `<applicationname>-<type>`

**Purpose**:
- Identify what is being deployed and where it runs
- Map metrics to deployment units (pods, containers, VMs)
- Enable per-service SLOs and capacity planning
- Track resource usage per deployable unit

**Characteristics**:
- Medium cardinality (10-200 per system)
- Maps 1:1 with deployment artifacts (Docker images, binaries)
- Represents technology choices (API vs worker vs daemon)
- Includes the runtime type for operational clarity

**Format Rules**:
1. Use kebab-case: `checkout-api`, not `CheckoutAPI` or `checkout_api`
2. Application name first: `payment-worker`, not `worker-payment`
3. Type suffix from standard list (see [Container Types](#container-types-reference))
4. Be specific but concise: `order-processor-worker`, not `worker-that-processes-orders`

**Examples**:
- `checkout-api` - HTTP API for checkout operations
- `payment-worker` - Background worker processing payments
- `notification-daemon` - Long-running notification service
- `inventory-cron` - Scheduled job for inventory sync
- `user-cache` - Redis cache for user sessions

**Anti-Examples**:
- ❌ `api` - Missing application name
- ❌ `checkout` - Missing type suffix
- ❌ `checkout_api` - Wrong case (use kebab-case)
- ❌ `CheckoutAPIService` - Wrong case, redundant suffix

### `component`

**Level**: C4 Component

**Definition**: A logical grouping of related functionality within a container. Components are the major structural building blocks of your code.

**Purpose**:
- Pinpoint exactly where an issue is occurring within a service
- Track performance of specific business logic areas
- Enable fine-grained debugging and optimization
- Measure component-level SLIs

**Characteristics**:
- Higher cardinality (5-30 per container, 50-500 per system)
- Maps to architectural modules/packages
- Represents logical cohesion (e.g., all payment logic, all auth logic)
- Somewhat flexible (can change as code evolves)

**Naming Guidelines**:
- Use kebab-case: `payment-handler`, not `PaymentHandler`
- Describe the responsibility: `cart-manager`, `order-validator`
- Be domain-focused: `stripe-integration` not `http-client-3`
- Keep consistent across containers when components have similar roles

**Examples**:
- `payment-handler` - Processes payment transactions
- `cart-manager` - Manages shopping cart operations
- `auth-middleware` - Authentication middleware
- `order-validator` - Validates order data
- `database-pool` - Database connection pool
- `stripe-client` - Stripe API integration
- `notification-sender` - Sends notifications

**Anti-Examples**:
- ❌ `handler` - Too generic
- ❌ `utils` - Not a meaningful component
- ❌ `class-123` - Implementation detail, not logical component
- ❌ `payment_handler` - Wrong case

## Container Naming Standard

### Format

```
<applicationname>-<type>
```

- **applicationname**: Describes what the container does (business/technical domain)
- **type**: Standard suffix indicating how it runs (from the [Container Types](#container-types-reference) list)

### Why This Format?

1. **Consistency**: Every team uses the same naming convention
2. **Clarity**: Immediately understand both purpose and deployment type
3. **Filtering**: Easy to filter by type (e.g., all `-worker` containers)
4. **Sorting**: Natural alphabetical grouping by application
5. **Documentation**: Self-documenting container purpose

### Examples by Pattern

| Application | Type | Container Name | Description |
|-------------|------|----------------|-------------|
| `checkout` | `api` | `checkout-api` | REST API for checkout |
| `checkout` | `worker` | `checkout-worker` | Background job processor |
| `payment` | `api` | `payment-api` | Payment HTTP service |
| `payment` | `worker` | `payment-worker` | Payment processing worker |
| `notification` | `daemon` | `notification-daemon` | Long-running notification service |
| `inventory` | `cron` | `inventory-cron` | Scheduled inventory sync |
| `user` | `cache` | `user-cache` | Redis cache for user data |
| `order` | `db` | `order-db` | Order database |
| `analytics` | `etl` | `analytics-etl` | ETL pipeline |
| `admin` | `web` | `admin-web` | Admin web frontend |

## Container Types Reference

### API & Web Services

| Type | Usage | Example |
|------|-------|---------|
| `api` | HTTP/REST API service | `checkout-api`, `user-api` |
| `graphql` | GraphQL API endpoint | `catalog-graphql` |
| `grpc` | gRPC service | `payment-grpc` |
| `web` | Web frontend/UI | `admin-web`, `shop-web` |

**When to use**:
- Service accepts incoming requests (HTTP, gRPC)
- Service exposes an API to other services or clients
- User-facing web applications

### Background Processing

| Type | Usage | Example |
|------|-------|---------|
| `worker` | Background worker/consumer | `payment-worker`, `email-worker` |
| `cron` | Scheduled job runner | `inventory-cron`, `cleanup-cron` |
| `daemon` | Long-running daemon process | `notification-daemon`, `watcher-daemon` |
| `consumer` | Message queue consumer | `order-consumer`, `event-consumer` |

**When to use**:
- `worker`: Processes jobs from a queue (Kafka, RabbitMQ, SQS)
- `cron`: Runs on a schedule (daily, hourly, etc.)
- `daemon`: Always running, not request/response (e.g., health checks, monitoring)
- `consumer`: Specifically consuming messages (use when distinction from generic worker matters)

### Data & Storage

| Type | Usage | Example |
|------|-------|---------|
| `db` | Database instance | `order-db`, `user-db` |
| `cache` | Cache instance | `session-cache`, `product-cache` |
| `queue` | Message queue/broker | `event-queue`, `task-queue` |

**When to use**:
- Tracking metrics for databases (connection pools, query latency)
- Monitoring cache performance (hit rate, latency)
- Queue broker metrics (lag, throughput)

### Infrastructure

| Type | Usage | Example |
|------|-------|---------|
| `proxy` | Reverse proxy/LB | `ingress-proxy`, `cache-proxy` |
| `gateway` | API gateway | `public-gateway`, `internal-gateway` |
| `router` | Request router | `event-router`, `service-router` |

**When to use**:
- Infrastructure components that route/forward traffic
- Entry points to systems
- Traffic management components

### Batch & Analytics

| Type | Usage | Example |
|------|-------|---------|
| `batch` | Batch processing job | `report-batch`, `export-batch` |
| `etl` | ETL pipeline | `sales-etl`, `analytics-etl` |
| `analytics` | Analytics/reporting | `metrics-analytics` |

**When to use**:
- Large-scale data processing
- Periodic reporting jobs
- Data transformation pipelines

### CLI & Tools

| Type | Usage | Example |
|------|-------|---------|
| `cli` | Command-line tool | `admin-cli`, `deploy-cli` |
| `task` | One-off task/migration | `migration-task`, `seed-task` |

**When to use**:
- Manual operations tools
- Database migrations
- One-time data fixes

## Label Selection Guide

### How to Choose the Right `system`

Ask yourself: **"What is the top-level product or business capability?"**

**Decision Tree**:

```
Is this a separate product line?
├─ Yes → New system (e.g., ecommerce, payment-platform)
└─ No → Part of existing system

Does it have its own team/budget/roadmap?
├─ Yes → New system
└─ No → Part of existing system

Could it be sold/deployed independently?
├─ Yes → New system
└─ No → Part of existing system
```

**Examples**:
- ✅ `ecommerce` - Complete e-commerce product
- ✅ `payment-platform` - Standalone payment processing (could be used by multiple products)
- ❌ `checkout` - This is just one part of ecommerce (use as container instead)

### How to Choose the Right `container`

Ask yourself: **"Is this a separate deployment unit?"**

**Decision Tree**:

```
Is it deployed independently?
├─ Yes → It's a container
└─ No → It's likely a component

Does it have its own process/runtime?
├─ Yes → It's a container
└─ No → It's a component

Does it have its own Docker image/binary?
├─ Yes → It's a container
└─ No → It's a component
```

**Then choose the type**:
- Does it handle HTTP requests? → `-api`
- Does it process background jobs? → `-worker`
- Does it run on a schedule? → `-cron`
- Is it always running but not serving requests? → `-daemon`

**Examples**:
- ✅ `checkout-api` - Separate API service with its own deployment
- ✅ `payment-worker` - Background worker, separate process
- ❌ `checkout-api-v2` - Don't version containers in labels (use versioning elsewhere)

### How to Choose the Right `component`

Ask yourself: **"What is the specific part of the code responsible for this operation?"**

**Decision Tree**:

```
Is it a meaningful architectural module?
├─ Yes → It's a component
└─ No → Too granular or too generic

Does it have clear responsibilities?
├─ Yes → It's a component
└─ No → Refine the boundary

Would you draw it on an architecture diagram?
├─ Yes → It's a component
└─ No → Too detailed
```

**Guidelines**:
- Map to packages/modules in your code
- One component per logical responsibility
- Prefer domain language: `cart-manager` over `http-handler`
- Keep consistent across similar operations

**Examples**:
- ✅ `payment-handler` - Handles payment logic
- ✅ `auth-middleware` - Authentication middleware
- ✅ `stripe-client` - Integration with Stripe
- ❌ `handler` - Too generic
- ❌ `function-123` - Implementation detail

## Best Practices

### 1. Align Labels with Architecture Diagrams

Your C4 diagrams should match your labels exactly. If you draw a system called "Payment Platform" on your diagram, use `payment-platform` as the system label.

**Why**: This creates a single source of truth between documentation and observability.

### 2. Use Consistent Naming Across Teams

Create a label registry that all teams reference:

```yaml
# labels-registry.yaml
systems:
  - ecommerce
  - payment-platform
  - user-management
  - inventory-system

container_types:
  - api
  - worker
  - daemon
  - cron
  - web
```

**Why**: Prevents fragmentation like `payment-platform` vs `payments` vs `payment-system`.

### 3. Start Broad, Add Granularity Later

Begin with system and container labels. Add component labels only when you need to debug specific subsystems.

**Why**: Premature granularity increases cardinality without adding value.

### 4. Document Label Choices

For each system, maintain a simple mapping:

```markdown
# E-commerce System Labels

- **System**: `ecommerce`
- **Containers**:
  - `checkout-api` - Checkout REST API
  - `checkout-worker` - Background checkout processing
  - `payment-api` - Payment gateway integration
  - `cart-cache` - Redis cache for shopping carts
```

**Why**: New team members can onboard faster and use labels correctly.

### 5. Use Labels for SLO Alignment

Define SLOs at the right level:
- **System-level SLO**: "99.9% of ecommerce requests succeed"
- **Container-level SLO**: "95% of checkout-api requests < 300ms"
- **Component-level SLI**: "Payment-handler P99 latency < 500ms"

### 6. Inject Labels Automatically

Use service mesh, Kubernetes annotations, or environment variables to inject labels automatically:

```yaml
# Kubernetes Deployment
metadata:
  labels:
    promener.io/system: ecommerce
    promener.io/container: checkout-api
```

**Why**: Reduces manual errors and ensures consistency.

### 7. Review Label Cardinality

Monitor the number of unique label combinations:

```promql
# Check unique system/container/component combinations
count(count by (system, container, component) (up))
```

**Target**: < 1000 unique combinations per system

**Why**: High cardinality impacts Prometheus performance and storage.

### 8. Version Containers in Code, Not Labels

Don't do this:
- ❌ `checkout-api-v1`, `checkout-api-v2`

Instead:
- ✅ Use `container: "checkout-api"` with separate `version: "v2"` label if needed

**Why**: Keeps label cardinality low and makes queries simpler.

## Anti-Patterns

### ❌ Overly Generic Labels

**Bad**:
```
system: "backend"
container: "api"
component: "handler"
```

**Why it's bad**: Doesn't provide meaningful filtering or context.

**Good**:
```
system: "ecommerce"
container: "checkout-api"
component: "payment-handler"
```

### ❌ Including Environment in Labels

**Bad**:
```
system: "ecommerce-prod"
container: "checkout-api-staging"
```

**Why it's bad**: Environment should be a separate label (`environment: "prod"`).

**Good**:
```
system: "ecommerce"
container: "checkout-api"
environment: "prod"  # Separate label
```

### ❌ Using Technical Implementation Details

**Bad**:
```
component: "database-connection-pool-v3"
component: "http-client-retry-handler"
```

**Why it's bad**: Too focused on implementation, not business logic.

**Good**:
```
component: "database-pool"
component: "order-client"
```

### ❌ Inconsistent Naming Across Teams

**Bad**:
- Team A: `system: "payments"`
- Team B: `system: "payment-platform"`
- Team C: `system: "payment-service"`

**Why it's bad**: Impossible to aggregate metrics across the entire payment system.

**Good**:
- All teams: `system: "payment-platform"`

### ❌ Too Many Components

**Bad**: 150 different components in a single container

**Why it's bad**:
- High cardinality
- Hard to aggregate
- Probably too granular

**Good**: 10-20 components per container (at most)

### ❌ Container Without Type Suffix

**Bad**:
```
container: "checkout"
container: "payment"
```

**Why it's bad**: Can't tell if it's an API, worker, or something else.

**Good**:
```
container: "checkout-api"
container: "payment-worker"
```

## Real-World Examples

### Example 1: E-commerce Platform

**System Architecture**:
```
System: ecommerce
├── checkout-api (REST API)
│   ├── cart-manager
│   ├── payment-handler
│   └── order-validator
├── checkout-worker (Background processor)
│   ├── payment-processor
│   └── notification-sender
├── inventory-api (REST API)
│   ├── stock-manager
│   └── warehouse-client
└── cart-cache (Redis)
```

**Sample Metrics**:
```promql
# System-level: Total e-commerce request rate
sum(rate(http_requests_total{system="ecommerce"}[5m]))

# Container-level: Checkout API latency
histogram_quantile(0.95,
  rate(latency_http_request_seconds_bucket{
    system="ecommerce",
    container="checkout-api"
  }[5m])
)

# Component-level: Payment handler error rate
rate(errors_total{
  system="ecommerce",
  container="checkout-api",
  component="payment-handler"
}[5m])
```

### Example 2: Payment Platform (Multi-System)

**System Architecture**:
```
System: payment-platform
├── payment-api (REST API)
│   ├── stripe-client
│   ├── paypal-client
│   └── transaction-validator
├── payment-worker (Background processor)
│   ├── settlement-processor
│   ├── refund-handler
│   └── webhook-sender
├── payment-cron (Scheduled jobs)
│   ├── reconciliation-job
│   └── reporting-job
└── payment-cache (Redis)
```

**Used by multiple systems**:
```promql
# Payments for e-commerce system
sum(rate(payment_requests_total{
  system="ecommerce",
  target_system="payment-platform"
}[5m]))

# Payments for subscription system
sum(rate(payment_requests_total{
  system="subscription-platform",
  target_system="payment-platform"
}[5m]))
```

### Example 3: Microservices with Shared Components

**Scenario**: Multiple services use a shared authentication component

**System Architecture**:
```
System: user-management
├── auth-api
│   ├── login-handler
│   ├── token-validator
│   └── session-manager
├── user-api
│   ├── profile-manager
│   └── auth-middleware  ← Uses auth-api
└── admin-api
    ├── user-admin
    └── auth-middleware  ← Uses auth-api
```

**Tracking authentication across services**:
```promql
# Total auth failures across all services
sum(rate(auth_failures_total{
  system="user-management",
  component=~".*auth.*"
}[5m]))

# Auth latency by container
histogram_quantile(0.99,
  rate(latency_http_middleware_seconds_bucket{
    system="user-management",
    middleware="auth"
  }[5m])
) by (container)
```

## Querying and Correlation

### Hierarchical Aggregation

**System Level** (All services):
```promql
sum(rate(http_requests_total{system="ecommerce"}[5m]))
```

**Container Level** (Single service):
```promql
sum(rate(http_requests_total{
  system="ecommerce",
  container="checkout-api"
}[5m]))
```

**Component Level** (Specific functionality):
```promql
sum(rate(http_requests_total{
  system="ecommerce",
  container="checkout-api",
  component="payment-handler"
}[5m]))
```

### Cross-System Correlation

Track how one system depends on another:

```promql
# Checkout API calling Payment Platform
sum(rate(latency_http_call_seconds_count{
  system="ecommerce",
  container="checkout-api",
  target_system="payment-platform"
}[5m]))
```

### Multi-Level Filtering

Find slow components across all containers:

```promql
histogram_quantile(0.99,
  sum(rate(latency_function_execution_seconds_bucket{
    system="ecommerce"
  }[5m])) by (container, component, le)
) > 0.1
```

### Ownership and Alerting

Route alerts based on labels:

```yaml
# Alert routing
- match:
    system: ecommerce
    container: checkout-api
  receiver: checkout-team

- match:
    system: payment-platform
  receiver: payment-team
```

## Migration Strategy

### Phase 1: Add Labels to New Services

Start with new services using full C4 labels:

```yaml
# Kubernetes deployment
metadata:
  labels:
    promener.io/system: ecommerce
    promener.io/container: checkout-api
```

### Phase 2: Retrofit Existing Services

Add labels to existing services without breaking current dashboards:

```go
// Old metric (keep for now)
requests.Inc()

// New metric with C4 labels
requestsC4.WithLabelValues(
    "ecommerce",      // system
    "checkout-api",   // container
    "payment-handler", // component
).Inc()
```

### Phase 3: Update Dashboards Gradually

Create new dashboards using C4 labels while keeping old ones:

```promql
# Old query
rate(http_requests_total{service="checkout"}[5m])

# New query
rate(http_requests_total{
  system="ecommerce",
  container="checkout-api"
}[5m])
```

### Phase 4: Deprecate Old Labels

Once all dashboards/alerts use C4 labels, remove old metrics.

## Integration with Promener Standards

### Using C4 Labels with Latency Metrics

```cue
import "github.com/jycamier/promener-standards/primitives/labels"

myMetrics: {
    latency_http_request_seconds: {
        namespace: "latency"
        subsystem: "http"
        type: "histogram"
        labels: labels.#C4Labels & {
            // Add metric-specific labels
            method: description: "HTTP method"
            route: description: "HTTP route"
            status: description: "HTTP status code"
        }
    }
}
```

### CUE Integration

```cue
package myservice

import "github.com/jycamier/promener-standards/primitives/labels"

// Use C4 labels in your metrics
#MyMetric: {
    labels: labels.#C4Labels
    // Your metric definition
}
```

## References

- [C4 Model](https://c4model.com/) - Official C4 architecture documentation
- [Prometheus Label Best Practices](https://prometheus.io/docs/practices/naming/)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
- [Promener C4 Latency Metrics](c4-latency-metrics.md)

## See Also

- [C4 Latency Metrics](c4-latency-metrics.md) - Metrics using C4 labels
- [Histogram Buckets](../primitives/histogram/) - Standard histogram buckets
- [Summary Objectives](../primitives/summary/) - Standard summary objectives
