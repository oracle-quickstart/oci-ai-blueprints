# Online Inference Blueprint (LLMPerf)

This blueprint benchmarks **online inference performance** of large language models using **LLMPerf**, a standardized benchmarking tool. It is designed to evaluate LLM APIs served via platforms such as OpenAI-compatible interfaces, including self-hosted LLM inference endpoints.

This blueprint helps:
- Simulate real-time request load on a running model server
- Measure end-to-end latency, throughput, and completion performance
- Push results to MLflow for visibility and tracking

---

## Pre-Filled Samples

| Title                                  | Description                                                                 |
|----------------------------------------|-----------------------------------------------------------------------------|
|Online inference on LLaMA 3 using LLMPerf|Benchmark of meta/llama3-8b-instruct via a local OpenAI-compatible endpoint |

These can be accessed directly from the OCI AI Blueprint portal.

---

## Prerequisites

Before running this blueprint:
- You **must have an inference server already running**, compatible with the OpenAI API format.
- Ensure the endpoint and model name match what’s defined in the config.

---

## Supported Scenarios

| Use Case              | Description                                           |
|-----------------------|-------------------------------------------------------|
| Local LLM APIs        | Benchmark your own self-hosted models (e.g., vLLM)    |
| Remote OpenAI API     | Benchmark OpenAI deployments for throughput analysis  |
| Multi-model endpoints | Test latency/throughput across different configurations |

---

### Sample Recipe (Job Mode for Online Benchmarking)

```json
{
  "recipe_id": "online_inference_benchmark",
  "recipe_mode": "job",
  "deployment_name": "Online Inference Benchmark",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:llm-benchmark-0409-v2",
  "recipe_node_shape": "VM.GPU.A10.2",
  "input_object_storage": [
    {
      "par": "https://objectstorage.ap-melbourne-1.oraclecloud.com/p/Z2q73uuLCAxCbGXJ99CIeTxnCTNipsE-1xHE9HYfCz0RBYPTcCbqi9KHViUEH-Wq/n/iduyx1qnmway/b/mymodels/o/",
      "mount_location": "/models",
      "volume_size_in_gbs": 100,
      "include": [
        "example_online.yaml"
      ]
    }
  ],
  "recipe_container_command_args": [
    "/models/example_online.yaml"
  ],
  "recipe_replica_count": 1,
  "recipe_container_port": "8000",
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_ephemeral_storage_size": 100
}
```

---

## Sample Config File (`example_online.yaml`)

```yaml
benchmark_type: online

model: meta/llama3-8b-instruct
input_len: 64
output_len: 32
max_requests: 5
timeout: 300
num_concurrent: 1
results_dir: /workspace/results_on
llm_api: openai
llm_api_key: dummy-key
llm_api_base: http://localhost:8001/v1

experiment_name: local-bench
run_name: llama3-test
mlflow_uri: http://mlflow-benchmarking.corrino-oci.com:5000
llmperf_path: /opt/llmperf-src
metadata: test=localhost
```

---

## Metrics Logged

- `output_tokens_per_second`
- `requests_per_minute`
- `overall_output_throughput`
- All raw metrics from the `_summary.json` output of LLMPerf

---
