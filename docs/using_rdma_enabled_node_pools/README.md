# Using RDMA Enabled Node Pools

Currently, AI Blueprints does not have the ability to provision node pools with RDMA configured. However, it can use node pools which were configured previously. Blueprints support for deploying node pools with RDMA configured is coming soon.

If you already have a cluster with RDMA enabled node pools, jump to [install AI Blueprints onto an existing cluster](./README.md#install-ai-blueprints-onto-existing-cluster).

Additionally, RDMA is currently only supported for H100 shapes, but A100, H200, and B200 shapes are being added in short order.

## Optional - Deploy an HPC Cluster with the OCI-OKE-HPC Quickstart

[The oci-hpc-oke quickstart](https://github.com/oracle-quickstart/oci-hpc-oke) provides a straightforward way to deploy RDMA enabled node pools into an OKE cluster. Follow that quickstart with these helpful tips to deploy an OKE cluster with an RDMA enabled node pool.

If you do not use this method, you will need to bring your own cluster with a node pool with RDMA connectivity to use recipes with RDMA enabled.

Tips to look out for in the oci-hpc-oke stack:

**Tip 1**: The main GitHub readme for that repository provides PAR links to images required for GPU nodes with RDMA connectivity.
  - Right click on the appropriate combination (IE GPU driver 560 & CUDA 12.6) and copy link to get the PAR.
  - Go to the tenancy + region in which you'd like to import the image to be used during the quickstart deployment. Follow [this doc](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/custom-images-import.htm#listing-custom-images) to import the custom image into that tenancy / region.
  - Once the image is done importing, it will be usable during cluster deployment.

**Tip 2**: During deployment of the HPC cluster, here is a description of the fields - Pay special attention to **Workers: Operational** and **Workers: GPU+RDMA**:
  - Create policies: Create the policies needed by the cluster. If this is unchecked, this must be done manually
  - Network: Creates the VCN for the cluster with appropriate security rules
  - Bastion & Operator: Gives ssh access to worker nodes and an internal operator to access kubernetes cluster on the operator node
  - OKE Cluster: The configuration of the OKE cluster nodes operating the control plane and pods for cluster management - should be CPU nodes
  - **Workers: Operational [REQUIRED]**: IMPORTANT - this is a common "pitfall". If enabling an RDMA node pool in the section below, put these in the same availability domain as the **Workers: GPU + RDMA**. You can use CPUs for this, such as the default VM.Standard.E5.Flex, but **the image should be the same as the one you use for the GPU+RDMA**, as these nodes will be used to check RDMA health, so they need the software stack.
  - Workers: CPU [OPTIONAL]: Non-RDMA CPU worker nodes to stand up with cluster (leave off as AI Blueprints can provision these if required)
  - Workers: GPU [OPTIONAL]: Non-RDMA GPU worker nodes to stand up with cluster (leave off as AI Blueprints can provision these if required)
  - **Workers: GPU+RDMA [REQUIRED]**: If you desire RDMA nodes, provision at least 2 of these, which will configure with RDMA connectivity. Put these in the same Availability domain as the **Workers: Operational** and use the same image.

## Install AI Blueprints onto existing cluster

[Stop after step 3 of this document](../../INSTALLING_ONTO_EXISTING_CLUSTER_README.md) to install AI Blueprints onto an existing cluster with RDMA enabled node pools.

For nodes which were recently deployed by the oci-hpc-oke stack, or if you finished installing AI blueprints onto your cluster with an existing RDMA enabled node pool, follow these steps after the the AI Blueprints stack has finished installing:

1. Find the private IP address of the node you'd like to add.
   - Command line with `kubectl` (assumes cluster access is setup):
     - run `kubectl get nodes`
     - run `kubectl describe node <nodename>` on each node until you find the node you want to add which is one of the nodes with RDMA connectivity
     - The private ip appears under the `Name` field of the output of `kubectl get nodes`.
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

## Using RDMA enabled nodes in a recipe

Blueprints supported RDMA shapes:
  - BM.GPU.H100.8

Additional shapes coming soon.

To use RDMA in a blueprint, the following fields must be added to deploy to the nodes configured in the previous step:
  - `"recipe_use_shared_node_pool": true` -> RDMA is only supported in shared pool mode
  - `"multinode_rdma_enabled_in_shared_pool": true` -> Lets blueprints know that this deployment should use RDMA configurations in the backend
  - `"multinode_num_nodes_to_use_from_shared_pool": 2` -> Number of nodes from RDMA enabled pool to use for this deployment

## Example Recipe

[This recipe](./rdma_distributed_inference.json) performs a multi-node distributed inference deployment of Llama-3.1-405b-Instruct to 2 H100 nodes communicating with RDMA and serves it over a public endpoint as an example.

The `recipe_container_env` has been left in so you can see that the nodes are communicating via RDMA in the pod logs, but this can be removed to minimize bloat in the logs.
