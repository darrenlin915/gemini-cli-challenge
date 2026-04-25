# Kubernetes Events Troubleshooting Guide

Kubernetes events are critical for diagnosing infrastructure and scheduling issues that don't appear in application logs (e.g., OOMKills, FailedScheduling, CrashLoopBackOff, Liveness Probe failures).

## Fetching Events via Cloud Logging (Preferred)
Always try Cloud Logging first. It retains historical events, does not require direct cluster access, and supports powerful filtering via LQL. Use `mcp_gke_query_logs` with log type `k8s_event_logs`.

**LQL Query — Warning events for a cluster:**
```lql
severity >= WARNING
resource.type="k8s_cluster"
resource.labels.cluster_name="YOUR_CLUSTER_NAME"
```

**LQL Query — Events for a specific namespace:**
```lql
resource.type="k8s_cluster"
resource.labels.cluster_name="YOUR_CLUSTER_NAME"
jsonPayload.metadata.namespace="YOUR_NAMESPACE"
```

## Fetching Events via `kubectl` (Fallback)
Only use `kubectl` if Cloud Logging did not return sufficient data, and after getting user confirmation.

**Get all events in a namespace (sorted by time):**
```bash
kubectl get events --sort-by='.metadata.creationTimestamp' -n <namespace>
```

**Get only WARNING events across the entire cluster:**
```bash
kubectl get events -A --field-selector type=Warning --sort-by='.metadata.creationTimestamp'
```

**Get events for a specific resource (e.g., a Pod):**
```bash
kubectl describe pod <pod-name> -n <namespace>
```
*(Look at the `Events:` section at the bottom of the output)*

## Common Event Types & Meanings
*   **`FailedScheduling`**: The pod cannot be scheduled on any node (often due to insufficient CPU/Memory or Taint/Toleration mismatches).
*   **`OOMKilled`**: The container exceeded its memory limit and was killed by the kernel. Check application memory leaks or increase limits.
*   **`CrashLoopBackOff`**: The container is repeatedly crashing immediately after starting. Check application startup logs (`kubectl logs -p <pod>`).
*   **`Unhealthy` (Liveness/Readiness/Startup Probe Failed)**: The pod failed its health check. The service might be deadlocking or taking too long to start.
*   **`Evicted`**: The node is running out of resources (usually Disk or Memory) and is evicting pods to recover.
*   **`BackOff`**: Generic backoff event for restarting failed containers or pulling images.
*   **`ErrImagePull` / `ImagePullBackOff`**: The container runtime cannot pull the image (Check image tag typos, registry authentication, or network issues).
