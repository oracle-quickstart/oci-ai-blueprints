# CPU Inference Blueprint

#### Deploy CPU-based inference with Ollama for cost-effective and GPU-free model serving

This blueprint provides a comprehensive framework for testing inference on CPUs using the Ollama platform with a variety of supported models such as Mistral, Gemma, and others available through Ollama. Unlike GPU-dependent solutions, this blueprint is designed for environments where CPU inference is preferred or required. It offers clear guidelines and configuration settings to deploy a robust CPU inference service, enabling thorough performance evaluations and reliability testing. Ollama's lightweight and efficient architecture makes it an ideal solution for developers looking to benchmark and optimize CPU-based inference workloads.

This blueprint explains how to use CPU inference for running large language models using Ollama. It includes two main deployment strategies:

- Serving pre-saved models directly from Object Storage
- Pulling models from Ollama and saving them to Object Storage

## Pre-Filled Samples

| Feature Showcase                                                              | Title                                              | Description                                                                                              | Blueprint File                                                 |
| ----------------------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Deploy Mistral model on bare metal compute for high-performance CPU inference | CPU inference with Mistral and BM.Standard.E4      | Deploys CPU inference with Mistral and BM.Standard.E4 on BM.Standard.E4.128 with undefined GPU(s).       | [cpu-inference-mistral-bm.json](cpu-inference-mistral-bm.json) |
| Deploy Gemma model on high-memory bare metal for large model CPU inference    | CPU inference with Gemma and BM.Standard.E5.192    | Deploys CPU inference with Gemma and BM.Standard.E5.192 on BM.Standard.E5.192 with undefined GPU(s).     | [cpu-inference-gemma.json](cpu-inference-gemma.json)           |
| Deploy Mistral model on flexible VM compute for cost-optimized CPU inference  | CPU inference with mistral and VM.Standard.E4.Flex | Deploys CPU inference with mistral and VM.Standard.E4.Flex on VM.Standard.E4.Flex with undefined GPU(s). | [cpu-inference-mistral-vm.json](cpu-inference-mistral-vm.json) |

---

## Why CPU Inference?

CPU inference is ideal for:

- Low-throughput or cost-sensitive deployments
- Offline testing and validation
- Prototyping without GPU dependency

---

## Supported Models

Ollama supports several high-quality open-source LLMs. Below is a small set of commonly used models:

| Model Name | Description                    |
| ---------- | ------------------------------ |
| gemma      | Lightweight open LLM by Google |
| llama2     | Meta's large language model    |
| mistral    | Open-weight performant LLM     |
| phi3       | Microsoft's compact LLM        |

---

## Deploying with OCI AI Blueprint

### Running Ollama Models from Object Storage

If you've already pushed your model to **Object Storage**, use the following service-mode recipe to run it. Ensure your model files are in the **blob + manifest** format used by Ollama.

#### Recipe Configuration

| Field                               | Description                                 |
| ----------------------------------- | ------------------------------------------- |
| recipe_id                           | `cpu_inference` – Identifier for the recipe |
| recipe_mode                         | `service` – Used for long-running inference |
| deployment_name                     | Custom name for the deployment              |
| recipe_image_uri                    | URI for the container image in OCIR         |
| recipe_node_shape                   | OCI shape, e.g., `BM.Standard.E4.128`       |
| input_object_storage                | Object Storage bucket mounted as input      |
| recipe_container_env                | List of environment variables               |
| recipe_replica_count                | Number of replicas                          |
| recipe_container_port               | Port to expose the container                |
| recipe_node_pool_size               | Number of nodes in the pool                 |
| recipe_node_boot_volume_size_in_gbs | Boot volume size in GB                      |
| recipe_container_command_args       | Arguments for the container command         |
| recipe_ephemeral_storage_size       | Temporary scratch storage                   |

#### Sample Recipe (Service Mode)

```json
{
  "recipe_id": "cpu_inference",
  "recipe_mode": "service",
  "deployment_name": "gemma and BME4 service",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:cpu_inference_service_v0.2",
  "recipe_node_shape": "BM.Standard.E4.128",
  "input_object_storage": [
    {
      "bucket_name": "ollama-models",
      "mount_location": "/models",
      "volume_size_in_gbs": 20
    }
  ],
  "recipe_container_env": [
    { "key": "MODEL_NAME", "value": "gemma" },
    { "key": "PROMPT", "value": "What is the capital of France?" }
  ],
  "recipe_replica_count": 1,
  "recipe_container_port": "11434",
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_container_command_args": [
    "--input_directory",
    "/models",
    "--model_name",
    "gemma"
  ],
  "recipe_ephemeral_storage_size": 100
}
```

---

### Accessing the API

Once deployed, send inference requests to the model via the exposed port:

```bash
curl http://<PUBLIC_IP>:11434/api/generate -d '{
  "model": "gemma",
  "prompt": "What is the capital of France?",
  "stream": false
}'
```

### Example Public Inference Calls

```bash
curl -L POST https://cpu-inference-mismistral.130-162-199-33.nip.io/api/generate \
  -d '{ "model": "mistral", "prompt": "What is the capital of Germany?" }' \
  | jq -r 'select(.response) | .response' | paste -sd " "

curl -L -k POST https://cpu-inference-mistral-flexe4.130-162-199-33.nip.io/api/generate \
  -d '{ "model": "mistral", "prompt": "What is the capital of Germany?" }' \
  | jq -r 'select(.response) | .response' | paste -sd " "
```

---

### Pulling from Ollama and Saving to Object Storage

To download a model from Ollama and store it in Object Storage, use the job-mode recipe below.

#### Recipe Configuration

| Field                               | Description                                |
| ----------------------------------- | ------------------------------------------ |
| recipe_id                           | `cpu_inference` – Same recipe base         |
| recipe_mode                         | `job` – One-time job to save a model       |
| deployment_name                     | Custom name for the saving job             |
| recipe_image_uri                    | OCIR URI of the saver image                |
| recipe_node_shape                   | Compute shape used for the job             |
| output_object_storage               | Where to store pulled models               |
| recipe_container_env                | Environment variables including model name |
| recipe_replica_count                | Set to 1                                   |
| recipe_container_port               | Typically `11434` for Ollama               |
| recipe_node_pool_size               | Set to 1                                   |
| recipe_node_boot_volume_size_in_gbs | Size in GB                                 |
| recipe_container_command_args       | Set output directory and model name        |
| recipe_ephemeral_storage_size       | Temporary storage                          |

#### Sample Recipe (Job Mode)

```json
{
  "recipe_id": "cpu_inference",
  "recipe_mode": "job",
  "deployment_name": "gemma and BME4 saver",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:cpu_inference_saver_v0.2",
  "recipe_node_shape": "BM.Standard.E4.128",
  "output_object_storage": [
    {
      "bucket_name": "ollama-models",
      "mount_location": "/models",
      "volume_size_in_gbs": 20
    }
  ],
  "recipe_container_env": [
    { "key": "MODEL_NAME", "value": "gemma" },
    { "key": "PROMPT", "value": "What is the capital of France?" }
  ],
  "recipe_replica_count": 1,
  "recipe_container_port": "11434",
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_container_command_args": [
    "--output_directory",
    "/models",
    "--model_name",
    "gemma"
  ],
  "recipe_ephemeral_storage_size": 100
}
```

---

## Final Notes

- Ensure all OCI IAM permissions are set to allow Object Storage access.
- Confirm that bucket region and deployment region match.
- Use the job-mode recipe once to save a model, and the service-mode recipe repeatedly to serve it.
