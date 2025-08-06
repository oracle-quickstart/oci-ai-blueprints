# Shared Node Pools

#### Create persistent node pools for efficient blueprint deployment without infrastructure recycling

Shared node pools enable you to launch infrastructure independent of individual blueprints, allowing multiple blueprints to deploy and undeploy on the same underlying infrastructure without the overhead of spinning up new node pools for each deployment. This approach eliminates the time-consuming process of infrastructure provisioning and teardown, particularly beneficial for bare metal shapes that require longer recycle times.

When you deploy a standard blueprint, OCI AI Blueprints creates a separate node pool for each blueprint and destroys it upon undeployment. Shared node pools solve this inefficiency by providing persistent infrastructure that can host multiple blueprints simultaneously or sequentially. This is especially valuable when you want to deploy multiple blueprints on the same hardware (e.g., two blueprints each using 2 GPUs on a 4-GPU shape) or need rapid deployment cycles.

The system supports both selector-based and non-selector deployment strategies. With selectors, you can use naming conventions to ensure specific blueprints land on designated shared node pools, providing precise control over resource allocation. Without selectors, blueprints will deploy to any available shared node pool matching the required shape.

Shared node pools are compatible with any blueprint and support all OCI compute shapes, with special considerations for bare metal configurations that require boot volume size specifications.

**Note**: The list of shapes below are supported by Blueprints, but not yet supported by OKE, requiring blueprints to treat them as self-managed nodes. These require:
1. Specifying the Availability Domain of the instance type
2. Specifying the custom image OCID to use for the node

**Note**: Clicking the Link in the table below will download a large image file to your computer (~20GB). It is best to copy the link and paste it in your conole to import the image as described in [This document section](../../other/using_rdma_enabled_node_pools/README.md).

| Shape Name      | Image PAR |
| :--------:      | :-------: |
| BM.GPU.B200.8   | [Link](https://objectstorage.ca-montreal-1.oraclecloud.com/p/ts6fjAuj7hY4io5x_jfX3fyC70HRCG8-9gOFqAjuF0KE0s-6tgDZkbRRZIbMZmoN/n/hpc_limited_availability/b/images/o/Canonical-Ubuntu-22.04-2025.05.20-0-OFED-24.10-1.1.4.0-GPU-570-OPEN-CUDA-12.8-2025.06.07-0) |
| BM.GPU.MI300X.8 | [Link](https://objectstorage.ca-montreal-1.oraclecloud.com/p/ts6fjAuj7hY4io5x_jfX3fyC70HRCG8-9gOFqAjuF0KE0s-6tgDZkbRRZIbMZmoN/n/hpc_limited_availability/b/images/o/Canonical-Ubuntu-22.04-2024.10.04-0-OCA-OFED-24.10-1.1.4.0-AMD-ROCM-632-2025.03.26-0) |


Additional required fields:

```json
"recipe_availability_domain": "<Availability Domain>",
"recipe_node_image_ocid": "<ocid>"
```

See [this recipe](./shared_node_pool_B200_BM.json) as an example for these parameters.

[This document section](../../other/using_rdma_enabled_node_pools/README.md) describes now to import a custom image and provides links to import custom images for various shapes.

## Pre-Filled Samples

| Feature Showcase                                                                                  | Title                           | Description                                                                                                                                                             | Blueprint File                                                                                       |
| ------------------------------------------------------------------------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Create persistent bare metal A10 node pool for high-performance workloads with dedicated hardware | Shared Node Pool for BM.GPU.A10 | Creates a shared node pool using BM.GPU.A10.4 bare metal instances, providing persistent GPU infrastructure for multiple blueprints without recycle overhead.           | [shared_node_pool_A10_BM.json](shared_node_pool_A10_BM.json)                                         |
| Create cost-effective VM-based A10 node pool for flexible blueprint deployment                    | Shared Node Pool for VM.GPU.A10 | Creates a shared node pool using VM.GPU.A10.2 virtual machine instances, offering flexible and cost-effective GPU infrastructure for development and testing workloads. | [shared_node_pool_A10_VM.json](shared_node_pool_A10_VM.json)                                         |
| Deploy vLLM inference service on existing shared node pool infrastructure for rapid deployment    | vLLM Inference on Shared Pool   | Demonstrates deploying a vLLM inference service on a pre-existing shared node pool, showcasing rapid deployment without infrastructure provisioning delays.             | [vllm_inference_sample_shared_pool_blueprint.json](vllm_inference_sample_shared_pool_blueprint.json) |

---

# In-Depth Feature Overview

## What are they

When you deploy a blueprint via OCI AI Blueprints, the underlying infrastructure is spun up (separate node pool for each blueprint within the OCI AI Blueprints cluster) and the application layer is deployed on top of that infrastructure. Once you are done with blueprint and undeploy it, the application layer and the infrastructure gets spun down (the node pool is deleted). This creates an issue when you want to quickly deploy and undeploy blueprints onto infrastructure that requires a long recycle time (such as bare metal shapes) or you want to deploy multiple blueprints onto the same underlying infrastructure (ex: blueprint A uses 2 GPUs and blueprint B uses 2 GPUs on a shape with 4 GPUs).

In come shared node pools, where you can launch infrastructure independent of a blueprint. You can launch a shared node pool, and deploy/undeploy blueprints onto the same node pool (underlying infrastructure) - removing the need to spin up new infrastructure for every blueprint that is deployed.

## How to use them

You can create a shared node pool with a selector or without a selector. A selector is a naming convention that you can use to ensure specific blueprints land on specific shared node pools.

### With selector

1. Create a shared node pool with a selector (this would be the payload to the `/deployment` POST API):

```
{
	"deployment_name": "BM.GPU4.8 shared pool",
	"recipe_mode": "shared_node_pool",
	"shared_node_pool_size": 1,
	"shared_node_pool_shape": "BM.GPU4.8",
	"shared_node_pool_boot_volume_size_in_gbs": 500,
	"shared_node_pool_selector": "selector_1"
}
```

2. Wait for the shared node pool to be deployed (can check `deployment_logs` for status)
3. Deploy any blueprint that you want to be deployed on the BM.GPU4.8 "selector_1" shared node pool (this would be the payload to the `/deployment` POST API):

```
{
	"recipe_id": "example",
	"recipe_mode": "service",
	"deployment_name": "echo1 selector_1",
	"recipe_use_shared_node_pool": true,
	"recipe_shared_node_pool_selector": "selector_1",
	"recipe_image_uri": "hashicorp/http-echo",
	"recipe_container_command_args": [
	"-text=oci-ai-blueprints"
	],
	"recipe_container_port": "5678",
	"recipe_node_shape": "BM.GPU4.8",
	"recipe_replica_count": 2
}
```

Note that the parameters:

- `recipe_use_shared_node_pool` ensures that we are using a shared node pool for this blueprint (and not launching new infrastructure
- `recipe_shared_node_pool_selector` ensures that we are deploying this blueprint onto the BM.GPU4.8 shared node pool we deployed in Step 1
- `recipe_node_shape` needs to match the shape of the shared node pool we launched in step 1 (regardless of including the selector or not)

\*\* If no shared node pool of shape BM.GPU4.8 with selector `selector_1` exisited, the blueprint would wait to be deployed until that shared node pool was created

### Without Selector

1. Create a shared node pool without a selector (this would be the payload to the `/deployment` POST API):

```
{
	"deployment_name": "BM.GPU4.8 shared pool2",
	"recipe_mode": "shared_node_pool",
	"shared_node_pool_size": 1,
	"shared_node_pool_shape": "BM.GPU4.8",
	"shared_node_pool_boot_volume_size_in_gbs": 500,
}
```

2. Wait for the shared node pool to be deployed (can check `deployment_logs` for status)
3. Deploy any blueprint that you want to be deployed on the BM.GPU4.8 "selector_1" shared node pool (this would be the payload to the `/deployment` POST API):

```
{
	"recipe_id": "example",
	"recipe_mode": "service",
	"deployment_name": "echo2 selector_1",
	"recipe_use_shared_node_pool": true,
	"recipe_image_uri": "hashicorp/http-echo",
	"recipe_container_command_args": [
	"-text=oci-ai-blueprints"
	],
	"recipe_container_port": "5678",
	"recipe_node_shape": "BM.GPU4.8",
	"recipe_replica_count": 2
}
```

Note that the parameters:

- `recipe_use_shared_node_pool` ensures that we are using a shared node pool for this blueprint (and not launching new infrastructure
- `recipe_node_shape` needs to match the shape of the shared node pool we launched in step 1 (regardless of including the selector or not)

**This blueprint will be deployed onto any BM.GPU4.8 shared node pool since no selector was included in the blueprint**
**For example, if you had two BM.GPU4.8 shared node pools, then it will randomly select one for deployment**

## Considerations

- If you do not have a shared node pool deployed but try to deploy a blueprint using the `recipe_use_shared_node_pool`, OCI AI Blueprints will wait to deploy the blueprint until it has the shared node pool to launch the blueprint onto
- Bare metal shape shared node pools require the `shared_node_pool_boot_volume_size_in_gbs` parameter
- Any blueprint is compatible with shared node pools

## Sample Blueprints

[shared_node_pool_A10_BM](shared_node_pool_A10_BM.json)
