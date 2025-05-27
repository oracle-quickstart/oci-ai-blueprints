# Deploying Blueprints Onto Specific Nodes

**Note:** A basic understanding of how to use Kubernetes is required for this task

Assumption: the node exists and you are installing OCI AI Blueprints alongside this pre-existing node (i.e. the node is in the same cluster as the OCI AI Blueprints application)

## Label Nodes

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
3. Login with the `Admin Username` and `Admin Password` in the Application information tab.
4. Click the link next to "deployment" which will take you to a page with "Deployment List", and a content box.
5. Paste in the sample blueprint json found [here](../../sample_blueprints/exisiting_cluster_installation/add_node_to_control_plane.json).
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

### Adding additional labels

To add any additional labels to nodes that you may wish to use later to specify deployment targets, this field (`recipe_node_labels`) can take any arbitrary number of labels to apply to a given node. For example, in the blueprint json, you could add the following:

```json
"recipe_node_labels": {
  "key1": "value1",
  "key2": "value2",
  "key3": "value3"
}
```

## Deploy a blueprint

Now that you have artifically created a shared node pool using the node labels above, you can deploy a recipe to that node pool.

```json
{
  "recipe_id": "example",
  "recipe_mode": "service",
  "deployment_name": "a10 deployment",
  "recipe_use_shared_node_pool": true,
  "recipe_image_uri": "hashicorp/http-echo",
  "recipe_container_command_args": ["-text=corrino"],
  "recipe_container_port": "5678",
  "recipe_node_shape": "BM.GPU.A10.4",
  "recipe_replica_count": 1,
  "recipe_nvidia_gpu_count": 4,
  "shared_node_pool_custom_node_selectors": [
    {
      "key": "corrino",
      "value": "a10pool"
    }
  ]
}
```

Note: In the example above, we specified `recipe_nvidia_gpu_count` as 4 which means we want to use 4 of the GPUs on the node.

Note: We set `shared_node_pool_custom_node_selectors` to "a10pool" to match the name of the shared node pool we created with the exisiting node. Here, we could add any additional labels added to target specific nodes for work.

Note: We set `recipe_use_shared_node_pool` to true so that we are using the shared node mode behavior for the blueprint (previously called recipe).

## Complete

At this point, you have successfully deployed a blueprint to an exisiting node and utilized a portion of the existing node by specifiying the specific number of GPUs you wish to use for the blueprint.
