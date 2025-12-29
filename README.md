# OCI AI Blueprints

**Deploy, scale, and monitor AI workloads with the OCI AI Blueprints platform, and reduce your GPU onboarding time from weeks to minutes.**

OCI AI Blueprints is a streamlined, no-code solution for deploying and managing Generative AI workloads on Kubernetes Engine (OKE). By providing opinionated hardware recommendations, pre-packaged software stacks, and out-of-the-box observability tooling, OCI AI Blueprints helps you get your AI applications running quickly and efficiently—without wrestling with the complexities of infrastructure decisions, software compatibility, and MLOps best practices.

[![Install OCI AI Blueprints](https://raw.githubusercontent.com/oracle-quickstart/oci-ai-blueprints/refs/heads/main/docs/images/install.svg)](./GETTING_STARTED_README.md)

## Table of Contents

**Getting Started**

- [Install AI Blueprints](./GETTING_STARTED_README.md)
- [Access AI Blueprints Portal and API](docs/usage_guide.md)

**About OCI AI Blueprints**

- [What is OCI AI Blueprints?](docs/about.md)
- [Why use OCI AI Blueprints?](docs/about.md)
- [Features](docs/about.md)
- [List of Blueprints](#blueprints)
- [FAQ](docs/about.md)
- [Support & Contact](https://github.com/oracle-quickstart/oci-ai-blueprints/blob/vkammari/doc_improvements/docs/about/README.md#frequently-asked-questions-faq)

**API Reference**

- [API Reference Documentation](docs/api_documentation.md)

**Additional Resources**

- [Publish Custom Blueprints](./docs/custom_blueprints)
- [Installing Updates](docs/installing_new_updates.md)
- [IAM Policies](docs/iam_policies.md)
- [Repository Contents](docs/about.md)
- [Known Issues](docs/known_issues.md)

## Getting Started

Install OCI AI Blueprints by clicking on the button below:

[![Install OCI AI Blueprints](https://raw.githubusercontent.com/oracle-quickstart/oci-ai-blueprints/refs/heads/main/docs/images/install.svg)](./GETTING_STARTED_README.md)

## Blueprints

Blueprints go beyond basic Terraform templates. Each blueprint:

- Offers validated hardware suggestions (e.g., optimal shapes, CPU/GPU configurations),
- Includes end-to-end application stacks customized for different GenAI use cases, and
- Comes with monitoring, logging, and auto-scaling configured out of the box.

After you install OCI AI Blueprints to an OKE cluster in your tenancy, you can deploy these pre-built blueprints:

| Blueprint                                                                                     | Description                                                                                                                                     |
| --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| [**LLM Model Serving/Inference with vLLM**](docs/sample_blueprints/model_serving/llm_inference_with_vllm/README.md) | Deploy Llama 2/3/3.1 7B/8B models using NVIDIA GPU shapes and the vLLM inference engine with auto-scaling.                                      |
| [**Llama Stack**](docs/sample_blueprints/partner_blueprints/llama-stack/README.md)                                       | Complete GenAI runtime with vLLM, ChromaDB, Postgres, and Jaeger for production deployments with unified API for inference, RAG, and telemetry. |
| [**Fine-Tuning Benchmarking**](docs/sample_blueprints/gpu_benchmarking/lora-benchmarking/README.md)                    | Run MLCommons quantized Llama-2 70B LoRA finetuning on A100 for performance benchmarking.                                                       |
| [**LoRA Fine-Tuning**](docs/sample_blueprints/model_fine_tuning/lora-fine-tuning/README.md)                             | LoRA fine-tuning of custom or HuggingFace models using any dataset. Includes flexible hyperparameter tuning.                                    |
| [**GPU Performance Benchmarking**](docs/sample_blueprints/gpu_health_check/gpu-health-check/README.md)                 | Comprehensive evaluation of GPU performance to ensure optimal hardware readiness before initiating any intensive computational workload.        |
| [**CPU Inference**](docs/sample_blueprints/model_serving/cpu-inference/README.md)                                   | Leverage Ollama to test CPU-based inference with models like Mistral, Gemma, and more.                                                          |
| [**Multi-node Inference with RDMA and vLLM**](docs/sample_blueprints/model_serving/multi-node-inference/README.md) | Deploy Llama-405B sized LLMs across multiple nodes with RDMA using H100 nodes with vLLM and LeaderWorkerSet.                                    |
| [**Autoscaling Inference with vLLM**](docs/sample_blueprints/model_serving/auto_scaling/README.md)                 | Serve LLMs with auto-scaling using KEDA, which scales to multiple GPUs and nodes using application metrics like inference latency.              |
| [**LLM Inference with MIG**](docs/sample_blueprints/model_serving/mig_multi_instance_gpu/README.md)                | Deploy LLMs to a fraction of a GPU with Nvidia’s multi-instance GPUs and serve them with vLLM.                                                  |
| [**Job Queuing**](docs/sample_blueprints/platform_features/teams/README.md)                                             | Take advantage of job queuing and enforce resource quotas and fair sharing between teams.                                                       |

## Support & Contact

If you have any questions, issues, or feedback, contact [vishnu.kammari@oracle.com](mailto:vishnu.kammari@oracle.com) or [grant.neuman@oracle.com](mailto:grant.neuman@oracle.com).

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md)

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2024, 2025 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
