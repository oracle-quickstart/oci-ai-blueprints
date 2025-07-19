# Online Inference Blueprint (LLMPerf)

#### Benchmark online inference performance of large language models using LLMPerf standardized benchmarking tool.

This blueprint benchmarks **online inference performance** of large language models using **LLMPerf**, a standardized benchmarking tool. It is designed to evaluate LLM APIs served via platforms such as OpenAI-compatible interfaces, including self-hosted LLM inference endpoints.

This blueprint helps:

- Simulate real-time request load on a running model server
- Measure end-to-end latency, throughput, and completion performance
- Push results to MLflow for visibility and tracking

---

## Pre-Filled Samples

| Feature Showcase                                                                                    | Title                                     | Description                                                                 | Blueprint File                                   |
| --------------------------------------------------------------------------------------------------- | ----------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------ |
| Benchmark live LLM API endpoints using LLMPerf to measure real-time performance and latency metrics | Online inference on LLaMA 3 using LLMPerf | Benchmark of meta/llama3-8b-instruct via a local OpenAI-compatible endpoint | [online_deployment.json](online_deployment.json) |

These can be accessed directly from the OCI AI Blueprint portal.

---

## Prerequisites

Before running this blueprint:

- You **must have an inference server already running**, compatible with the OpenAI API format.
- Ensure the endpoint and model name match what’s defined in the config.

---

## Supported Scenarios

| Use Case              | Description                                             |
| --------------------- | ------------------------------------------------------- |
| Local LLM APIs        | Benchmark your own self-hosted models (e.g., vLLM)      |
| Remote OpenAI API     | Benchmark OpenAI deployments for throughput analysis    |
| Multi-model endpoints | Test latency/throughput across different configurations |

---

## Sample Blueprints

[Sample Blueprint (Job Mode for Online Benchmarking)](online_inference_job.json)
[Sample Config File ](example_online.yaml)

---

## Metrics Logged

- `output_tokens_per_second`
- `requests_per_minute`
- `overall_output_throughput`
- All raw metrics from the `_summary.json` output of LLMPerf

---
