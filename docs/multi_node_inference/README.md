# Multi-Node Inference

[Jump to Quickstart](#Quickstart_Guide:_Multi-Node_Inference)

## What is it?

**Inference:**  
Inference is the process of running data through a trained machine learning model to generate an output—similar to calling a function with some input data and receiving a computed result. For instance, when you feed text (such as a question) into a large language model, the model processes that input and returns a text-based answer.

**Inference Serving:**  
Inference serving is about deploying these trained models as APIs or services. This setup allows for efficient processing of predictions, whether on demand (real-time) or in batches, much like how a web service handles requests and responses.

**Multi-Node Inference:**  
Multi-node inference scales up this process by distributing the workload across several computing nodes, each typically equipped with one or more GPUs. This is particularly useful for handling large models that require substantial computational power. It combines two key parallelization techniques:

- **Tensor Parallelism:** Within a single node, the model’s complex numerical operations (e.g., matrix multiplications) are divided among multiple GPUs. Think of it as breaking a large calculation into smaller pieces that can be processed simultaneously by different GPUs.
- **Pipeline Parallelism:** The inference process is divided into sequential stages, with each node responsible for one stage. This is similar to an assembly line, where each node completes a specific part of the overall task before passing it along.

Together, these methods ensure that multi-node inference efficiently utilizes available hardware resources, reducing processing time and improving throughput for both real-time and batch predictions.

## When to use it?

Use multi-node inference whenever you are trying to use a very large model that will not fit into all available GPU memory on a single node. As an example, Llama-3.3-70B-Instruct requires roughly 150G of GPU memory when serving. If you were serving this on BM.GPU.A10.4, the 4 A10 GPUs have a combined 100G of GPU memory, so the model is too large to fit onto this one node. You must distribute the model weights across the GPUs of each node (tensor parallelism) and the GPUs in other nodes (pipeline parallelism) in order to run LLM inference with such large models.

## How to determine shape and GPU requirements for a given model?

1. Find the number of parameters in your model (usually in the name of the model such as Llama-3.3-70B-Instruct would have 70 billion parameters)
2. Determine the precision of the model (FP32 vs FP16 vs FP8) - you can find this in the config.json of the model if on hugging face (look for the torch_dtype); a good assumption is that the model was trained on FP32 and is served on FP16 so FP16 is what you would use for your model precision
3. Use formula here: https://ksingh7.medium.com/calculate-how-much-gpu-memory-you-need-to-serve-any-llm-67301a844f21 or https://www.substratus.ai/blog/calculating-gpu-memory-for-llm to determine the amount of GPU memory needed
4. Determine which shapes you have access to and how much GPU memory each instance of that shape has: https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm (ex: VM.GPU2.1 has 16 GB of GPU memory per instance). Note that as of right now, you must use the same shape across the entire node pool when using multi-node inference. Mix and match of shape types is not supported within the node pool used for the multi-node inference blueprint.
5. Divide the total GPU memory size needed (from Step #3) by the amount of GPU memory per instance of the shape you chose in Step #4. Round up to the nearest whole number. This will be the total number of nodes you will need in your node pool for the given shape and model.

## How to use it?

We are using [vLLM](https://docs.vllm.ai/en/latest/serving/distributed_serving.html) and [Ray](https://github.com/ray-project/ray) using the [LeaderWorkerSet (LWS)](https://github.com/kubernetes-sigs/lws) to manage state between multiple nodes.

In order to use multi-node inference in an OCI Blueprint, first deploy a shared node pool with blueprints using [this recipe](../sample_blueprints/shared_node_pool_A10_VM.json).

Then, use the following blueprint to deploy serving software: [LINK](../sample_blueprints/multinode_inference_VM_A10.json)

The blueprint creates a LeaderWorkerSet which is made up of one head node and worker nodes. The head node is identical to other worker nodes (in terms of ability to run workloads on it), except that it also runs singleton processes responsible for cluster management.

More documentation on LWS terminology [here](https://lws.sigs.k8s.io/docs/).

## Required Blueprint Parameters

The following parameters are required:

- `"recipe_mode": "service"` -> recipe_mode must be set to `service`

- `"recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:ray2430_vllmv083"` -> currently, the only image we have supporting distributed inference.

- `recipe_container_port` -> the port to access the inference endpoint

- `deployment_name` -> name of this deployment

- `recipe_replica_count` -> the number of replicas (copies) of your blueprint.

- `recipe_node_shape` -> OCI name of the Compute shape chosen (use exact names as found here: https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)

- `input_object_storage` (plus the parameters required inside this object). volume_size_in_gbs creates a block volume to store your model, so ensure this is sufficient to hold your model (roughly 1.5x model size).

- `recipe_ephemeral_storage_size` -> size of the attached block volume that will be used to store any ephemeral data (a separate block volume is managed by input_object_storage to house model).

- `recipe_nvidia_gpu_count` -> the number of GPUs per node (since head and worker nodes are identical, it is the number of GPUs in the shape you have specified. Ex: VM.GPU.A10.2 would have 2 GPUs)

- `recipe_use_shared_node_pool` -> `true` - currently, multinode inference is only available on shared node pool deployments (for compatibility with RDMA shapes).

- `multinode_num_nodes_to_use_from_shared_pool` -> the total number of nodes (as an integer) you want to use to serve this model. This number must be less than the size of the shared node pool, and will only use schedulable nodes in the pool.

- [OPTIONAL] `"multinode_rdma_enabled_in_shared_pool": "true"` -> If you have deployed an HPC cluster with RDMA enabled for node pools - [see here for details](../deploy_ai_blueprints_onto_hpc_cluster) - enable RDMA communication between nodes (currently only supported for BM.GPU.H100.8). This will fail validation if RDMA is not supported for shape type, or node is missing appropriate labels described in linked doc.

- [OPTIONAL] `recipe_readiness_probe_params` -> Readiness probe to ensure that service is ready to serve requests. Parameter details found [here](../startup_liveness_readiness_probes/README.md).

## Requirements

- **Kuberay Operator Installed** = Make sure that the leaderworkerset (LWS) operator is installed (this is installed via the Resource Manager). Any OCI AI Blueprints installation before 4/17/25 will need to be reinstalled via the latest quickstarts release in order to ensure Kuberay is installed in your OCI AI Blueprints instance.

- **Same shape for worker and head nodes** = Cluster must be uniform in regards to node shape and size (same shape, number of GPUs, number of CPUs etc.) for the worker nodes and head nodes.

- **Chosen shape must have GPUs** = no CPU inferencing is available at the moment

- We only provide one distributed inference image which contains vLLM + Ray and some custom launching with LWS. It is possible that other frameworks are supported, but they are untested.

# Quickstart Guide: Multi-Node Inference

Follow these 6 simple steps to deploy your multi-node inference using OCI AI Blueprints.

1. **Deploy your shared node pool**
   - Deploy a shared node pool containing at least 2 nodes for inference. Note: Existing shared node pools can be used!
     - as a template, follow [this BM.A10](../sample_blueprints/shared_node_pool_A10_BM.json) or [this VM.A10](../sample_blueprints/shared_node_pool_A10_VM.json).
2. **Create Your Deployment Blueprint**
   - Create a JSON configuration (blueprint) that defines your RayCluster. Key parameters include:
     - `"recipe_mode": "service"`
     - `deployment_name`, `recipe_node_shape`, `recipe_container_port`
     - `input_object_storage` (and its required parameters)
     - `recipe_nvidia_gpu_count` (GPUs per node)
     - `multinode_num_nodes_to_use_from_shared_pool` (number of nodes to use from pool per replica)
   - Refer to the [sample blueprint for parameter value examples](../sample_blueprints/multinode_inference_VM_A10.json)
   - Refer to the [Required Blueprint Parameters](#Required_Blueprint_Parameters) section for full parameter details.
3. **Deploy the Blueprint via OCI AI Blueprints**
   - Deploy the blueprint json via the `deployment` POST API
4. **Monitor Your Deployment**
   - Check deployment status using OCI AI Blueprint’s logs via the `deployment_logs` API endpoint
5. **Verify Cluster Endpoints**
   - Once deployed, locate your service endpoints:
     - **API Inference Endpoint:** Accessible via `https://<deployment_name>.<assigned_service_endpoint>.nip.io`

6. **Start Inference and Scale as Needed**
   - Test your deployment by sending a sample API request:
     ```bash
     curl -L 'https://<deployment_name>.<assigned_service_endpoint>.nip.io/metrics'
     ...
     curl -L https://<deployment_name>.<assigned_service_endpoint>.nip.io/v1/completions \
     -H "Content-Type: application/json" \
     -d '{
         "model": "/models",
         "prompt": "San Francisco is a",
         "max_tokens": 512,
         "temperature": 0
     }' | jq

     ```

Happy deploying!
