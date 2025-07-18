# GPU Health Check

#### Comprehensive GPU health validation and diagnostics for production readiness

This repository offers a robust, pre-check recipe for thorough GPU health validation prior to deploying production or research workloads. Designed to operate seamlessly across both single-node and multi-node environments, this diagnostic toolset enables you to verify that your GPU infrastructure is primed for high-demand experiments. By systematically assessing key performance metrics—such as thermal behavior, power stability, and overall hardware reliability—you can proactively detect and address issues like thermal throttling, power irregularities, and GPU instability. This early-warning system minimizes the risk of unexpected downtime and performance degradation, ensuring that your system consistently operates at peak efficiency and reliability during critical computational tasks.

## Pre-Filled Samples

| Feature Showcase                                                                                              | Title                     | Description                                                       | Blueprint File                                           |
| ------------------------------------------------------------------------------------------------------------- | ------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------- |
| Validate A10 GPU performance and stability using 16-bit floating point precision for memory-efficient testing | 2 A10 GPUs with dtype 16  | Deploys 2 A10 GPUs with dtype 16 on VM.GPU.A10.2 with 2 GPU(s).   | [healthcheck_fp16_a10.json](healthcheck_fp16_a10.json)   |
| Validate A10 GPU performance and stability using 32-bit floating point precision for comprehensive testing    | 2 A10 GPUs with dtype 32  | Deploys 2 A10 GPUs with dtype 32 on VM.GPU.A10.2 with 2 GPU(s).   | [healthcheck_fp32_a10.json](healthcheck_fp32_a10.json)   |
| Validate H100 GPU cluster performance and stability using 16-bit precision for high-scale workloads           | 8 H100 GPUs with dtype 16 | Deploys 8 H100 GPUs with dtype 16 on BM.GPU.H100.8 with 8 GPU(s). | [healthcheck_fp16_h100.json](healthcheck_fp16_h100.json) |
