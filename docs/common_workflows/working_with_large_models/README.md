# Working with Large Models

## Deploy Shared Node Pool

Most large models require a large machine to handle inference / finetuning of the model, therefore we recommend you use a bare-metal shape for the large model.

As a first step, for bare-metal shapes we recommend deploying a shared node pool due to the large recycle times. Shared node pools allow us to deploy blueprints onto and off of the node without destroying the node resources. To deploy an H100 shared node pool, here is the JSON for the /deployment API:

```json
{
  "deployment_name": "H100_shared_pool",
  "recipe_mode": "shared_node_pool",
  "shared_node_pool_size": 1,
  "shared_node_pool_shape": "BM.GPU.H100.8",
  "shared_node_pool_boot_volume_size_in_gbs": 1000
}
```

Bare metal shapes can take up to 30 minutes to come online. If you hit a shape validation error but you have capacity for the shape (this happens sometimes and is an internal OCI issue), use this instead:

```json
{
  "deployment_name": "H100_shared_pool",
  "recipe_mode": "shared_node_pool",
  "shared_node_pool_size": 1,
  "shared_node_pool_shape": "BM.GPU.H100.8",
  "shared_node_pool_boot_volume_size_in_gbs": 1000,
  "skip_capacity_validation": true,
  "skip_quota_validation": true
}
```

## Download the model to object storage (optional, but recommended)

For repeat deployments, large models take longer to download from huggingface than they do from object storage because of how we've implemented the download from object storage vs how the huggingface download works in code.

**NOTE**: For any step involving a closed model for huggingface (meta models as an example), you will need to use your own token to download the model. We cannot distribute huggingface tokens as it breaks the SLA.

Steps:

1. Create a bucket in object storage in the same region as the shared node pool (decrease copy times). In our example, we will call this something similar to the name of the model we plan to use: `llama3290Bvisioninstruct`

2. Once the bucket is finished creating, deploy [this blueprint](../../sample_blueprints/platform_feature_blueprints/model_storage/download_closed_hf_model_to_object_storage.json) to copy `meta-llama/Llama-3.2-90B-Vision-Instruct` to the bucket you created.
   - **Note**: The blueprint assumes you created the bucket using the name `llama3290Bvisioninstruct`. If you changed the name, you will also need to modify it in the example blueprint.


Once this copy is done, the model can now be used for blueprint deployments. You can track this in API deployment logs.

## Deploy the serving blueprint

Once the copy is done, we can now deploy the blueprint using the model, except copying it from our object storage in the same region as our blueprint. Note the bucket name is the name of the bucket you created for your model:

```json
{
  "recipe_id": "llm_inference_nvidia",
  "recipe_mode": "service",
  "deployment_name": "90bvisioninstruct",
  "recipe_image_uri": "docker.io/vllm/vllm-openai:v0.9.1",
  "recipe_node_shape": "BM.GPU.H100.8",
  "recipe_replica_count": 1,
  "recipe_container_port": "8000",
  "recipe_nvidia_gpu_count": 8,
  "recipe_use_shared_node_pool": true,
  "recipe_node_boot_volume_size_in_gbs": 900,
  "recipe_container_command_args": [
    "--model",
    "/models",
    "--tensor-parallel-size",
    "8"
  ],
  "recipe_ephemeral_storage_size": 800,
  "recipe_shared_memory_volume_size_limit_in_mb": 80000,
  "recipe_prometheus_enabled": true,
  "input_object_storage": [
    {
      "bucket_name": "llama3290Bvisioninstruct",
      "mount_location": "/models",
      "volume_size_in_gbs": 500
    }
  ]
}
```

## Test a query

When the blueprint comes up, find the service endpoint in the url provided in the deployment digest section of the api for this blueprint. Using my example above, the service endpoint would come out to something like:

`90bvisioninstruct.<base_endpoint>.nip.io`

A simple test to ensure it is serving correctly is to run:

```bash
curl -L 90bvisioninstruct.<base_endpoint>.nip.io/metrics
```

Which will hit the server's metrics endpoint.

To test an actual vision query of this model, create the following file called `request.json` (make sure that url for the image is all on a single line):

```
{
  "model": "/models",
  "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": "What's in this image?"},
            {"type": "image_url", "image_url": {"url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"}}
        ]
    }]
}
```

Then, with the `request.json` in place, run:

```bash
 curl -L https://90bvisioninstruct.<base_endpoint>.nip.io/v1/chat/completions --header 'Content-Type: application/json' --data-binary @request.json
```

## Complete

At this point, you have successfully deployed 3 separate blueprints:

1. Spin up a bare metal shared node pool to deploy blueprints onto
2. Deployed a blueprint to copy a large model from huggingface to your own object storage
3. Deployed the model to an inference serving endpoint on your shared node pool
4. Tested the inference endpoint
