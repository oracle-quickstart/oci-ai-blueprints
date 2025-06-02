# Sample Blueprints

## Overview

This page provides an overview of all available sample blueprint categories. Each category contains multiple pre-configured recipes that demonstrate specific features and use cases for OCI AI Blueprints.

## How to use

You may use any blueprint JSON from these categories as the payload in the `/deployment` endpoint. You are free to change any parameter as you would like, however, the parameters chosen have been tested and validated. Any changes you make to these sample blueprints, we cannot guarantee their efficiency or correctness.

## Sample Blueprint Categories

| Feature Category                                                 | Type           | Documentation                                        | Description                                                                               |
| ---------------------------------------------------------------- | -------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [Autoscaling](auto_scaling/)                                     | Inference      | [Guide](auto_scaling/README.md)                      | Scale inference workloads based on traffic load with automatic pod and node scaling       |
| [CPU Inference](cpu-inference/)                                  | Inference      | [Guide](cpu-inference/README.md)                     | Deploy CPU-based inference with Ollama for cost-effective and GPU-free model serving      |
| [Existing Cluster Installation](exisiting_cluster_installation/) | Infrastructure | [Guide](exisiting_cluster_installation/README.md)    | Deploy OCI AI Blueprints on your existing OKE cluster without creating new infrastructure |
| [GPU Health Check](gpu-health-check/)                            | Diagnostics    | [Guide](gpu-health-check/README.md)                  | Comprehensive GPU health validation and diagnostics for production readiness              |
| [vLLM Inference](llm_inference_with_vllm/)                       | Inference      | [Guide](llm_inference_with_vllm/README.md)           | Deploy large language models using vLLM for high-performance inference                    |
| [LoRA Benchmarking](lora-benchmarking/)                          | Training       | [Guide](lora-benchmarking/README.md)                 | Benchmark fine-tuning performance using MLCommons methodology                             |
| [LoRA Fine-Tuning](lora-fine-tuning/)                            | Training       | [Guide](lora-fine-tuning/README.md)                  | Efficiently fine-tune large language models using Low-Rank Adaptation                     |
| [Multi-Instance GPU](mig_multi_instance_gpu/)                    | Infrastructure | [Guide](mig_multi_instance_gpu/README.md)            | Partition H100 GPUs into multiple isolated instances for efficient resource sharing       |
| [Model Storage](model_storage/)                                  | Storage        | [Guide](model_storage/README.md)                     | Download and store models from HuggingFace to OCI Object Storage                          |
| [Multi-Node Inference](multi-node-inference/)                    | Inference      | [Guide](multi-node-inference/README.md)              | Scale large language model inference across multiple GPU nodes                            |
| [Shared Node Pools](shared_node_pools/)                          | Infrastructure | [Guide](shared_node_pools/README.md)                 | Create persistent node pools for efficient blueprint deployment                           |
| [Teams](teams/)                                                  | Management     | [Guide](teams/README.md)                             | Enforce resource quotas and fair sharing between teams using Kueue                        |
| [RDMA Node Pools](using_rdma_enabled_node_pools/)                | Infrastructure | [Guide](using_rdma_enabled_node_pools/README.md)     | Enable high-performance inter-node communication using Remote Direct Memory Access        |
| [Startup & Health Probes](startup_liveness_readiness_probes/)    | Configuration  | [Guide](startup_liveness_readiness_probes/README.md) | Configure application health monitoring and startup validation                            |
