# Offline Inference Blueprint - Infra (vLLM)

#### Run offline LLM inference benchmarks using vLLM with automated performance tracking and MLflow logging.

This blueprint provides a configurable framework to run **offline LLM inference benchmarks** using vLLM as the inference engine. It is designed for cloud GPU environments and supports automated performance benchmarking with MLflow logging.

This blueprint enables you to:

- Run inference locally on GPU nodes using pre-loaded models
- Benchmark token throughput, latency, and request performance
- Push results to MLflow for comparison and analysis

---

## Pre-Filled Samples

| Feature Showcase                                                                                                           | Title                                | Description                                                                        | Blueprint File                                                       |
| -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Spin up GPU infrastructure via shared node pool to avoid hardware recycle times between different blueprint benchmark runs | Create VM A10 Shared Node Pool       | Creates a shared node pool using a selector `shared_pool` and `VM.GPU.A10.2` shape | [shared_node_pool_a10.json](shared_node_pool_a10.json)               |
| Benchmark LLM performance using vLLM backend with offline inference for token throughput analysis                          | Offline inference with LLAMA 3- vLLM | Benchmarks Meta-Llama-3.1-8B model using vLLM on VM.GPU.A10.2 with 2 GPUs.         | [offline-benchmark-blueprint.json](offline-benchmark-blueprint.json) |

You can access these pre-filled samples from the OCI AI Blueprint portal.

---

## When to use Offline inference

Offline inference is ideal for:

- Accurate performance benchmarking (no API or network bottlenecks)
- Comparing GPU hardware performance (A10, A100, H100, MI300X)
- Evaluating backend frameworks (inference engines) like vLLM

---

## Supported Backends

| Backend | Description                                                         |
| ------- | ------------------------------------------------------------------- |
| vllm    | Token streaming inference engine for LLMs with speculative decoding |

---

## Running the Benchmark

- Things need to run the benchmark
  - Your MLFlow URL (this can be found via the GET `workspace/` endpoint or under the `Deployments` tab if using the portal)
  - A node pool with GPU hardware (this can be done by deploying the shared node pool pre-filled sample here)
  - Model checkpoints pre-downloaded and stored in an object storage.
  - Make sure to get a PAR for the object storage where the models are saved. With listing, write and read perimissions
  - Configured benchmarking blueprint - make sure to update the MLFlow URL (ex `https://mlflow.121-158-72-41.nip.io`)

This blueprint supports benchmark execution via job-mode (the benchmarking container will spin up, benchmark, then spin down once the benchmarking is complete). The recipe mounts a model and config file from Object Storage (hence the need for a PAR link), runs offline inference, and logs metrics to MlFlow.

---

## Metrics Logged

- `requests_per_second`
- `input_tokens_per_second`
- `output_tokens_per_second`
- `total_tokens_per_second`
- `elapsed_time`
- `total_input_tokens`
- `total_output_tokens`

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

### Recipe Container Environment Variables

| Key                    | Description                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `backend`              | Set to `vllm` since we are using vLLM as the inference engine backend                                                                                             |
| `model`                | Name of the model - note this should be the same as the path to the model directory (already mounted via Object Storage).                                         |
| `tokenizer`            | Name of the tokenizer - this will almost always be the same as the model name and the path to the model (usually same as model path).                             |
| `input-len`            | Number of tokens in the input prompt.                                                                                                                             |
| `output-len`           | Number of tokens to generate.                                                                                                                                     |
| `num-prompts`          | Number of total prompts to run (e.g., 64 prompts x 128 output tokens).                                                                                            |
| `tensor-parallel-size` | Number of parallelism groups to partition tensors across the GPUs to enable parallel computation. This should almost always be set to the number of GPUs per node |
| `max-model-len`        | Largest context length (prompt and output) allowed for the given model                                                                                            |
| `dtype`                | Precision (e.g., float16, bfloat16, auto).                                                                                                                        |
| `mlflow_uri`           | MLflow server to log performance metrics. Make sure to include `https://` before the url but do not include the port it is listening on such as `:5000`           |
| `experiment_name`      | Experiment name to group runs in MLflow UI.                                                                                                                       |
| `run_name`             | Custom name to identify this particular run.                                                                                                                      |

---
