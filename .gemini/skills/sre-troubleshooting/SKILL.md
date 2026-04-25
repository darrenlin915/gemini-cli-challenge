---
name: sre-troubleshooting
description: SRE Troubleshooting skill for diagnosing incidents. Includes workflows for checking GitHub PRs/Commits, querying GKE Kubernetes events, inspecting Cloud Logging, retrieving Monitoring metrics, and summarizing findings to Jira. Use when troubleshooting, checking deployments, investigating errors/latency/OOMs, or generating incident root cause reports for Jira.
---

# SRE Troubleshooting Playbook

## Overview
This skill guides the agent through a standardized SRE incident response workflow, bridging GitHub code changes, GKE infrastructure health, Kubernetes Events, Cloud Logging, Monitoring Metrics, and Jira reporting.

## Troubleshooting Workflow

**⚠️ CRITICAL RULE:** NEVER modify Kubernetes resources directly using `kubectl` (e.g., `kubectl edit`, `kubectl apply`, `kubectl scale`, `kubectl delete`). All infrastructure and applications are managed by a GitOps Controller (ArgoCD). Any direct changes to the cluster will be overwritten by the controller. All modifications MUST be done by updating the declarative manifests in the git repository.

**⚠️ CRITICAL RULE:** DO NOT edit source code.

When asked to troubleshoot an incident, follow these sequential phases:

### Phase 1: Triage & Correlation
Recent changes are the most common cause of incidents. Identify what changed immediately before the issue began.
- Run `git log --oneline -n 10`
- Run `gh pr list --state merged --limit 5`
- Determine if the affected service's image tag in GKE matches the recent commit hash.

### Phase 2: Kubernetes Events via Cloud Logging
Query Cloud Logging FIRST to check for infrastructure-level failures (e.g., OOMKilled, CrashLoopBackOff, Evictions, FailedScheduling). Cloud Logging retains historical events and does not require direct cluster access.
- **Discover Log Schemas:** Always call `mcp_gke_get_log_schema` first (e.g., for `k8s_event_logs`).
- **Query Kubernetes Events:** Use `mcp_gke_query_logs` with log type `k8s_event_logs`. Specify `project_id` and the `time_range`.
- See `references/k8s-events-guide.md` for deeper event analysis strategies.

### Phase 3: Application Logs via Cloud Logging
If the infrastructure events look healthy but the application is failing (e.g., HTTP 5xx errors), query application logs from Cloud Logging.
- **Discover Log Schemas:** Call `mcp_gke_get_log_schema` for `k8s_application_logs`.
- **Query Logs:** Use `mcp_gke_query_logs`. Specify `project_id` and the `time_range`.
- See `references/lql-queries.md` for pre-built Log Query Language (LQL) templates.

### Phase 4: Monitoring Metrics Analysis (Cloud Monitoring)
Check performance metrics via Cloud Monitoring to identify resource exhaustion, latency spikes, or error rate increases.
- Use `mcp_gke_list_monitored_resource_descriptors` to find the correct metric schema if needed.
- See `references/metrics-guide.md` for instructions on querying GCP Monitoring metrics for CPU, Memory, and Network.

### Phase 5: Fallback — Direct Cluster Inspection via `kubectl`
**ONLY use `kubectl` if Cloud Logging and Cloud Monitoring queries in Phases 2-4 did not return sufficient data to identify the root cause.**
Before running any `kubectl` command, you MUST:
1. Explain to the user why the cloud-based queries were insufficient.
2. List the specific `kubectl` commands you intend to run.
3. **Explicitly ask the user for confirmation** before proceeding.

Once confirmed, you may use:
- `mcp_gke_get_cluster` and `mcp_gke_get_kubeconfig` to connect to the cluster.
- `kubectl get pods -n <namespace>` to check pod states.
- `kubectl get events --sort-by='.metadata.creationTimestamp' -n <namespace>` for real-time events.
- `kubectl logs <pod-name> -n <namespace>` or `kubectl logs <pod-name> -n <namespace> --previous` for container logs.
- `mcp_gke_get_node_sos_report` for node diagnostics.

### Phase 6: Reporting & Jira Integration
After investigating the issue, you MUST summarize the root cause and offer to report it to Jira.
1. **Generate a Summary:** Create a clear, concise incident report (Impact, Root Cause Hypothesis, Recommended Mitigation).
2. **Ask the User:** Present this summary to the user and explicitly ask:
   - "Would you like to modify this summary?"
   - "Should I create a new Jira ticket with this summary?"
   - "Should I add this summary as a comment to an existing Jira ticket?"
3.  **Action:** If the user agrees to post to Jira, use `mcp_atlassian-rovo-mcp-server_createJiraIssue` (to create a new issue) or `mcp_atlassian-rovo-mcp-server_addCommentToJiraIssue` (to comment on an existing issue).
4.  **Provide Link:** After creating a new Jira ticket, provide the user with a direct link to the newly created issue.
