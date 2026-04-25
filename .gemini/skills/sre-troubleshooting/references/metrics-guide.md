# GKE Monitoring Metrics Guide

Monitoring metrics are crucial for diagnosing latency, resource exhaustion, and high error rates.

## Discovering Metric Names
To query metrics, you need the exact metric descriptor. Use the `mcp_gke_list_monitored_resource_descriptors` tool to list available schemas.

## Important GKE Metrics
Here are the most common metrics used during an incident:

### Compute Resources (CPU & Memory)
*   `kubernetes.io/container/cpu/limit_utilization`: Is the container hitting its CPU limit (leading to throttling)?
*   `kubernetes.io/container/memory/limit_utilization`: Is the container hitting its Memory limit (leading to OOMKilled)?
*   `kubernetes.io/node/cpu/allocatable_utilization`: Is the entire node out of CPU?
*   `kubernetes.io/node/memory/allocatable_utilization`: Is the entire node out of Memory?

### Network
*   `kubernetes.io/pod/network/received_bytes_count`: Unexpected drops or spikes in incoming traffic.
*   `kubernetes.io/pod/network/sent_bytes_count`: Unexpected drops or spikes in outgoing traffic.

## Querying Metrics (Via gcloud)
If you need to view raw metric data directly from the CLI, use `gcloud monitoring metrics.time-series list`. 

**Example: Check CPU utilization for a specific pod (last hour)**
*(Replace PROJECT_ID and POD_NAME)*
```bash
gcloud monitoring metrics.time-series list \
  --project=PROJECT_ID \
  --filter='metric.type="kubernetes.io/container/cpu/limit_utilization" AND resource.labels.pod_name="POD_NAME"' \
  --view=FULL \
  --interval.start-time="-1h"
```

## Horizontal Pod Autoscaler (HPA)
When troubleshooting load issues, check if the HPA is scaling properly.
HPA status can sometimes be inferred from Cloud Monitoring metrics (scaling events, replica counts). If Cloud Monitoring does not provide enough detail, fall back to `kubectl` after getting user confirmation:
```bash
kubectl get hpa -n <namespace>
kubectl describe hpa <hpa-name> -n <namespace>
```
Look for `Conditions` in the describe output to see if the HPA is able to fetch metrics and scale up.
