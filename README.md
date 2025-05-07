# OCI AI Blueprints
**Deploy, scale, and monitor AI workloads with the OCI AI Blueprints platform, and reduce your GPU onboarding time from weeks to minutes.**

OCI AI Blueprints is a streamlined, no-code solution for deploying and managing Generative AI workloads on Kubernetes Engine (OKE). By providing opinionated hardware recommendations, pre-packaged software stacks, and out-of-the-box observability tooling, OCI AI Blueprints helps you get your AI applications running quickly and efficiently—without wrestling with the complexities of infrastructure decisions, software compatibility, and MLOps best practices.

[![Install OCI AI Blueprints](https://raw.githubusercontent.com/oracle-quickstart/oci-ai-blueprints/9d1d61b3b79e61dabe19d1672c3e54704b294a93/docs/install.svg)](./GETTING_STARTED_README.md)

## Table of Contents
**Getting Started**
- [Install AI Blueprints](./GETTING_STARTED_README.md)
- [Access AI Blueprints Portal and API](./docs/api_documentation/accessing_oci_ai_blueprints/README.md)

**About OCI AI Blueprints**
- [What is OCI AI Blueprints?](./docs/about/README.md#what-is-oci-ai-blueprints)
- [Why use OCI AI Blueprints?](./docs/about/README.md#why-use-oci-ai-blueprints)
- [Features](./docs/about/README.md#features)
- [List of Blueprints](#blueprints)
- [FAQ](./docs/about/README.md#frequently-asked-questions-faq)
- [Support & Contact](https://github.com/oracle-quickstart/oci-ai-blueprints/blob/vkammari/doc_improvements/docs/about/README.md#frequently-asked-questions-faq)

**API Reference**
- [API Reference Documentation](docs/api_documentation/README.md)

**Additional Resources**
- [Publish Custom Blueprints](./docs/custom_blueprints)
- [Installing Updates](./docs/installing_new_updates)
- [IAM Policies](./docs/iam_policies/README.md)
- [Repository Contents](./docs/about/README.md#repository-contents)
- [Known Issues](docs/known_issues/README.md)

## Getting Started
Install OCI AI Blueprints by clicking on the button below:

[![Install OCI AI Blueprints](https://raw.githubusercontent.com/oracle-quickstart/oci-ai-blueprints/9d1d61b3b79e61dabe19d1672c3e54704b294a93/docs/install.svg)](./GETTING_STARTED_README.md)

## Blueprints

Blueprints go beyond basic Terraform templates. Each blueprint:
- Offers validated hardware suggestions (e.g., optimal shapes, CPU/GPU configurations),
- Includes end-to-end application stacks customized for different GenAI use cases, and
- Comes with monitoring, logging, and auto-scaling configured out of the box.

After you install OCI AI Blueprints to an OKE cluster in your tenancy, you can deploy these pre-built blueprints:

| Blueprint                    | Description                                                                                                                             |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------|
| [**LLM & VLM Inference with vLLM**](./docs/sample_blueprints/vllm-inference)  | Deploy Llama 2/3/3.1 7B/8B models using NVIDIA GPU shapes and the vLLM inference engine with auto-scaling.                              |
| [**Fine-Tuning Benchmarking**](./docs/sample_blueprints/lora-benchmarking) | Run MLCommons quantized Llama-2 70B LoRA finetuning on A100 for performance benchmarking.                                               |
| [**LoRA Fine-Tuning**](./docs/sample_blueprints/lora-fine-tuning)         | LoRA fine-tuning of custom or HuggingFace models using any dataset. Includes flexible hyperparameter tuning.                            |
| [**Health Check**](./docs/sample_blueprints/gpu-health-check)             | Comprehensive evaluation of GPU performance to ensure optimal hardware readiness before initiating any intensive computational workload.|
| [**CPU Inference**](./docs/sample_blueprints/cpu-inference)            | Leverage Ollama to test CPU-based inference with models like Mistral, Gemma, and more.                                                  |
| [**Multi-node Inference with RDMA and vLLM**](./docs/multi_node_inference)            | Deploy Llama-405B sized LLMs across multiple nodes with RDMA using H100 nodes with vLLM and LeaderWorkerSet.                                          |
| [**Scaled Inference with vLLM**](./docs/auto_scaling)            | Serve LLMs with auto-scaling using KEDA, which scales to multiple GPUs and nodes using application metrics like inference latency.|
| [**LLM Inference with MIG**](./docs/mig_multi_instance_gpu)            | Deploy LLMs to a fraction of a GPU with Nvidia’s multi-instance GPUs and serve them with vLLM.                                                 |
| [**Health Check**](./docs/sample_blueprints/gpu-health-check)            | Comprehensive evaluation of GPU performance to ensure optimal hardware readiness before initiating any intensive computational workload.                 |

## Support & Contact

If you have any questions, issues, or feedback, contact [vishnu.kammari@oracle.com](mailto:vishnu.kammari@oracle.com) or [grant.neuman@oracle.com](mailto:grant.neuman@oracle.com).
