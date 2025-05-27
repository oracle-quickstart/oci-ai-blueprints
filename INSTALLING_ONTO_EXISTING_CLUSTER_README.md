# Install OCI AI Blueprints onto an Existing OKE Cluster

This guide helps you install and use **OCI AI Blueprints** for the first time on an existing OKE cluster that was created outside of blueprints which already has workflows running on it. You will:

1. Ensure you have the correct IAM policies in place.
2. Retrieve existing cluster OKE and VCN names from console.
3. Deploy the **OCI AI Blueprints** application onto the existing cluster.
4. Learn how to add existing nodes in the cluster to be used by blueprints.
5. Deploy a sample recipe to that node.
6. Test your deployment and undeploy
7. Destroy the stack

There is an additional section at the bottom for users who have the nvidia-gpu-operator installed, and would like to use Multi-Instance GPUs with H100 nodes visit [this section](./INSTALLING_ONTO_EXISTING_CLUSTER_README.md#multi-instance-gpu-setup).

Additionally, visit [this section](./INSTALLING_ONTO_EXISTING_CLUSTER_README.md#need-help) if you need to contact the team about setup issues.

---

## Overview

Rather than installing blueprints onto a new cluster, a user may want to leverage an existing cluster with node pools and tools already installed. This doc will cover the components needed to deploy to an existing cluster, how to add existing node pools to be used by blueprints, and additional considerations which should be considered.

## Step 1: Set Up Policies in Your Tenancy

Some or all of these policies may be in place as required by OKE. Please review the required policies listed [here](docs/iam_policies.md) and add any required policies which are missing.

1. If you are **not** a tenancy administrator, ask your admin to add additional required policies in the **root compartment**.
2. If you **are** a tenancy administrator, you can either manually add the additional policies to an existing dynamic group, or let the resource manager deploy the required policies during stack creation.

## Step 2: Retrieve Existing OKE OCID and VCN OCID

1. Navigate to the console.
2. Go to the region that contains the cluster you wish to deploy blueprints onto.
3. Navigate to **Developer Services -> Containers & Artifacts -> Kubernetes Clusters (OKE) -> YourCluster**
4. Click your cluster, and then capture the name of the cluster and the name of the VCN as they will be used during stack creation.

## Step 3: Deploy the OCI AI Blueprints Application

1. Go to [Deploy the OCI AI Blueprints Application](./GETTING_STARTED_README.md#step-3-deploy-the-oci-ai-blueprints-application) and click the button to deploy.
2. Go to the correct region where your cluster is deployed.
3. If you have not created policies and are an admin, and would like the stack to deploy the policies for you:

   - select "NO" for the question "Have you enabled the required policies in the root tenancy for OCI AI Blueprints?"
   - select "YES" for the question "Are you an administrator for this tenancy?".
   - Under the section "OCI AI Blueprints IAM", click the checkbox to create the policies. (If you do not see this, ensure you've selected the correct choices for the questions above.)

- Otherwise, create the policies if you are an admin, or have your admin create the policies.

4. Select "YES" for all other options.
5. Fill out additional fields for username and password, as well as Home Region.
6. Under "OKE Cluster & VCN", select the cluster name and vcn name you found in step 2.
7. Populate the subnets with the appropriate values. As a note, there is a "hint" under each field which corresponds to possible naming conventions. If your subnets are named differently, navigate back to the console page with the cluster and find them there.
8. **Important ADVANCED**: When installing onto your own cluster, it is likely that you have some tools already installed, such as prometheus, grafana, or the gpu-operator. If this is the case, **click the box** under the section **"ADVANCED: Bringing your own cluster?"**. This will prompt several drop-downs to appear containing all the tools we `helm install`.
   - **Critical**: If you have that tool installed, you must click the box which says, "Bring your own X" where "X" is the tool name.
   - This will prompt you for the `kubernetes namespace` in which the tool was installed. This is because internal tooling uses some of these namespaces.
   - If this tool was installed with helm, you can do:
   ```bash
   helm list --all-namespaces
   ```
   - To get a specific tool's namespace, like prometheus:
   ```bash
   helm list --all-namespaces | grep prometheus
   # outputs
   prometheus    monitoring    1 ...
   ```
9. After you've added all the relevant tooling namespaces, apply the stack by hitting "Next", then click the "run apply" box.

## Step 4: Add Existing Nodes to Cluster (optional)

If you have existing node pools in your original OKE cluster that you'd like Blueprints to be able to use, follow these steps after the stack is finished:

1. Find the private IP address of the node you'd like to add.
   - Console:
     - Go to the OKE cluster in the console like you did above
     - Click on "Node pools"
     - Click on the pool with the node you want to add
     - Identify the private ip address of the node under "Nodes" in the page.
   - Command line with `kubectl` (assumes cluster access is setup):
     - run `kubectl get nodes`
     - run `kubectl describe node <nodename>` on each node until you find the node you want to add
     - The private ip appears under the `Name` field of the output of `kubectl get nodes`.
2. Go to the stack and click "Application information". Click the API Url.
   - If you get a warning about security, sometimes it takes a bit for the certificates to get signed. This will go away once that process completes on the OKE side.
3. Login with the `Admin Username` and `Admin Password` in the Application information tab.
4. Click the link next to "deployment" which will take you to a page with "Deployment List", and a content box.
5. Paste in the sample blueprint json found [here](docs/sample_blueprints/exisiting_cluster_installation/add_node_to_control_plane.json).
6. Modify the "recipe_node_name" field to the private IP address you found in step 1 above.
7. Click "POST". This is a fast operation.
8. Wait about 20 seconds and refresh the page. It should look like:

```json
[
  {
    "mode": "update",
    "recipe_id": null,
    "creation_date": "2025-03-28 11:12 AM UTC",
    "deployment_uuid": "750a________cc0bfd",
    "deployment_name": "startupaddnode",
    "deployment_status": "completed",
    "deployment_directive": "commission"
  }
]
```

## Step 5: Deploy a sample recipe

2. Go to the stack and click "Application information". Click the API Url.
   - If you get a warning about security, sometimes it takes a bit for the certificates to get signed. This will go away once that process completes on the OKE side.
3. Login with the `Admin Username` and `Admin Password` in the Application information tab.
4. Click the link next to "deployment" which will take you to a page with "Deployment List", and a content box.
5. If you added a node from [Step 4](./INSTALLING_ONTO_EXISTING_CLUSTER_README.md#step-4-add-existing-nodes-to-cluster-optional), use the following shared node pool [blueprint](./docs/sample_blueprints/shared_node_pools/vllm_inference_sample_shared_pool_blueprint.json).
   - Depending on the node shape, you will need to change:
     `"recipe_node_shape": "BM.GPU.A10.4"` to match your shape.
6. If you did not add a node, or just want to deploy a fresh node, use the following [blueprint](docs/sample_blueprints/vllm-inference/vllm_inference_sample_blueprint.json).
7. Paste the blueprint you selected into context box on the deployment page and click "POST"
8. To monitor the deployment, go back to "Api Root" and click "deployment_logs".
   - If you are deploying without a shared node pool, it can take 10-30 minutes to bring up a node, depending on shape and whether it is bare-metal or virtual.
   - If you are deploying with a shared node pool, the blueprint will deploy much more quickly.
   - It is common for a recipe to report "unhealthy" while it is deploying. This is caused by "Warnings" in the pod events when deploying to kubernetes. You only need to be alarmed when an "error" is reported.
9. Wait for the following steps to complete:
   - Affinity / selection of node -> Directive / commission -> Command / initializing -> Canonical / name assignment -> Service -> Deployment -> Ingress -> Monitor / nominal.
10. When you see the step "Monitor / nominal", you have an inference server running on your node.

## Step 6: Test your deployment

1. Upon completion of [Step 5](./INSTALLING_ONTO_EXISTING_CLUSTER_README.md#step-5-deploy-a-sample-recipe), test the deployment endpoint.
2. Go to Api Root, then click "deployment_digests". Find the "service_endpoint_domain" on this page.

   - This is <deployment-name>.<base-url>.nip.io for those who let us deploy the endpoint. If you use the default recipes above, an example of this would be:

   `vllm-inference-deployment.158-179-30-233.nip.io`

3. `curl` the metrics endpoint:

```bash
curl -L vllm-inference-deployment.158-179-30-233.nip.io/metrics
# HELP vllm:cache_config_info Information of the LLMEngine CacheConfig
# TYPE vllm:cache_config_info gauge
vllm:cache_config_info{block_size="16",cache_dtype="auto",cpu_offload_gb="0",enable_prefix_caching="False",gpu_memory_utilization="0.9",is_attention_free="False",num_cpu_blocks="4096",num_gpu_blocks="10947",num_gpu_blocks_override="None",sliding_window="None",swap_space_bytes="4294967296"} 1.0
# HELP vllm:num_requests_running Number of requests currently running on GPU.
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running{model_name="/models/NousResearch/Meta-Llama-3.1-8B-Instruct"} 0.0
# HELP vllm:num_requests_swapped Number of requests swapped to CPU.
...
```

4. Send an actual post request:

```bash
curl -L -H "Content-Type: application/json" -d '{"model": "/models/NousResearch/Meta-Llama-3.1-8B-Instruct", "messages": [{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": "Hello, how are you?"}], "temperature": 0.7, "max_tokens": 100 }' vllm-inference-deployment.158-179-30-233.nip.io/v1/chat/completions | jq

# response
{
  "id": "chatcmpl-bb9093a3f51cee3e0ebe67ed06da59f0",
  "object": "chat.completion",
  "created": 1743169357,
  "model": "/models/NousResearch/Meta-Llama-3.1-8B-Instruct",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I'm doing well, thank you for asking! I'm a helpful assistant, so I'm always ready to assist you with any questions or tasks you may have. How about you? How's your day going so far?",
        "tool_calls": []
      },
      "logprobs": null,
      "finish_reason": "stop",
      "stop_reason": null
    }
  ],
  "usage": {
    "prompt_tokens": 27,
    "total_tokens": 73,
    "completion_tokens": 46,
    "prompt_tokens_details": null
  },
  "prompt_logprobs": null
}
```

5. When completed, undeploy the recipe:
   - go to Api Root -> deployment
   - Grab the whole deployment_uuid field for your deployment.
     - "deployment_uuid": "asdfjklafjdskl"
   - go to Api Root -> undeploy
   - paste the field "deployment_uuid" into the content box and wrap it in curly braces {}:
     - {"deployment_uuid": "asdfjklafjdskl"}
   - Click "POST"
6. Monitor the undeploy:
   - go to Api Root -> deployment_logs
   - Look for: Directive decommission -> Ingress deleted -> Deployment deleted -> Service deleted -> Directive / decommission / completed.

## Step 7: Destroy the stack

Destroying the OCI AI Blueprints stack will not destroy any resources which were created or destroyed outside of the stack such as node pools or helm installs. Only things created by the stack will be destroyed for the stack. To destroy the stack:

1. Go to the console and navigate to Developer Services -> Resource Manager -> Stacks -> Your OCI AI Blueprints stack
2. Click "Destroy" at the top

## Multi-Instance GPU Setup

If you have the nvidia gpu operator already installed, and would like to reconfigure it because you plan on using Multi-Instance GPUs (MIG) with your H100 nodes, you will need to manually update / reconfigure your cluster with helm.

This can be done like below:

```bash
# Get the deployment name
helm list -n gpu-operator

NAME                   	NAMESPACE   	REVISION	UPDATED                             	STATUS  	CHART               	APP VERSION
gpu-operator-1742982512	gpu-operator	1       	2025-03-26 05:48:41.913183 -0400 EDT	deployed	gpu-operator-v24.9.2	v24.9.2

# Upgrade the deployment
helm upgrade gpu-operator-1742982512 nvidia/gpu-operator \
   --namespace gpu-operator \
   --set mig.strategy="mixed" \
   --set migManager.enabled=true

Release "gpu-operator-1742982512" has been upgraded. Happy Helming!
NAME: gpu-operator-1742982512
LAST DEPLOYED: Wed Mar 26 05:59:23 2025
NAMESPACE: gpu-operator
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

## Need Help?

- Check out [Known Issues & Solutions](docs/known_issues.md) for troubleshooting common problems.
- For questions or additional support, contact [vishnu.kammari@oracle.com](mailto:vishnu.kammari@oracle.com) or [grant.neuman@oracle.com](mailto:grant.neuman@oracle.com).
