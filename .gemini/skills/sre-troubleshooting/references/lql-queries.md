# Cloud Logging LQL Queries Guide

Use these LQL (Logging Query Language) snippets with the `mcp_gke_query_logs` tool to quickly find root causes.

## Core Application Logs
**Log Type:** `k8s_application_logs` (or similar depending on log schema).

### 1. Find 5xx Errors (HTTP Errors)
Useful when an API or frontend is failing.
```lql
resource.type="k8s_container"
resource.labels.cluster_name="YOUR_CLUSTER"
resource.labels.namespace_name="YOUR_NAMESPACE"
textPayload=~"HTTP/[0-9.]+ 5[0-9]{2}" OR jsonPayload.status>=500
```

### 2. Find Exceptions & Stack Traces
```lql
resource.type="k8s_container"
resource.labels.cluster_name="YOUR_CLUSTER"
resource.labels.namespace_name="YOUR_NAMESPACE"
(textPayload=~"Exception|Error|panic|fatal" OR severity>=ERROR)
```

### 3. Filter Out Health Checks
To reduce noise, exclude liveness/readiness probe requests.
```lql
resource.type="k8s_container"
resource.labels.cluster_name="YOUR_CLUSTER"
NOT textPayload=~"kube-probe|HealthCheck"
```

## Infrastructure Events
**Log Type:** `k8s_event_logs`

### 1. Find OOMKilled Events
```lql
resource.type="k8s_cluster"
resource.labels.cluster_name="YOUR_CLUSTER"
jsonPayload.reason="OOMKilled"
```

### 2. Find Node Not Ready or Evictions
```lql
resource.type="k8s_node"
resource.labels.cluster_name="YOUR_CLUSTER"
(jsonPayload.reason="NodeNotReady" OR jsonPayload.reason="Evicted")
```
