# GPU Health Check & Pre-Check Blueprint

This blueprint provides a **pre-check blueprint** for GPU health validation before running production or research workloads. The focus is on delivering a **diagnostic tool** that can run on both single-node and multi-node environments, ensuring that your infrastructure is ready for demanding experiments.

The workflow includes:
- **Data types** as input (`fp8`, `fp16`, `fp32`, `fp64`)
- **Custom Functions** for GPU diagnostics
- **GPU-Burn** for stress testing
- **Results** collected in JSON files (and optionally PDF reports)

By following this blueprint, you can identify and localize issues such as thermal throttling, power irregularities, or GPU instability before they impact your main workloads.

---

## 1. Architecture Overview

Below is a simplified overview:

<img width="893" alt="image" src="https://github.com/user-attachments/assets/e44f7ffe-19cf-48be-a026-e27fddfbed3c" />


### Key Points

- Data Types: You can specify one of several floating-point precisions (`fp8`, fp16, fp32, `fp64`).
- Custom Functions: Diagnostic functions that measure performance metrics such as throughput, memory bandwidth, etc.
- Single-Node vs. Multi-Node: Tests can be run on a single machine or scaled to multiple machines.
- GPU-Burn: A specialized stress-testing tool for pushing GPUs to their maximum performance limits.
- Results: Output is aggregated into JSON files (and optionally PDFs) for analysis.

---

## 2. Health Check Blueprint

This blueprint aims to give you confidence that your GPUs are healthy. The key checks include:

1. Compute Throughput  
   - Dense matrix multiplications or arithmetic operations stress the GPU cores.  
   - Ensures sustained performance without degradation.

2. Memory Bandwidth  
   - Reading/writing large chunks of data (e.g., `torch.rand()`) tests memory throughput.  
   - Verifies the memory subsystem operates at expected speeds.

3. Temperature & Thermal Stability  
   - Uses commands like nvidia-smi to monitor temperature.  
   - Checks for throttling under load.

4. Power Consumption  
   - Monitors power draw (e.g., `nvidia-smi --query-gpu=power.draw --format=csv`).  
   - Identifies irregular or excessive power usage.

5. GPU Utilization  
   - Ensures GPU cores (including Tensor Cores) are fully engaged during tests.  
   - Confirms no unexpected idle time.

6. Error Detection  
   - Checks for hardware errors or CUDA-related issues.  
   - Asserts numerical correctness to ensure no silent failures.

7. Multi-GPU Testing  
   - Validates multi-GPU or multi-node setups.  
   - Ensures the entire environment is consistent and stable.

8. Mixed Precision Testing  
   - Uses AMP for fp8 or fp16 operations (e.g., `torch.cuda.amp.autocast()`).  
   - Confirms performance and compatibility with mixed-precision ops.

---

## 3. Data Types and How They Work

- fp8, fp16: Lower precision can offer speedups but requires checks for numerical stability.  
- fp32 (single precision): Standard for most deep learning tasks; tests confirm typical GPU operations.  
- fp64 (double precision): Used in HPC/scientific workloads; verifies performance and accuracy at high precision.

Depending on the dtype you select, the script either runs a set of Custom Functions or launches GPU-Burn to push the hardware to its limits. The results are saved in JSON for analysis.

---

## 4. Custom Functions

These Python-based diagnostic functions systematically measure:

- Throughput (matrix multiplies, convolution stubs, etc.)  
- Memory bandwidth (large tensor reads/writes)  
- Temperature (via nvidia-smi or other sensors)  
- Power usage  
- GPU utilization  
- Error detection (assert checks, error logs)  
- Multi-GPU orchestration (parallel usage correctness)  
- Mixed precision compatibility (AMP in PyTorch)

They can run on a single node or multiple nodes, with each run producing structured JSON output.

---

## 5. GPU-Burn

[GPU-Burn](https://github.com/wilicc/gpu-burn) is a stress-testing tool designed to push GPUs to their maximum performance limits. It is typically used to:

- Validate hardware stability  
- Identify potential overheating or faulty components  
- Confirm GPUs can handle extreme workloads without errors or throttling

When you run GPU-Burn in float32 or float64 mode, its output can be captured in a log file, then parsed into JSON or PDF summaries for reporting.

---


## 6. Usage

1. Clone the Blueprint & Install Dependencies  

   
Bash

     git clone <repo_url>
     cd <repo_name>
     docker build -t gpu-healthcheck .
   

2. Run the Pre-Check  
   - Single Node Example (fp16):  
     
Bash


     docker run --gpus all -it -v $(pwd)/results:/app/testing_results gpu-healthcheck --dtype float16 --expected_gpus A10:2,A100:0,H100:0
     
     
   - GPU-Burn Stress Test (float32):  
     
Bash


     docker run --gpus all -it -v $(pwd)/results:/app/testing_results gpu-healthcheck --dtype float32 --expected_gpus A10:2,A100:0,H100:0
     

3. Examine Results  
   - JSON output is located in the results/ directory.  
   - PDF summaries will also be generated.

---
## 7. Implementing it into OCI AI Blueprints

This is an example of json file which be used to deploy into OCI AI Blueprints:

```json
{
  "recipe_id": "healthcheck",
  "recipe_mode": "job",
  "deployment_name": "healthcheck",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:healthcheck_v0.3",
  "recipe_node_shape": "VM.GPU.A10.2",
  "output_object_storage": [
    {
      "bucket_name": "healthcheck2",
      "mount_location": "/healthcheck_results",
      "volume_size_in_gbs": 20
    }
  ],
  "recipe_container_command_args": [
    "--dtype", "float16", "--output_dir", "/healthcheck_results", "--expected_gpus", "A10:2,A100:0,H100:0"
  ],
  "recipe_replica_count": 1,
  "recipe_nvidia_gpu_count": 2,
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_ephemeral_storage_size": 100,
  "recipe_shared_memory_volume_size_limit_in_mb": 1000,
  "recipe_use_shared_node_pool": true
}
```
---

## Explanation of Healthcheck Recipe Fields

| Field                                  | Type        | Example Value                                                                 | Description |
|---------------------------------------|-------------|-------------------------------------------------------------------------------|-------------|
| `recipe_id`                           | string      | `"healthcheck"`                                                              | Identifier for the recipe |
| `recipe_mode`                         | string      | `"job"`                                                                      | Whether the recipe runs as a one-time job or a service |
| `deployment_name`                     | string      | `"healthcheck"`                                                              | Name of the deployment/job |
| `recipe_image_uri`                    | string      | `"iad.ocir.io/.../healthcheck_v0.3"`                                         | URI of the container image stored in OCI Container Registry |
| `recipe_node_shape`                   | string      | `"VM.GPU.A10.2"`                                                              | Compute shape to use for this job |
| `output_object_storage.bucket_name`   | string      | `"healthcheck2"`                                                              | Name of the Object Storage bucket to write results |
| `output_object_storage.mount_location`| string      | `"/healthcheck_results"`                                                     | Directory inside the container where the bucket will be mounted |
| `output_object_storage.volume_size_in_gbs` | integer | `20`                                                                         | Storage volume size (GB) for the mounted bucket |
| `recipe_container_command_args`       | list        | `[--dtype, float16, --output_dir, /healthcheck_results, --expected_gpus, A10:2,A100:0,H100:0]` | Arguments passed to the container |
| `--dtype`                             | string      | `"float16"`                                                                   | Precision type for computations (e.g. float16, float32) |
| `--output_dir`                        | string      | `"/healthcheck_results"`                                                     | Directory for writing output (maps to mounted bucket) |
| `--expected_gpus`                     | string      | `"A10:2,A100:0,H100:0"`                                                       | Expected GPU types and counts |
| `recipe_replica_count`                | integer     | `1`                                                                          | Number of replicas (containers) to run |
| `recipe_nvidia_gpu_count`            | integer     | `2`                                                                          | Number of GPUs to allocate |
| `recipe_node_pool_size`              | integer     | `1`                                                                          | Number of nodes to provision |
| `recipe_node_boot_volume_size_in_gbs`| integer     | `200`                                                                         | Size of the boot volume (GB) |
| `recipe_ephemeral_storage_size`      | integer     | `100`                                                                         | Ephemeral scratch storage size (GB) |
| `recipe_shared_memory_volume_size_limit_in_mb` | integer | `1000`                                                                   | Size of shared memory volume (`/dev/shm`) in MB |
| `recipe_use_shared_node_pool`        | boolean     | `true`                                                                       | Whether to run on a shared node pool |

## 8. Contact

For questions or additional information, open an issue in this blueprint or contact the maintainers directly.
