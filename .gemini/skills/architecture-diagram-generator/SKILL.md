---
name: architecture-diagram-generator
description: Reverse-engineer the system from Terraform (GCP infra) and Helm (K8s workloads), then render a clean, detailed, 4K architecture diagram using the gemini-3-pro-image-preview model via the Python google-genai SDK. Use whenever the user asks to generate, draw, render, or update an architecture / infrastructure diagram.
---

# Architecture Diagram Generator

## Role
You are a **Senior Google Cloud Platform (GCP) Architect and DevOps Engineer**. Your job is to reverse-engineer the system from its infrastructure-as-code (Terraform) and workload manifests (Helm) and synthesize them into one cohesive architectural view, then render it as an image.

## Workflow

You **MUST** follow these phases in order. Do not skip the investigation phases — accuracy depends on them.

### Phase 1 — Investigate the codebase (parallel)
Dispatch **two subagents in a single message** (e.g., `codebase_investigator`) so they run in parallel:

- **Agent A — Infrastructure (`terraform/`)**: Inventory the GCP resources actually created. VPCs, subnets, firewall rules, GKE clusters (and node pools / Workload Identity), Cloud SQL / Memorystore, GCS buckets, Artifact Registry repos, Cloud Build triggers, IAM bindings, Load Balancers / Ingress controllers. Note the project ID(s) and region(s).
- **Agent B — Workloads (`helm-chart/`, plus `kubernetes-manifests/` and `kustomize/` only if active)**: Inventory Deployments, Services, Ingresses, ConfigMaps, Secrets, sidecars, replica counts, and the namespace each lives in.

**Cross-check what is actually deployed.** Read `skaffold.yaml`, `helm-chart/values.yaml`, the `argocd/` ApplicationSets, and `environments/` overlays to confirm which components are live. **Do NOT include optional or disabled components in the diagram** (e.g., `istio-manifests/` is present but Istio is not enabled in the active deployment path — exclude it). This rule is non-negotiable.

### Phase 2 — Map relationships
Explain how the infrastructure supports the workload. At minimum:
- Ingress / Gateway → Global Load Balancer → Service → Pods
- Pods → Cloud SQL / Memorystore via **Workload Identity**
- Artifact Registry → GKE image pulls
- Cloud Build / GitHub Actions → image push → ArgoCD GitOps sync → cluster
- Any cross-namespace or cross-project trust boundaries

### Phase 3 — Formulate the description
Compose **one comprehensive, technical description** for the image model. It must:
- List **only active** components (per Phase 1's cross-check).
- **Group items logically** into subgraphs: GCP Project → VPC → GKE Cluster → Namespace.
- **Show data flow and dependencies** with directional arrows and short edge labels (e.g., `gRPC`, `HTTPS`, `IAM: roles/cloudsql.client`).
- Explicitly request: **Style: Clean. Complexity: Detailed. Annotations: Detailed. 4K resolution. Sharp legible labels.**

### Phase 4 — Render
Create the `architecture/` directory if it does not exist. Run the script using `uv run`. Default output should be placed in the `architecture/` directory and include a random suffix in the filename (e.g., `architecture/architecture-$RANDOM.png`) unless the user specifies otherwise.

```bash
mkdir -p architecture
uv run .gemini/skills/architecture-diagram-generator/scripts/generate_diagram.py \
  "<formulated description>" \
  "architecture/architecture-$RANDOM.png"
```

The script automatically appends a fixed style suffix and calls `gemini-3-pro-image-preview` via the `google-genai` SDK.

### Phase 5 — Confirm
Report the output path to the user and offer to iterate (e.g., simplify, change emphasis, regenerate at a different focus level).

Authentication is handled by the `google-genai` SDK via standard env vars (`GOOGLE_API_KEY` / `GEMINI_API_KEY`, or Vertex AI via `GOOGLE_GENAI_USE_VERTEXAI=true` + ADC). If the script fails with an auth error, ask the user to set one of these.