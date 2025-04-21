# Offline Inference Blueprint - Infra (SGLang + vLLM)

This blueprint provides a configurable framework to run **offline LLM inference benchmarks** using either the SGLang or vLLM backends. It is designed for cloud GPU environments and supports automated performance benchmarking with MLflow logging.

This blueprint enables you to:
- Run inference locally on GPU nodes using pre-loaded models
- Benchmark token throughput, latency, and request performance
- Push results to MLflow for comparison and analysis

---

## Pre-Filled Samples

| Title                         | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
|Offline inference with LLaMA 3|Benchmarks Meta-Llama-3.1-8B model using SGLang on VM.GPU.A10.2 with 2 GPUs. |

You can access these pre-filled samples from the OCI AI Blueprint portal.

---
## When to use Offline inference 

Offline inference is ideal for:
- Accurate performance benchmarking (no API or network bottlenecks)
- Comparing GPU hardware performance (A10, A100, H100, MI300X)
- Evaluating backend frameworks like vLLM and SGLang

---

## Supported Backends

| Backend  | Description                                                  |
|----------|--------------------------------------------------------------|
| sglang   | Fast multi-modal LLM backend with optimized throughput      |
| vllm     | Token streaming inference engine for LLMs with speculative decoding |

---

## Running the Benchmark

This blueprint supports benchmark execution via a job-mode recipe using a YAML config file. The recipe mounts a model and config file from Object Storage, runs offline inference, and logs metrics.

---

### Sample Recipe (Job Mode for Offline SGLang Inference)

```json
{
  "recipe_id": "offline_inference_sglang",
  "recipe_mode": "job",
  "deployment_name": "Offline Inference Benchmark",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:llm-benchmark-0409-v2",
  "recipe_node_shape": "VM.GPU.A10.2",
  "input_object_storage": [
    {
      "par": "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/Z2q73uuLCAxCbGXJ99CIeTxnCTNipsE-1xHE9HYfCz0RBYPTcCbqi9KHViUEH-Wq/n/iduyx1qnmway/b/mymodels/o/",
      "mount_location": "/models",
      "volume_size_in_gbs": 500,
      "include": [
        "example_sglang.yaml",
        "NousResearch/Meta-Llama-3.1-8B"
      ]
    }
  ],
  "recipe_container_command_args": [
    "/models/example_sglang.yaml"
  ],
  "recipe_replica_count": 1,
  "recipe_container_port": "8000",
  "recipe_nvidia_gpu_count": 2,
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_ephemeral_storage_size": 100,
  "recipe_shared_memory_volume_size_limit_in_mb": 200
}
```

---

## Sample Config File (`example_sglang.yaml`)

```yaml
benchmark_type: offline
offline_backend: sglang

model_path: /models/NousResearch/Meta-Llama-3.1-8B
tokenizer_path: /models/NousResearch/Meta-Llama-3.1-8B
trust_remote_code: true
conv_template: llama-2

input_len: 128
output_len: 128
num_prompts: 64
max_seq_len: 4096
max_batch_size: 8
dtype: auto
temperature: 0.7
top_p: 0.9

mlflow_uri: http://mlflow-benchmarking.corrino-oci.com:5000
experiment_name: "sglang-bench-doc-test-new"
run_name: "llama3-8b-sglang-test"
```

---

## Metrics Logged

- `requests_per_second`
- `input_tokens_per_second`
- `output_tokens_per_second`
- `total_tokens_per_second`
- `elapsed_time`
- `total_input_tokens`
- `total_output_tokens`

If a dataset is provided:
- `accuracy`
