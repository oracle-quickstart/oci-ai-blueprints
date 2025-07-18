# Install OCI AI Blueprints onto an Existing OKE Cluster

#### Deploy OCI AI Blueprints on your existing OKE cluster without creating new infrastructure

This guide helps you install and use **OCI AI Blueprints** on an existing OKE cluster that was created outside of blueprints and already has workflows running on it. Rather than installing blueprints onto a new cluster, you can leverage an existing cluster with node pools and tools already installed.

The installation process involves ensuring you have the correct IAM policies in place, retrieving existing cluster OKE and VCN information from the console, deploying the OCI AI Blueprints application onto the existing cluster, and optionally adding existing nodes to be used by blueprints. You can then deploy sample recipes to test functionality.

Key considerations include managing existing tooling like Prometheus, Grafana, or the GPU operator that may already be installed on your cluster. The blueprint installation process can detect and work around these existing components. Additionally, if you have the nvidia-gpu-operator installed and plan to use Multi-Instance GPUs with H100 nodes, special configuration steps are available.

This approach allows you to:

- Leverage existing cluster resources and configurations
- Add blueprints capabilities without disrupting current workloads
- Utilize existing node pools for blueprint deployments
- Maintain compatibility with pre-installed cluster tools

## Pre-Filled Samples

| Feature Showcase                                                                              | Title                              | Description                                                                                                                                                               | Blueprint File                                                   |
| --------------------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Add existing cluster nodes to OCI AI Blueprints control plane for shared resource utilization | Add Existing Node to Control Plane | Configures an existing cluster node to be managed by OCI AI Blueprints, enabling shared node pool functionality and resource optimization across existing infrastructure. | [add_node_to_control_plane.json](add_node_to_control_plane.json) |

For complete step-by-step instructions, see the [full installation guide](../../../../INSTALLING_ONTO_EXISTING_CLUSTER_README.md).
