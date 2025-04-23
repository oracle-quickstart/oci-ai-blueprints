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
|Offline inference with LLAMA 3- vLLM| Benchmarks Meta-Llama-3.1-8B model using vLLM on VM.GPU.A10.2 with 2 GPUs.|

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
- Things need to run the benchmark 
  - Model checkpoints pre-downloaded and stored in an object storage.
  - Make sure to get a PAR for the object storage where the models are saved. With listing, write and read perimissions
  - A Bucket to save the outputs. This does not take a PAR, so should be a bucket in the same tenancy as to where you have your OCI blueprints stack
  - Config `.yaml` file that has all the parameters required to run the benhcmark. This includes input_len, output_len, gpu_utilization value etc. 
  - Deployment `.json` to deploy your blueprint. 
  - Sample deployment and config files are provided below along with links.

This blueprint supports benchmark execution via a job-mode recipe using a YAML config file. The recipe mounts a model and config file from Object Storage, runs offline inference, and logs metrics.

Notes : Make sure your output object storage is in the same tenancy as your stack. 
---

### [Sample Blueprint (Job Mode for Offline SGLang Inference)](dhttps://github.com/oracle-quickstart/oci-ai-blueprints/blob/offline-inference-benchmark/docs/sample_blueprints/offline-inference-infra/offline_deployment_sglang.json)

```json
{
    "recipe_id": "offline_inference_sglang",
    "recipe_mode": "job",
    "deployment_name": "Offline Inference Benchmark",
    "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:llm-benchmark-0409-v4",
    "recipe_node_shape": "VM.GPU.A10.2",
    "input_object_storage": [
      {
        "par": "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/0T99iRADcM08aVpumM6smqMIcnIJTFtV2D8ZIIWidUP9eL8GSRyDMxOb9Va9rmRc/n/iduyx1qnmway/b/mymodels/o/",
        "mount_location": "/models",
        "volume_size_in_gbs": 500,
        "include": [
          "new_example_sglang.yaml",
          "NousResearch/Meta-Llama-3.1-8B"
        ]
      }
    ],
    "output_object_storage": [
      {
        "bucket_name": "inference_output",
        "mount_location": "/mlcommons_output",
        "volume_size_in_gbs": 200
      }
    ],
    "recipe_container_command_args": [
      "/models/new_example_sglang.yaml"
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
### [Sample Blueprint (Job Mode for Offline vLLM Inference)](dhttps://github.com/oracle-quickstart/oci-ai-blueprints/blob/offline-inference-benchmark/docs/sample_blueprints/offline-inference-infra/offline_deployment_sglang.json)

```json
{
    "recipe_id": "offline_inference_vllm",
    "recipe_mode": "job",
    "deployment_name": "Offline Inference Benchmark vllm",
    "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:llm-benchmark-0409-v4",
    "recipe_node_shape": "VM.GPU.A10.2",
    "input_object_storage": [
      {
        "par": "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/0T99iRADcM08aVpumM6smqMIcnIJTFtV2D8ZIIWidUP9eL8GSRyDMxOb9Va9rmRc/n/iduyx1qnmway/b/mymodels/o/",
        "mount_location": "/models",
        "volume_size_in_gbs": 500,
        "include": [
          "offline_vllm_example.yaml",
          "NousResearch/Meta-Llama-3.1-8B"
        ]
      }
    ],
    "output_object_storage": [
      {
        "bucket_name": "inference_output",
        "mount_location": "/mlcommons_output",
        "volume_size_in_gbs": 200
      }
    ],
    "recipe_container_command_args": [
      "/models/offline_vllm_example.yaml"
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

## [Sample Config File SGlang - 1 (`new_example_sglang.yaml`)](https://github.com/oracle-quickstart/oci-ai-blueprints/blob/offline-inference-benchmark/docs/sample_blueprints/offline-inference-infra/new_example_sglang.yaml)

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


save_metrics_path: /mlcommons_output/benchmark_output_llama3_sglang.json

```
## [Sample Config File - 2 vLLM (`offline_vllm_example.yaml`)](https://github.com/oracle-quickstart/oci-ai-blueprints/blob/offline-inference-benchmark/docs/sample_blueprints/offline-inference-infra/offline_vllm_example.yaml)
```yaml
benchmark_type: offline
model: /models/NousResearch/Meta-Llama-3.1-8B
tokenizer: /models/NousResearch/Meta-Llama-3.1-8B

input_len: 12
output_len: 12
num_prompts: 2
seed: 42
tensor_parallel_size: 8

# vLLM-specific
#quantization: awq
dtype: half
gpu_memory_utilization: 0.99
num_scheduler_steps: 10
device: cuda
enforce_eager: true
kv_cache_dtype: auto
enable_prefix_caching: true
distributed_executor_backend: mp

# Output
#output_json: ./128_128.json

# MLflow
mlflow_uri: http://mlflow-benchmarking.corrino-oci.com:5000
experiment_name: test-bm-suite-doc
run_name: llama3-vllm-test
save_metrics_path:  /mlcommons_output/benchmark_output_llama3_vllm.json

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


### Top-level Deployment Keys

| Key | Description |
|-----|-------------|
| `recipe_id` | Identifier of the recipe to run; here, it's an offline SGLang benchmark job. |
| `recipe_mode` | Specifies this is a `job`, meaning it runs to completion and exits. |
| `deployment_name` | Human-readable name for the job. |
| `recipe_image_uri` | Docker image containing the benchmark code and dependencies. |
| `recipe_node_shape` | Shape of the VM or GPU node to run the job (e.g., VM.GPU.A10.2). |

### Input Object Storage

| Key | Description |
|-----|-------------|
| `input_object_storage` | List of inputs to mount from Object Storage. |
| `par` | Pre-Authenticated Request (PAR) link to a bucket/folder. |
| `mount_location` | Files are mounted to this path inside the container. |
| `volume_size_in_gbs` | Size of the mount volume. |
| `include` | Only these files/folders from the bucket are mounted (e.g., model + config). |

### Output Object Storage

| Key | Description |
|-----|-------------|
| `output_object_storage` | Where to store outputs like benchmark logs or results. |
| `bucket_name` | Name of the output bucket in OCI Object Storage. |
| `mount_location` | Mount point inside container where outputs are written. |
| `volume_size_in_gbs` | Size of this volume in GBs. |

### Runtime & Infra Settings

| Key | Description |
|-----|-------------|
| `recipe_container_command_args` | Path to the YAML config that defines benchmark parameters. |
| `recipe_replica_count` | Number of job replicas to run (usually 1 for inference). |
| `recipe_container_port` | Port (optional for offline mode; required if API is exposed). |
| `recipe_nvidia_gpu_count` | Number of GPUs allocated to this job. |
| `recipe_node_pool_size` | Number of nodes in the pool (1 means 1 VM). |
| `recipe_node_boot_volume_size_in_gbs` | Disk size for OS + dependencies. |
| `recipe_ephemeral_storage_size` | Local scratch space in GBs. |
| `recipe_shared_memory_volume_size_limit_in_mb` | Shared memory (used by some inference engines). |

---

## **Sample Config File (`example_sglang.yaml`)**

This file is consumed by the container during execution to configure the benchmark run.

### Inference Setup

| Key | Description |
|-----|-------------|
| `benchmark_type` | Set to `offline` to indicate local execution with no HTTP server. |
| `offline_backend` | Backend engine to use (`sglang` or `vllm`). |
| `model_path` | Path to the model directory (already mounted via Object Storage). |
| `tokenizer_path` | Path to the tokenizer (usually same as model path). |
| `trust_remote_code` | Enables loading models that require custom code (Hugging Face). |
| `conv_template` | Prompt formatting template to use (e.g., `llama-2`). |

### Benchmark Parameters

| Key | Description |
|-----|-------------|
| `input_len` | Number of tokens in the input prompt. |
| `output_len` | Number of tokens to generate. |
| `num_prompts` | Number of total prompts to run (e.g., 64 prompts x 128 output tokens). |
| `max_seq_len` | Max sequence length supported by the model (e.g., 4096). |
| `max_batch_size` | Max batch size per inference run (depends on GPU memory). |
| `dtype` | Precision (e.g., float16, bfloat16, auto). |

### Sampling Settings

| Key | Description |
|-----|-------------|
| `temperature` | Controls randomness in generation (lower = more deterministic). |
| `top_p` | Top-p sampling for diversity (0.9 keeps most probable tokens). |

### MLflow Logging

| Key | Description |
|-----|-------------|
| `mlflow_uri` | MLflow server to log performance metrics. |
| `experiment_name` | Experiment name to group runs in MLflow UI. |
| `run_name` | Custom name to identify this particular run. |

### Output

| Key | Description |
|-----|-------------|
| `save_metrics_path` | Path inside the container where metrics will be saved as JSON. |
