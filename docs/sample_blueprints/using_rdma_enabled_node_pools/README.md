# Using RDMA Enabled Node Pools

Random Direct Memory Access (RDMA) is a protocol that lets one node read from or write to the memory of another node without involving either machine’s CPU or operating system, enabling true zero-copy data transfers and dramatically reducing latency and CPU overhead. In large-scale AI workloads such as multi-node training with AllReduce or disaggregated LLM inference, RDMA can yield tremendous performance gains by signifantly reducing communication and copy overhead between nodes.

Blueprints uses [OCI cluster networks with instance pools](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/managingclusternetworks.htm) to provision RDMA-enabled node pools. 

Note: follow our supported shapes as these have been validated with blueprints. To request additional shape support, open an issue on GitHub.

RDMA is currently supported for:

 - BM.GPU.H100.8
 - BM.GPU.H200.8
 - BM.GPU.B4.8

Additional shape support is coming soon.

# Provision RDMA-enabled shared nodepools with Blueprints

The following section will describe the steps to provision RDMA-enabled shared nodepools 

If you already have a cluster with RDMA enabled node pools, for example [from this quickstart](https://github.com/oracle-quickstart/oci-hpc-oke) jump to [install AI Blueprints onto an existing cluster](./README.md#install-ai-blueprints-onto-existing-cluster).

If not, proceed below.

## Required policies

The specific policy required for RDMA-enabled shared node pools is:
```
Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to {CLUSTER_JOIN} in compartment {compartment_name}
```

The fine-grained policy list for blueprints can be found [here](../../iam_policies.md).

## Import a custom image

The following [oci-hpc-oke quickstart](https://github.com/oracle-quickstart/oci-hpc-oke?tab=readme-ov-file#images-to-use) provides node images with proper drivers and libraries for RDMA connectivity between nodes for various CUDA driver / toolkit versions. One of these images must be imported into your tenancy in the correct region (and possibly compartment depending on policies) to provision RDMA enabled shared node pools.

  - Right click on the appropriate combination (IE GPU driver 560 & CUDA 12.6) and copy link to get the PAR
  - Login to the tenancy + region in which you'd like to import the image
  - In the console, click the hamburger in the top left -> Compute -> Instances -> Custom Images
  - Go to the Compartment in which you'd like to import the image, then click "Import image"
  - Set the compartment in "Create in compartment", name the image, then ensure the OS is set to "Ubuntu" as these are Ubuntu images
  - Click the circle "Import from an Object Storage URL"
  - Paste the PAR URL retrieved above into the object storage url box
  - For image type, select "OCI"
  - Add any tags you'd like, then click "Import Image" on the bottom
  - Once the image is done importing (30 minutes to an hour), it will be usable during cluster deployment
  - To use the image in recipes, you will need to retrieve the image OCID

[This doc](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/custom-images-import.htm#listing-custom-images) provides complete details for all image importing options.

## Deploying an RDMA-enabled shared node pool

Once the image has been imported, it is now possible to deploy a shared node pool with RDMA connectivity with AI blueprints.

In addition to the parameters described in [the shared node pool doc](../shared_node_pools/README.md#without-selector), the following additional parameters are required:
  - `"recipe_availability_domain": "<FULL AD NAME>"` -> full availability domain name where you have capacity for nodes. Examples: `"TrcQ:AP-MELBOURNE-1-AD-1"`, `"TrcQ:EU-FRANKFURT-1-AD-3"`. These can generally be found in the console via Hamburger (top left) -> Governance & Administration -> Tenancy Management -> Limits, Quotas and Usage

  - `"recipe_node_image_ocid": "<image ocid>"` -> the OCID of the custom image you imported

  - `"multinode_rdma_enabled_in_shared_pool": true` -> boolean telling blueprints to setup RDMA. **Important** - if this is left off, blueprints will provision a shared node pool with the specified shape as a node pool without RDMA connectivity and this cannot be undone except by deleting and recreating the pool.

  - `"shared_node_pool_size": >1` -> This must be some number greater than 1, as RDMA is fundamentally **inter-node** connectivity.

This is an [example blueprint](./rdma_shared_node_pool.json).

Populate the example with the correct shape, AD, and image OCID, and paste it into the `/deployment` API endpoint to deploy a 2 node RDMA-enabled pool which can be used for downstream blueprints.

## Using RDMA-enabled nodes in a blueprint

To use RDMA in a blueprint, the following fields must be added to deploy to the nodes configured in the previous step:
  - `"recipe_use_shared_node_pool": true` -> RDMA is only supported in shared pool mode
  - `"multinode_rdma_enabled_in_shared_pool": true` -> Lets blueprints know that this deployment should use RDMA configurations in the backend
  - `"multinode_num_nodes_to_use_from_shared_pool": 2` -> Number of nodes from RDMA enabled pool to use for this deployment

[This blueprint](./rdma_distributed_inference.json) performs a multi-node distributed inference deployment of Llama-3.1-405b-Instruct to 2 H100 nodes communicating with RDMA and serves it over a public endpoint as an example. 405b with fp16 was selected because the weights are too large to load into a single BM.GPU.H100.8, as it takes around 900GB of GPU vRAM to load the weights.

The `recipe_container_env` has been left in so you can see that the nodes are communicating via RDMA in the pod logs, but this can be removed to minimize bloat in the logs.


## Install AI Blueprints onto existing cluster

[Stop after step 3 of this document](../../../INSTALLING_ONTO_EXISTING_CLUSTER_README.md) to install AI Blueprints onto an existing cluster with RDMA enabled node pools.

For nodes which were recently deployed by the oci-hpc-oke stack, or if you finished installing AI blueprints onto your cluster with an existing RDMA enabled node pool, follow these steps after the the AI Blueprints stack has finished installing:

1. Find the private IP address of the node you'd like to add.
   - Command line with `kubectl` (assumes cluster access is setup):
     - run `kubectl get nodes`
     - run `kubectl describe node <nodename>` on each node until you find the node you want to add which is one of the nodes with RDMA connectivity
     - The private ip appears under the `Name` field of the output of `kubectl get nodes`.
   - Alternatively, find them in the console in "Instances" for your tenancy/region/compartment
2. Go to the stack and click "Application information". Click the API Url.
   - If you get a warning about security, sometimes it takes a bit for the certificates to get signed. This will go away once that process completes on the OKE side.
3. Login with the `Admin Username` and `Admin Password` in the Application information tab.
4. Click the link next to "deployment" which will take you to a page with "Deployment List", and a content box.
5. Paste in the sample blueprint json found [here](./rdma_update_nodes.json), replacing the `recipe_node_name` with the private IP address found above.
6. Click "POST". This takes about 20 seconds to complete.
7. After waiting about 20 seconds, refresh the page which should look like:
```json
[
    {
        "mode": "update",
        "recipe_id": null,
        "creation_date": "2025-03-28 11:12 AM UTC",
        "deployment_uuid": "750a________cc0bfd",
        "deployment_name": "startupaddnode1",
        "deployment_status": "completed",
        "deployment_directive": "commission"
    }
]
```
8. Repeat steps 5-7 for each node you'd like to add, updating `recipe_node_name` and incrementing `deployment_name` fields for each deployment until you've added all RDMA enabled nodes you'd like to add to the cluster.

## Issues

To report an issue with RDMA deployments, please post an issue on the GitHub.
