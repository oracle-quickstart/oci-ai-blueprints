## What is OCI AI Blueprints?

**OCI AI Blueprints** is a streamlined, no-code solution for deploying and managing Generative AI workloads on Oracle Cloud Infrastructure (OCI). By providing opinionated hardware recommendations, pre-packaged software stacks, and out-of-the-box observability tooling, OCI AI Blueprints helps you get your AI applications running quickly and efficiently—without wrestling with the complexities of infrastructure decisions, software compatibility, and MLOps best practices.

---

## Why use OCI AI Blueprints

### Enterprises face three main challenges when running GenAI workloads on OCI

1. **Hardware Decisions**  
   Choosing the right GPUs, networking, and storage configurations can be a painful, time-consuming process for data scientists and ML engineers.

2. **Software Stack Complexity**  
   Selecting and maintaining frameworks (e.g., PyTorch, TensorFlow), drivers (e.g., CUDA), and libraries can be difficult and error-prone. Ensuring ongoing compatibility can stall project timelines.

3. **Observability & MLOps**  
   Standing up a robust MLOps stack—monitoring, auto-scaling, experiment tracking—often involves Kubernetes expertise and custom tooling that can be tedious to maintain.

### How OCI AI Blueprints Solves These Challenges

1. **Validated Hardware Recommendations**  
   Deploy your GenAI workloads with confidence using pre-packaged blueprints tested on recommended OCI GPU, CPU, and networking configurations. This saves you from time-consuming performance benchmarking and guesswork.

2. **Opinionated, Pre-Packaged Software Stacks**  
   Each blueprint includes the necessary frameworks, libraries, and model configurations for a specific AI use case (e.g., RAG, fine-tuning, inference). Power users can further customize or swap out components as needed.

3. **Built-In Observability and Auto-Scaling**  
   By automating MLOps tasks—monitoring, logging, and scaling—OCI AI Blueprints simplifies infrastructure management. Tools like Prometheus, Grafana, MLFlow, and KEDA are automatically installed, giving you a production-grade environment with minimal effort.

---

## Features

| Feature                        | Description                                                                                                                             | Instructions                                                  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Customize Blueprints**       | Tailor existing OCI AI Blueprints to suit your exact AI workload needs—everything from hyperparameters to node counts and hardware.     | [Read More](../custom_blueprints/README.md)                   |
| **Updating OCI AI Blueprints** | Keep your OCI AI Blueprints environment current with the latest control plane and portal updates.                                       | [Read More](../installing_new_updates/README.md)              |
| **Shared Node Pool**           | Use longer-lived resources (e.g., bare metal nodes) across multiple blueprints or to persist resources after a blueprint is undeployed. | [Read More](../sample_blueprints/shared_node_pools/README.md) |
| **File Storage Service**       | Store and supply model weights using OCI File Storage Service for blueprint deployments.                                                | [Read More](../fss/README.md)                                 |
| **Auto-Scaling**               | Automatically adjust resource usage based on infrastructure or application-level metrics to optimize performance and costs.             | [Read More](../sample_blueprints/auto_scaling/README.md)      |

---

## Repository Contents

This repository provides comprehensive Terraform scripts that provision and configure:

1. An ATP database instance
2. Grafana & Prometheus for monitoring
3. MLFlow for experiment tracking
4. KEDA for dynamic auto-scaling
5. The OCI AI Blueprints front-end and back-end in an OKE cluster of your choice

Once installed, you can:

- Access the **OCI AI Blueprints Portal** and **API**.
- Deploy or undeploy blueprints for inference, training, and more.
- Deploy custom container images for your AI/ML workloads by simply pointing to the image URL.

---

## Frequently Asked Questions (FAQ)

**Q: What is the safest way to test OCI AI Blueprints in my tenancy?**  
A: Create a separate compartment and OKE cluster, then deploy OCI AI Blueprints there. This isolates any potential impacts.

**Q: Which containers and resources get deployed in my tenancy?**  
A:

1. OCI AI Blueprints front-end and back-end containers
2. Grafana & Prometheus (monitoring)
3. MLFlow (experiment tracking)
4. KEDA (application-based auto-scaling)

**Q: How can I run inference benchmarking?**  
A: Deploy a vLLM blueprint, then use a tool like LLMPerf to run benchmarking against your inference endpoint. Contact us for more details.

**Q: Where can I see the full list of blueprints?**  
A: All available blueprints are listed [here](../sample_blueprints/README.md). If you need something custom, please let us know.

**Q: How do I check logs for troubleshooting?**  
A: Use `kubectl` to inspect pod logs in your OKE cluster.

**Q: Does OCI AI Blueprints support auto-scaling?**  
A: Yes, we leverage KEDA for application-driven auto-scaling. See [documentation](../auto_scaling/README.md).

**Q: Which GPUs are compatible?**  
A: Any NVIDIA GPUs available in your OCI region (A10, A100, H100, etc.).

**Q: Can I deploy to an existing OKE cluster?**  
A: Yes, though testing on clusters running other workloads is ongoing. We recommend a clean cluster for best stability.

**Q: How do I run multiple blueprints on the same node?**  
A: Enable shared node pools. [Read more here](../sample_blueprints/shared_node_pools/README.md).
