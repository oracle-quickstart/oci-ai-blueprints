# Multi-Instance GPU (MIG)

#### Partition GPUs into multiple isolated instances for efficient resource sharing and concurrent workloads

Multi-Instance GPU (MIG) is a feature of NVIDIA GPUs that allows a single physical GPU to be partitioned into multiple isolated instances, each acting as an independent GPU with dedicated compute, memory, and cache resources. This enables multiple users or workloads to run concurrently on a single GPU without interfering with each other and without virtualization overhead.

MIG is particularly useful when running multiple smaller models that do not require an entire GPU, such as hosting multiple smaller LLMs (Llama-7B, Mistral-7B, or Gemma-2B) on an A100 or H100 GPU. It ensures resource allocation is optimized, preventing one model from monopolizing the entire GPU while maintaining high throughput. This approach is incredibly well-suited for autoscaling scenarios because many more pods can be scheduled onto a single node depending on the MIG configuration.

Currently, OCI AI Blueprints supports MIG for H100, H200, and B200s with various slice configurations ranging from 7 mini GPUs to full instances. The system supports creating MIG-enabled shared node pools, deploying inference workloads to specific MIG slices, and updating MIG configurations on existing nodes.

To see supported configurations and resource requests, go to [Mig Configurations](./README.md#mig-configurations).

## Pre-Filled Samples

| Feature Showcase                                                                              | Title                                                | Description                                                                                                                                                          | Blueprint File                                                                                     |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Create H100 shared node pool with MIG configuration for efficient GPU resource partitioning   | MIG-Enabled H100 Shared Node Pool                    | Deploys a shared node pool with H100 GPUs configured for Multi-Instance GPU (MIG) partitioning, enabling multiple isolated workloads per physical GPU.               | [mig_enabled_shared_node_pool.json](mig_enabled_shared_node_pool.json)                             |
| Deploy multiple inference replicas on MIG slices for high-throughput serving with autoscaling | MIG Inference with Multiple Replicas and Autoscaling | Deploys multiple inference replicas on MIG GPU slices with autoscaling capabilities, optimizing resource utilization across partitioned H100 GPUs.                   | [mig_inference_multiple_replicas.json](mig_inference_multiple_replicas.json)                       |
| Deploy single inference instance on 20GB MIG slice for dedicated model serving                | MIG Inference Single Replica (20GB Slice)            | Deploys a single inference instance on a 20GB MIG slice, providing dedicated GPU resources for model serving with pod autoscaling support.                           | [mig_inference_single_replica.json](mig_inference_single_replica.json)                             |
| Deploy single inference instance on 10GB MIG slice for memory-efficient model serving         | MIG Inference Single Replica (10GB Slice)            | Deploys a single inference instance on a 10GB MIG slice, optimized for smaller models requiring less GPU memory while maintaining performance.                       | [mig_inference_single_replica_10gb.json](mig_inference_single_replica_10gb.json)                   |
| Update MIG configuration on specific node by private IP for targeted resource management      | Update MIG Configuration by Node Name                | Updates the MIG configuration on a specific node identified by its private IP address, allowing targeted resource reconfiguration without affecting the entire pool. | [mig_update_node_with_node_name.json](mig_update_node_with_node_name.json)                         |
| Update MIG configuration across entire node pool for cluster-wide resource optimization       | Update MIG Configuration by Node Pool Name           | Updates the MIG configuration across an entire node pool, enabling cluster-wide resource reconfiguration for optimized GPU partitioning.                             | [mig_update_shared_pool_with_node_pool_name.json](mig_update_shared_pool_with_node_pool_name.json) |

---

# In-Depth Feature Overview

[Jump to Quickstart](#quickstart)

## What is it?

Multi-Instance GPU (MIG) is a feature of NVIDIA GPUs that allows a single physical GPU to be partitioned into multiple isolated instances, each acting as an independent GPU with dedicated compute, memory, and cache resources. This enables multiple users or workloads to run concurrently on a single GPU without interfering with each other without virtualization overhead - so no performance penalty.

## When to use it?

Use MIG when you need to efficiently share GPU resources among multiple inference workloads or users. MIG is particularly useful when running multiple smaller models that do not require an entire GPU. For example, if you're hosting multiple smaller LLMs (such as Llama-7B, Mistral-7B, or Gemma-2B) on an H100 GPU, MIG ensures resource allocation is optimized, preventing one model from monopolizing the entire GPU while still maintaining high throughput. In this scenario, it is incredibly well-suited for [autoscaling](../auto_scaling/README.md), because many more pods can be scheduled onto a single node depending on the MIG configuration.

As a more concrete example, we will use the scenario of inference serving with Llama-3.1-8B-Instruct. Llama-3.1-8B-Instruct takes roughly `8B * 2 = 16GB` of GPU memory. This would only use about 1/5 of the memory in an H100.

Without MIG, a full H100 GPU would be needed to serve this model as the GPU cannot execute separate processes simultaneously on a single GPU, wasting ~64GB of the GPU memory that we can use to serve other models, or other replicas at the cost of some latency and throughput. With MIG, we can use the configuration **all-1g.20gb** described below in [Mig Configurations](#mig-configurations) to serve 4 of these models on a single H100 GPU.

For small models like this, we would see a moderate drop in performance of a single slice (10-20%), but a huge gain in aggregate performance (~300%) across the 4 instances, which could all be served as a single blueprint.

## When not to use it?

MIG is not designed for multi-GPU workloads, so if your model or application requires more than 1 GPU, MIG is not appropriate. Additionally for models that do fit on less than a single GPU, MIG comes with trade-offs that may not be suitable for all organizations. When you split a GPU into MIG partitions, you are reducing the compute and memory per partition. Because of this, models served with MIG may see increased latency and decreased throughput at the per model / per serving level. While throughput may increase across many replicas of the served model, latency will not as it is more sensitive to the compute resources serving the model. Because of this, if your application is highly latency sensitive, MIG may not be the best option.

## Support and Configurations

Currently, AI/ML Toolkit only supports MIG for **H100, H200, and B200 GPUs**, or the OCI shapes **BM.GPU.H100.8, BM.GPU.H200.8, BM.GPU.B200.8**. When a MIG configuration (explained below) is applied, it is applied to all GPUs on the node, e.g a single BM.GPU.H100.8 has 8 H100 GPUs and applying a MIG configuration would apply it to all 8 GPUs.

Additionally, using multiple "slices" for a single workload is not supported, so MIG is best when the entire task can be incorporated into a single slice. As an example of what this is referring to, when serving LLM inference in a standard (non-MIG) blueprint, it is possible to use multiple GPUs with tensor-parallelism to distribute a model over those GPUs.

This is not supported with MIG because this is not supported by NVIDIA NCCL. Instead, it is recommended to use a larger slice or full GPUs if more performance or tensor-parallelism is needed.

### Mig Configurations

The following tables provide MIG configurations supported by AI/ML Toolkit (click to see dropdown):

<details>
<summary><strong>BM.GPU.H100.8</strong></summary>

| Configuration | Total Slices Per GPU | Total Memory Per Slice | Total Compute Fraction | Pods Schedulable |                     Description                      |
| :-----------: | :------------------: | :--------------------: | :--------------------: | :--------------: | :--------------------------------------------------: |
|  all-1g.10gb  |          7           |          10GB          |          1/7           |        7         |    7 mini GPUs with 10GB each with 14% of compute    |
|  all-1g.20gb  |          4           |          20GB          |          1/4           |        4         |    4 mini GPUs with 20GB each with 25% of compute    |
|  all-2g.20gb  |          3           |          20GB          |          2/7           |        3         |    3 mini GPUs with 20GB each with 29% of compute    |
|  all-3g.40gb  |          2           |          40GB          |          3/7           |        2         |    2 mini GPUs with 40GB each with 43% of compute    |
|  all-4g.40gb  |          1           |          40GB          |          4/7           |        1         |       1 mini GPU with 40GB with 57% of compute       |
|  all-7g.80gb  |          1           |          80GB          |          7/7           |        1         |                    Full H100 GPU                     |
| all-balanced  |          4           | 2x10GB, 1x20GB, 1x40GB |          7/7           |        4         | 2 of the profile 1g.10gb, 1 2g.20gb, 1 3g.40gb above |
| all-disabled  |          -           |           -            |           -            |        -         |            Turn MIG off and use full H100            |

</details>

<details>
<summary><strong>BM.GPU.H200.8</strong></summary>

| Configuration | Total Slices Per GPU | Total Memory Per Slice | Total Compute Fraction | Pods Schedulable |                     Description                      |
| :-----------: | :------------------: | :--------------------: | :--------------------: | :--------------: | :--------------------------------------------------: |
|  all-1g.18gb  |          7           |          18GB          |          1/7           |        7         |    7 mini GPUs with 18GB each with 14% of compute    |
|  all-1g.35gb  |          4           |          35GB          |          1/4           |        4         |    4 mini GPUs with 35GB each with 25% of compute    |
|  all-2g.35gb  |          3           |          35GB          |          2/7           |        3         |    3 mini GPUs with 35GB each with 29% of compute    |
|  all-3g.71gb  |          2           |          71GB          |          3/7           |        2         |    2 mini GPUs with 71GB each with 43% of compute    |
|  all-4g.71gb  |          1           |          71GB          |          4/7           |        1         |       1 mini GPU with 71GB with 57% of compute       |
| all-7g.141gb  |          1           |         141GB          |          7/7           |        1         |                    Full H200 GPU                     |
| all-balanced  |          4           | 2x18GB, 1x35GB, 1x71GB |          7/7           |        4         | 2 of the profile 1g.18gb, 1 2g.35gb, 1 3g.71gb above |
| all-disabled  |          -           |           -            |           -            |        -         |            Turn MIG off and use full H200            |

</details>

<details>
<summary><strong>BM.GPU.B200.8</strong></summary>

| Configuration | Total Slices Per GPU | Total Memory Per Slice | Total Compute Fraction | Pods Schedulable |                     Description                      |
| :-----------: | :------------------: | :--------------------: | :--------------------: | :--------------: | :--------------------------------------------------: |
|  all-1g.23gb  |          7           |          23GB          |          1/7           |        7         |    7 mini GPUs with 23GB each with 14% of compute    |
|  all-1g.45gb  |          4           |          45GB          |          1/4           |        4         |    4 mini GPUs with 45GB each with 25% of compute    |
|  all-2g.45gb  |          3           |          45GB          |          2/7           |        3         |    3 mini GPUs with 45GB each with 29% of compute    |
|  all-3g.90gb  |          2           |          90GB          |          3/7           |        2         |    2 mini GPUs with 90GB each with 43% of compute    |
|  all-4g.90gb  |          1           |          90GB          |          4/7           |        1         |       1 mini GPU with 90GB with 57% of compute       |
| all-7g.180gb  |          1           |         180GB          |          7/7           |        1         |                    Full B200 GPU                     |
| all-balanced  |          4           | 2x23GB, 1x45GB, 1x90GB |          7/7           |        4         | 2 of the profile 1g.23gb, 1 2g.45gb, 1 3g.90gb above |
| all-disabled  |          -           |           -            |           -            |        -         |            Turn MIG off and use full B200            |

</details>

For a visual representation of slicing, refer to this example for H100s (black represents unusable GPU in that configuration):

![mig slicing](./mig_slices.png)

### How to choose MIG configuration for a given model?

1. Find the number of parameters in your model (usually in the name of the model such as Llama-3.2-3B-Instruct would have 3 billion parameters)
2. Determine the precision of the model (FP32 vs FP16 vs FP8) - you can find this in the config.json of the model if on hugging face (look for the torch_dtype); a good assumption is that the model was trained on FP32 and is served on FP16 so FP16 is what you would use for your model precision
3. Use formula here: https://ksingh7.medium.com/calculate-how-much-gpu-memory-you-need-to-serve-any-llm-67301a844f21 or https://www.substratus.ai/blog/calculating-gpu-memory-for-llm to determine the amount of GPU memory needed, so in this case `((3GB * 4) / (32 / 16)) * 1.2 ~= 7.2GB`
4. Determine which MIG configuration above meets your needs. In this case, `all-1g.10gb` is appropriate because it has 10GB of memory per slice.
5. With `all-1g.10gb`, you could serve `7 Slices per GPU * 8 GPUs = 56` instances of this model on a single `BM.GPU.H100.8`. Optionally using `all-balanced`, you could serve `2 Slices per GPU * 8 GPUs = 16` instances of this model, and have 8 instances of a 20GB GPU, and 8 instances of a 40GB GPU for other workloads.

## Required Blueprint Parameters

There are two ways to apply a mig configuration to a node pool.

1. During shared_node_pool deployment
2. As an update to an existing shared node pool

### Mig Blueprint Configuration

#### shared_node_pool:

Apart from the existing requirements for a shared node pool found [here](../../platform_features/shared_node_pools/README.md), the following are additional requirements / options for MIG:

- `"shared_node_pool_mig_config"` - the mig congfiguration to apply to each node in the node pool. Possible values are in the [Mig Configurations](#mig-configurations). This will apply the node to each node in the pool, but if you want to update a specific node that can be done via the `update` mode described in the next section.
- `"recipe_max_pods_per_node"`: [OPTIONAL: DEFAULT = 90] - by default, since MIG can slice up to 56 times for a full BM.GPU.H100.8, the default 31 pods by OKE is insufficient. As part of shared_node_pool deployment for MIG, this value is increased to 90 to fit all slice configurations + some buffer room. The maximum value is proportedly 110. It is not recommended to change this value, as it can not be modified after deployment of a pool. In order to change it, a node must be removed from the pool and re-added with the new value.

A sample blueprint for the mig enabled shared pool can be found [in sample blueprints](mig_enabled_shared_node_pool.json).

#### update mig configuration:

Alternatively, you can update the MIG configuration of an existing node pool as a separate deployment. This is useful if you want to update the MIG configuration of a specific node, or if you want to change the MIG configuration of a pool. Updates to mig configuration typically take 1-2 minutes but can take up to 5 if applying MIG to a previously unmigged node.

Importantly, when applying the MIG configuration update, nothing should be running on the node being updated. This is because MIG is making changes at the hardware level which will affect running applications. Alternatively, the MIG configuration may fail if the node is currently running a workload.

In future iterations, we will add support to temporarily pause work and reschedule work onto the node, but that is not yet supported.

- `"recipe_mode"`: `"update"` - this specifies that you want to update the MIG configuration of an existing node pool.
- `"deployment_name"` - Any name you want to assign the update deployment. This is a new name that you can use to reference the update deployment.
- `"shared_node_pool_mig_config"` - the mig configuration to apply to each node in the node pool. Possible values are in the [Mig Configurations](#mig-configurations). With the update entrypoint, this can be applied to a specific node, or the whole node pool.
- `"recipe_node_name"` - One of `"recipe_node_name"` or `"recipe_node_pool_name"` must be provided - this is the private IP address of the node. This will only apply the passed mig configuration to the specified node, rather than the whole pool. This option currently only supports a single node at a time.
- `"recipe_node_pool_name"` - One of `"recipe_node_name"` or `"recipe_node_pool_name"` must be provided - this is the name of the node pool. This will apply the passed mig configuration to the whole pool, rather than a specific node.

A sample blueprint to update using **node name**: [mig_update_shared_pool_with_node_name.json](mig_update_node_with_node_name.json).

A sample blueprint to update using **node pool name**: [mig_update_shared_pool_with_node_pool_name.json](mig_inference_single_replica.json).

### Use MIG Resource in Blueprint

#### Resource requests:

There is one way to request MIG resources during deployment of a blueprint. It is only valid to request a MIG resource if the node has been pre-configured with that MIG configuration prior to blueprint deployment. If a blueprint requests a MIG resource that has not been configured on any node, the blueprint will fail validation. The parameter:

- `"mig_resource_request"` - the type of MIG resource the blueprint should run on.

The list of available MIG resource requests:

<details>
<summary><strong>BM.GPU.H100.8</strong></summary>

| Resource |                                Description                                |
| :------: | :-----------------------------------------------------------------------: |
| 1g.10gb  |          Request a 10GB slice (from all-1g.10gb or all-balanced)          |
| 1g.20gb  |               Request a 20GB slice (from all-1g.20gb only)                |
| 2g.20gb  | Request a 20GB slice with more compute (from all-2g.20gb or all-balanced) |
| 3g.40gb  |          Request a 40GB slice (from all-3g.40gb or all-balanced)          |
| 4g.40gb  |      Request a 40GB slice with more compute (from all-4g.40gb only)       |
| 7g.80gb  |          Request 80GB with full compute (from all-7g.80gb only)           |

**Note**: 7g.80gb is a MIG configuration - that means that if this configuration is in place, you must request this configuration to use the GPU. It is recommended to disable MIG with `all-disabled` if you intend to use the full compute.

</details>

<details>
<summary><strong>BM.GPU.H200.8</strong></summary>

| Resource |                                Description                                |
| :------: | :-----------------------------------------------------------------------: |
| 1g.18gb  |          Request a 18GB slice (from all-1g.18gb or all-balanced)          |
| 1g.35gb  |               Request a 35GB slice (from all-1g.35gb only)                |
| 2g.35gb  | Request a 35GB slice with more compute (from all-2g.35gb or all-balanced) |
| 3g.71gb  |          Request a 71GB slice (from all-3g.71gb or all-balanced)          |
| 4g.71gb  |      Request a 71GB slice with more compute (from all-4g.71gb only)       |
| 7g.141gb |          Request 141GB with full compute (from all-7g.141gb only)         |

**Note**: 7g.141gb is a MIG configuration - that means that if this configuration is in place, you must request this configuration to use the GPU. It is recommended to disable MIG with `all-disabled` if you intend to use the full compute.

</details>

<details>
<summary><strong>BM.GPU.B200.8</strong></summary>

| Resource |                                Description                                |
| :------: | :-----------------------------------------------------------------------: |
| 1g.23gb  |          Request a 23GB slice (from all-1g.23gb or all-balanced)          |
| 1g.45gb  |               Request a 45GB slice (from all-1g.45gb only)                |
| 2g.45gb  | Request a 45GB slice with more compute (from all-2g.45gb or all-balanced) |
| 3g.90gb  |          Request a 90GB slice (from all-3g.90gb or all-balanced)          |
| 4g.90gb  |      Request a 90GB slice with more compute (from all-4g.90gb only)       |
| 7g.180gb |          Request 180GB with full compute (from all-7g.180gb only)         |

**Note**: 7g.180gb is a MIG configuration - that means that if this configuration is in place, you must request this configuration to use the GPU. It is recommended to disable MIG with `all-disabled` if you intend to use the full compute.

</details>

If you would like to run the same blueprint across many slices (which may be the case with LLM inference), increase the number of replicas in `recipe_replica_count`.

A sample blueprint with multiple replicas can be found here: [mig_inference_multiple_replicas.json](mig_inference_single_replica.json).

A sample blueprint with a single replica can be found here: [mig_inference_single_replica.json](mig_inference_single_replica_10gb.json).

## Quickstart

The following is a quickstart with the example flow of using MIG for blueprint deployment.

1. Approximate your model's resource requirements using the framework in the [How to choose MIG](#how-to-choose-mig-configuration-for-a-given-model) section.
2. Launch your H100 shared pool with the correct [MIG config](#mig-configurations) based on (1).
3. Launch your blueprint onto that MIG configuration with [Use MIG in a blueprint](#use-mig-resource-in-blueprint).
4. Evaluate usage. If more memory is needed, select a larger slice from the MIG configurations. If less memory / performance is needed and you can run more workloads, select a smaller slice, and [update MIG configuration](#update-mig-configuration).
5. Rerun your workflow and re-evaluate.
6. Repeat steps 3-5 until optimal setup is determined.

Executing the blueprints below would be an exact representation of the above.

1. Launch shared pool: [shared_mig_pool.json](mig_enabled_shared_node_pool.json)
2. Launch MIG inference when pool is active: [mig_inference.json](mig_inference_single_replica_10gb.json)
3. Evaluate performance and determine update is needed to reduce memory from 20gb slice to 10gb slice: [update_mig.json](mig_update_node_with_node_name.json)
4. Launch recipe again, this time selecting 1g.10gb resource: [mig_inference.json](mig_inference_single_replica_10gb.json)
