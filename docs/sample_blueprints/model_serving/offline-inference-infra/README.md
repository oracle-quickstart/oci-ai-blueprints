# Offline Inference Blueprint - Infra (SGLang + vLLM)

#### Run offline LLM inference benchmarks using SGLang or vLLM backends with automated performance tracking and MLflow logging.

This blueprint provides a configurable framework to run **offline LLM inference benchmarks** using either the SGLang or vLLM backends. It is designed for cloud GPU environments and supports automated performance benchmarking with MLflow logging.

This blueprint enables you to:

- Run inference locally on GPU nodes using pre-loaded models
- Benchmark token throughput, latency, and request performance
- Push results to MLflow for comparison and analysis

---

## Pre-Filled Samples

| Feature Showcase                                                                                           | Title                                | Description                                                                  | Blueprint File                                                   |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Benchmark LLM performance using SGLang backend with offline inference for accurate performance measurement | Offline inference with LLaMA 3       | Benchmarks Meta-Llama-3.1-8B model using SGLang on VM.GPU.A10.2 with 2 GPUs. | [offline_deployment_sglang.json](offline_deployment_sglang.json) |
| Benchmark LLM performance using vLLM backend with offline inference for token throughput analysis          | Offline inference with LLAMA 3- vLLM | Benchmarks Meta-Llama-3.1-8B model using vLLM on VM.GPU.A10.2 with 2 GPUs.   | [offline_deployment_vllm.json](offline_deployment_vllm.json)     |

You can access these pre-filled samples from the OCI AI Blueprint portal.

---

## When to use Offline inference

Offline inference is ideal for:

- Accurate performance benchmarking (no API or network bottlenecks)
- Comparing GPU hardware performance (A10, A100, H100, MI300X)
- Evaluating backend frameworks like vLLM and SGLang

---

## Supported Backends

| Backend | Description                                                         |
| ------- | ------------------------------------------------------------------- |
| sglang  | Fast multi-modal LLM backend with optimized throughput              |
| vllm    | Token streaming inference engine for LLMs with speculative decoding |

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

### Notes : Make sure your output object storage is in the same tenancy as your stack.

## Sample Blueprints

[Sample Blueprint (Job Mode for Offline SGLang Inference)](offline_deployment_sglang.json)
[Sample Blueprint (Job Mode for Offline vLLM Inference)](offline_deployment_vllm.json)
[Sample Config File SGlang ](offline_sglang_example.yaml)
[Sample Config File - vLLM ](offline_vllm_example.yaml)

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

| Key                 | Description                                                                  |
| ------------------- | ---------------------------------------------------------------------------- |
| `recipe_id`         | Identifier of the recipe to run; here, it's an offline SGLang benchmark job. |
| `recipe_mode`       | Specifies this is a `job`, meaning it runs to completion and exits.          |
| `deployment_name`   | Human-readable name for the job.                                             |
| `recipe_image_uri`  | Docker image containing the benchmark code and dependencies.                 |
| `recipe_node_shape` | Shape of the VM or GPU node to run the job (e.g., VM.GPU.A10.2).             |

### Input Object Storage

| Key                    | Description                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| `input_object_storage` | List of inputs to mount from Object Storage.                                 |
| `par`                  | Pre-Authenticated Request (PAR) link to a bucket/folder.                     |
| `mount_location`       | Files are mounted to this path inside the container.                         |
| `volume_size_in_gbs`   | Size of the mount volume.                                                    |
| `include`              | Only these files/folders from the bucket are mounted (e.g., model + config). |

### Output Object Storage

| Key                     | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `output_object_storage` | Where to store outputs like benchmark logs or results.  |
| `bucket_name`           | Name of the output bucket in OCI Object Storage.        |
| `mount_location`        | Mount point inside container where outputs are written. |
| `volume_size_in_gbs`    | Size of this volume in GBs.                             |

### Runtime & Infra Settings

| Key                                            | Description                                                   |
| ---------------------------------------------- | ------------------------------------------------------------- |
| `recipe_container_command_args`                | Path to the YAML config that defines benchmark parameters.    |
| `recipe_replica_count`                         | Number of job replicas to run (usually 1 for inference).      |
| `recipe_container_port`                        | Port (optional for offline mode; required if API is exposed). |
| `recipe_nvidia_gpu_count`                      | Number of GPUs allocated to this job.                         |
| `recipe_node_pool_size`                        | Number of nodes in the pool (1 means 1 VM).                   |
| `recipe_node_boot_volume_size_in_gbs`          | Disk size for OS + dependencies.                              |
| `recipe_ephemeral_storage_size`                | Local scratch space in GBs.                                   |
| `recipe_shared_memory_volume_size_limit_in_mb` | Shared memory (used by some inference engines).               |

---

## **Sample Config File (`example_sglang.yaml`)**

This file is consumed by the container during execution to configure the benchmark run.

### Inference Setup

| Key                 | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| `benchmark_type`    | Set to `offline` to indicate local execution with no HTTP server. |
| `offline_backend`   | Backend engine to use (`sglang` or `vllm`).                       |
| `model_path`        | Path to the model directory (already mounted via Object Storage). |
| `tokenizer_path`    | Path to the tokenizer (usually same as model path).               |
| `trust_remote_code` | Enables loading models that require custom code (Hugging Face).   |
| `conv_template`     | Prompt formatting template to use (e.g., `llama-2`).              |

### Benchmark Parameters

| Key              | Description                                                            |
| ---------------- | ---------------------------------------------------------------------- |
| `input_len`      | Number of tokens in the input prompt.                                  |
| `output_len`     | Number of tokens to generate.                                          |
| `num_prompts`    | Number of total prompts to run (e.g., 64 prompts x 128 output tokens). |
| `max_seq_len`    | Max sequence length supported by the model (e.g., 4096).               |
| `max_batch_size` | Max batch size per inference run (depends on GPU memory).              |
| `dtype`          | Precision (e.g., float16, bfloat16, auto).                             |

### Sampling Settings

| Key           | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| `temperature` | Controls randomness in generation (lower = more deterministic). |
| `top_p`       | Top-p sampling for diversity (0.9 keeps most probable tokens).  |

### MLflow Logging

| Key               | Description                                  |
| ----------------- | -------------------------------------------- |
| `mlflow_uri`      | MLflow server to log performance metrics.    |
| `experiment_name` | Experiment name to group runs in MLflow UI.  |
| `run_name`        | Custom name to identify this particular run. |

### Output

| Key                 | Description                                                    |
| ------------------- | -------------------------------------------------------------- |
| `save_metrics_path` | Path inside the container where metrics will be saved as JSON. |
