# NemoClaw Accelerator Pack

> **Experimental** — This pack is still in experiment mode and not meant for production use cases.

The **NemoClaw Starter Pack** is an AI Accelerator Pack that deploys a secure, sandboxed execution environment for OpenClaw autonomous agents on Oracle Cloud Infrastructure (OCI). It uses NemoClaw with OpenShell runtime protection to isolate agent actions inside a Landlock + seccomp + network-namespaced sandbox.

## What You Get

- **Hardware:** A BM.GPU4.8 bare metal instance (8x A100 80GB) for self-hosted inference, or CPU-only infrastructure when using a cloud API provider. Runs on Oracle Kubernetes Engine (OKE).
- **Software:** NemoClaw + OpenShell sandbox with:
  - **OpenClaw dashboard**: Browser-based chat UI for interacting with autonomous agents
  - **Web terminal**: Optional ttyd-based terminal for direct sandbox access (`nemoclaw connect`, `openclaw tui`)
  - **Provider selection**: Self-hosted NVIDIA NIM, OpenAI API, or Anthropic API for inference
  - **Security tiers**: Restricted, balanced, or open policy tiers controlling sandbox permissions

## Use Cases

- **OCI cloud operations**: Agents interact with OCI APIs to inspect infrastructure, troubleshoot deployments, query databases, manage object storage, and automate operational tasks — with policy-controlled access levels.
- **Autonomous software engineering**: Agents write, execute, debug, and iterate on code with full tool access (shell, git, package managers) while sandboxed from production infrastructure.
- **Data analysis and research**: Agents gather data from the web, run computations, and produce structured reports — useful for market research, competitive analysis, or literature review.

## Security

OpenShell enforces security at the proxy level, all network traffic from the sandbox passes through a policy-aware proxy that filters requests by host, port, HTTP method, and URL path. Key protections:

- **Network isolation**: Only explicitly allowed endpoints are reachable. Random internet access is blocked.
- **Method-level control**: Policies can allow GET but block POST/DELETE on specific APIs.
- **IMDS blocked**: The OCI Instance Metadata Service (169.254.169.254) is not accessible from inside the sandbox, preventing instance principal credential theft.
- **Filesystem isolation**: Landlock restricts file access to designated read-only and read-write paths.

**Note on DinD:** The workspace container runs in privileged mode (required for Docker-in-Docker), this is a security risk.

## Deployment and Access

Please contact us if you want to try this pack out.

After deployment you get:

- **OpenClaw Dashboard**: The tokenized openclaw dashboard URL is in the stack outputs.
- **Web Terminal**: A browser-based terminal for running CLI commands inside the sandbox.
- **OCI AI Blueprints Portal**: The Blueprints portal URL for managing deployments.
