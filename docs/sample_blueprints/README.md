# Sample Blueprints

## Overview

This page provides an overview of all available sample blueprint categories. Each category contains multiple pre-configured recipes that demonstrate specific features and use cases for OCI AI Blueprints.

## How to use

You may use any blueprint JSON from these categories as the payload in the `/deployment` endpoint. You are free to change any parameter as you would like, however, the parameters chosen have been tested and validated. Any changes you make to these sample blueprints, we cannot guarantee their efficiency or correctness.

## Sample Blueprint Categories

| Feature Category                                                 | Type           | Documentation                                        | Description                                                                                 |
| ---------------------------------------------------------------- | -------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| [Autoscaling](platform_feature_blueprints/auto_scaling/README.md)                                     | Inference      | [Guide](platform_feature_blueprints/auto_scaling/README.md)                      | Scale inference workloads based on traffic load with automatic pod and node scaling         |
| [CPU Inference](workload_blueprints/cpu-inference/README.md)                                  | Inference      | [Guide](workload_blueprints/cpu-inference/README.md)                     | Deploy CPU-based inference with Ollama for cost-effective and GPU-free model serving        |
| [Existing Cluster Installation](platform_feature_blueprints/exisiting_cluster_installation/README.md) | Infrastructure | [Guide](platform_feature_blueprints/exisiting_cluster_installation/README.md)    | Deploy OCI AI Blueprints on your existing OKE cluster without creating new infrastructure   |
| [GPU Health Check](workload_blueprints/gpu-health-check/README.md)                            | Diagnostics    | [Guide](workload_blueprints/gpu-health-check/README.md)                  | Comprehensive GPU health validation and diagnostics for production readiness                |
| [vLLM Inference](workload_blueprints/llm_inference_with_vllm/README.md)                       | Inference      | [Guide](workload_blueprints/llm_inference_with_vllm/README.md)           | Deploy large language models using vLLM for high-performance inference                      |
| [Llama Stack](workload_blueprints/llama-stack/README.md)                                      | Application    | [Guide](workload_blueprints/llama-stack/README.md)                       | Complete GenAI runtime with vLLM, ChromaDB, Postgres, and Jaeger for production deployments |
| [LoRA Benchmarking](workload_blueprints/lora-benchmarking/README.md)                          | Training       | [Guide](workload_blueprints/lora-benchmarking/README.md)                 | Benchmark fine-tuning performance using MLCommons methodology                               |
| [LoRA Fine-Tuning](workload_blueprints/lora-fine-tuning/README.md)                            | Training       | [Guide](workload_blueprints/lora-fine-tuning/README.md)                  | Efficiently fine-tune large language models using Low-Rank Adaptation                       |
| [Multi-Instance GPU](platform_feature_blueprints/mig_multi_instance_gpu/README.md)                    | Infrastructure | [Guide](platform_feature_blueprints/mig_multi_instance_gpu/README.md)            | Partition H100 GPUs into multiple isolated instances for efficient resource sharing         |
| [Model Storage](platform_feature_blueprints/model_storage/README.md)                                  | Storage        | [Guide](platform_feature_blueprints/model_storage/README.md)                     | Download and store models from HuggingFace to OCI Object Storage                            |
| [Multi-Node Inference](workload_blueprints/multi-node-inference/README.md)                    | Inference      | [Guide](workload_blueprints/multi-node-inference/README.md)              | Scale large language model inference across multiple GPU nodes                              |
| [Shared Node Pools](platform_feature_blueprints/shared_node_pools/README.md)                          | Infrastructure | [Guide](platform_feature_blueprints/shared_node_pools/README.md)                 | Create persistent node pools for efficient blueprint deployment                             |
| [Teams](platform_feature_blueprints/teams/README.md)                                                  | Management     | [Guide](platform_feature_blueprints/teams/README.md)                             | Enforce resource quotas and fair sharing between teams using Kueue                          |
| [RDMA Node Pools](platform_feature_blueprints/using_rdma_enabled_node_pools/README.md)                | Infrastructure | [Guide](platform_feature_blueprints/using_rdma_enabled_node_pools/README.md)     | Enable high-performance inter-node communication using Remote Direct Memory Access          |
| [Startup & Health Probes](platform_feature_blueprints/startup_liveness_readiness_probes/README.md)    | Configuration  | [Guide](platform_feature_blueprints/startup_liveness_readiness_probes/README.md) | Configure application health monitoring and startup validation                              |
