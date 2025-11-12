package main

import (
	"github.com/jycamier/promener-standards/schemas"
	"github.com/jycamier/promener-standards/primitives/labels"
	"github.com/jycamier/promener-standards/metrics/latency"
	"github.com/jycamier/promener-standards/metrics/traffic"
)

schemas.#Promener & {
	version: "1.0.0"
	info: {
		title:   "Ecommerce 9000"
		version: "1.0.0"
	}
	services: {
		default: {
			info: {
				title:   "Default Service"
				version: "1.0.0"
			}
			latency.#DefaultLatencyMetrics & {
				#commonLabels: labels.#C4Labels
			}
			traffic.#DefaultTrafficMetrics & {
				#commonLabels: labels.#C4Labels
			}
			metrics: {
				// Using validator to ensure metric name follows Prometheus conventions
				test: {
					namespace: "foo"
					subsystem: "bar"
					help:      "Foobar help"
					type:      "counter"
				}
			}
		}
	}
}
