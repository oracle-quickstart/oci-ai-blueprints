# Autoscaling

#### Scale inference workloads based on traffic load

OCI AI Blueprints supports automatic scaling (autoscaling) of inference workloads to handle varying traffic loads efficiently. This means that when demand increases, OCI AI Blueprints can spin up more pods (containers running your inference jobs) and, if needed, provision additional GPU nodes. When demand decreases, it scales back down to save resources and cost.

## Pre-Filled Samples

| Feature Showcase                                                                                    | Title                                                 | Description                                                                                                                                                             | Blueprint File                                           |
| --------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| Demonstrate automatic scaling of inference workloads with both pod-level and node-level autoscaling | vLLM Inference with Automatic Scaling on VM.GPU.A10.2 | Deploys a vLLM inference service with automatic scaling capabilities, scaling from 1-4 pods and 1-2 nodes based on traffic load using VM.GPU.A10.2 with 1 GPU per node. | [autoscaling_blueprint.json](autoscaling_blueprint.json) |

---

# In-Depth Feature Overview

OCI AI Blueprints supports automatic scaling (autoscaling) of inference workloads to handle varying traffic loads efficiently. This means that when demand increases, OCI AI Blueprints can spin up more pods (containers running your inference jobs) and, if needed, provision additional GPU nodes. When demand decreases, it scales back down to save resources and cost.

To achieve this, OCI AI Blueprints uses [Kubernetes Event-driven Autoscaling](https://keda.sh) along with [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) (HPA) and the [OCI Cluster Autoscaler Add-on](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusingclusterautoscaler_topic-Working_with_Cluster_Autoscaler_as_Cluster_Add-on.htm).

## Quick Reference: Add the following to your inference blueprint to use autoscaling:

This is the minimum you need to add to your blueprint json to add pod autoscaling to an inference blueprint:

```json
    "recipe_pod_autoscaling_params": {
        "min_replicas": 1,
        "max_replicas": 4
    }
```

This is the minimum you need to add to your blueprint json to add pod + node autoscaling to an inference blueprint:

```json
    "recipe_pod_autoscaling_params": {
        "min_replicas": 1,
        "max_replicas": 4
    }
    "recipe_node_autoscaling_params": {
        "min_nodes": 1,
        "max_nodes": 2
    }
```

This will be added to the blueprint payload JSON in the `/deployment` POST request.

## How it works

1. Monitoring Load with Prometheus
   - OCI AI Blueprints collects real-time performance data using Prometheus, a popular monitoring tool.
   - Specifically, it tracks vLLM inference metrics (e.g., request rate, GPU usage).
2. Scaling Pods with KEDA and HPA
   - KEDA watches these metrics and uses a query (written in PromQL, Prometheus's query language) to determine when to scale up or down.
   - If the query result crosses a defined threshold, the HPA will trigger a scale-up, adding more inference pods.
   - When load decreases, HPA scales down the pods.
3. Scaling Nodes with OCI Cluster Autoscaler
   - If the current GPU nodes don’t have enough capacity for new pods, the OCI Cluster Autoscaler provisions additional GPU nodes automatically.
   - Once demand drops, it removes unnecessary nodes to optimize costs.

To prevent frequent scaling due to sudden traffic spikes, OCI AI Blueprints includes smoothing factors, ensuring that scaling is responsive but not overly aggressive.

## Configuring Autoscaling

When setting up autoscaling, it's important to define:

1. Number of GPUs required per blueprint
2. Total number of GPU nodes available
3. Maximum number of replicas (inference pods) you want to run

### Example Scenario

Suppose you have the following configuration:

- Inference blueprint: Requires 1 GPU
- Node type: VM.GPU.A10.2 (which has 2 GPUs)
- Starting replicas: 1
- Each replica is set to require 1 GPU
- Since each node has 2 GPUs, you can scale up one additional replica before requiring a new node.
- When a third replica is needed, a new GPU node must be provisioned.

### Best Practices

1. Optimize GPU allocation
   - Ensure the number of GPUs required per replica divides evenly into the total GPUs on a node.
   - Example: If a blueprint needs 2 GPUs, running it on a 4-GPU node allows for 1 scale-up before requiring a new node.
2. Avoid setting more replicas than available GPUs
   - If the max replicas are set to 8, but your cluster can only fit 4, the extra 4 replicas will remain in a pending state due to insufficient resources.

## Basic Configurations

Examples with utilizing these parameters will be shown below.

|              key               |  Parameter   |  Type   |               Description                | Example |
| :----------------------------: | :----------: | :-----: | :--------------------------------------: | :-----: |
| recipe_pod_autoscaling_params  | min_replicas | integer | Minimum number of replicas to start with |    1    |
| recipe_pod_autoscaling_params  | max_replicas | integer |  Maximum number of replicas to scale to  |    4    |
| recipe_node_autoscaling_params |  min_nodes   | integer |   Minimum number of nodes in node pool   |    1    |
| recipe_node_autoscaling_params |  max_nodes   | integer |    Maximum node pool size to scale to    |    4    |

## Advanced Configurations

In addition to the basic configuration which should be sufficient for most users, additional parameters are tunable. The modification of these parameters has been tested, but each will impact scaling in a different way and should be used cautiously. All of these are part of `recipe_pod_autoscaling_params`:

|         Parameter         |  Type   |                                                                                       Description                                                                                       | Example |
| :-----------------------: | :-----: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-----: |
| collect_metrics_timespan  | integer |                                                             time over which to collect time series metrics from prometheus                                                              |   5m    |
|     scaling_threshold     | number  | Threshold value to trigger scaling. If tuning, this will be most impactful on scaling. Moving it up will make scaling less aggressive, moving it down will make scaling more aggressive |   0.5   |
|     scaling_cooldown      | integer |                                                             Min time to wait after scaling up before scaling back down (s)                                                              |   60    |
|     polling_interval      | integer |                                                                          How often to query scaling metric (s)                                                                          |   15    |
| stabilization_window_down | integer |                                                        Time period over which to stabilize metrics before scaling a pod down (s)                                                        |   180   |
|    scaling_period_down    | integer |                                                         Min time after scaling a pod down before it can scale another pod down                                                          |   90    |
|  stabilization_window_up  | integer |                                                         Time period over which to stabilize metrics before scaling a pod up (s)                                                         |   120   |
|     scaling_period_up     | integer |                                                             Min time after scaling a pod up before another pod can be added                                                             |   60    |
|           query           | string  |                        If desired, a valid prometheus query to be used in conjunction with threshold to trigger scaling. Will completely change scaling behavior                        |         |

### Adjusting the Prometheus Query

This is an advanced topic, and will materially affect autoscaling but is fully supported in OCI AI Blueprints. Each blueprint deployment comes with a prometheus endpoint that can be preprended to the base url associated with your stack. So, if my base url was:
`100-200-160-20.nip.io` then my prometheus url would be `prometheus.100-200-160-20.nip.io`.

When I have deployed a blueprint with autoscaling enabled, I can visit this endpoint and see the available metrics that vllm surfaces for users by typing `vllm:` in the search bar. A full list of production metrics can be found [here](https://docs.vllm.ai/en/v0.6.6/serving/metrics.html). The end goal of query adjustment is to:

1. Find a value that reflects the criteria you want to scale on
2. Write a query that gives you a time averaged result (generally used with the `rate` function in promQL)
3. Find a threshold that meets your needs for scaling

An example query using `rate` in promQL format would look like this:

```
avg(rate(vllm:e2e_request_latency_seconds_count{instance="recipe-advancedauto2.default:80"}[5m]))
```

This query finds an average rate over a 5 minute time window. This query is insufficient because all it averages over is the number of requests received each minute, and puts in no bearing on performance.

A more realistic query looks a bit more complicated - here is the default query we use to scale:

```
1 - (sum(rate(vllm:e2e_request_latency_seconds_bucket{le='5.0', instance='recipe-vllmautowithfss.default:80'}[5m])) / sum(rate(vllm:e2e_request_latency_seconds_bucket{le='+Inf', instance='recipe-vllmautowithfss.default:80'}[5m])))"
```

This value uses histogram buckets provided by vLLM and:

1. Gets the rate of all requests that finished in < 5 seconds.
2. Divides that by all requests to get the fraction of all requests that finished in 5s or less
3. Subtracts this from 1 to determine the rate of requests that took more than 5s

This is essentially a p-value of requests that completed in more than 5 seconds. When compared to the `scaling_threshold` in the advanced parameters, this cutoff is then more easily explained. If the threshold was 0.6, the explanation would be:

"Scale when 60% of all requests take more than 5s to complete end-to-end."

Similar logic should be applied when considering your own queries for best performance.

## Pod Autoscaling (Single Node Scaling)

Pod auto-scaling allows a blueprint to scale within a single node, up to the number of GPUs available on that node. Below are two examples:

### Example 1: Blueprint with 2 GPUs on an H100 Node

- Blueprint requires 2 GPUs.
- A BM.GPU.H100.8 node has 8 GPUs, meaning it can support up to 4 replicas before needing another node.

```json
{
  "recipe_node_shape": "BM.GPU.H100.8",
  "recipe_replica_count": 1,
  "recipe_node_pool_size": 1,
  "recipe_nvidia_gpu_count": 2,
  "recipe_pod_autoscaling_params": {
    "min_replicas": 1,
    "max_replicas": 4
  }
}
```

### Example 2: Blueprint with 1 GPU on an A10 Node

- recipe requires 1 GPU
- A VM.GPU.A10.2 node has 2 GPUs, meaning it can support up to 2 replicas

```json
{
  "recipe_node_shape": "VM.GPU.A10.2",
  "recipe_replica_count": 1,
  "recipe_node_pool_size": 1,
  "recipe_nvidia_gpu_count": 1,
  "recipe_pod_autoscaling_params": {
    "min_replicas": 1,
    "max_replicas": 2
  }
}
```

#### Additional Considerations:

Pod autoscaling can be paired with startup and liveness probes to verify that a blueprint is both ready to receive requests and continuing to function properly. For more information, visit [our startup and liveness probe doc](../startup_liveness_readiness_probes/README.md).

## Node + Pod Auto-Scaling (Scaling Beyond a Single Node)

When a single node can no longer handle additional replicas, OCI AI Blueprints will provision new GPU nodes. Below are two examples:

### Example 1: Scaling Across Two H100 Nodes

- Blueprint requires 2 GPUs.
- A BM.GPU.H100.8 node has 8 GPUs, meaning it can support up to 4 replicas per node.
  With node autoscaling, up to 2 nodes can be added, supporting 8 replicas total.

```json
{
  "recipe_node_shape": "BM.GPU.H100.8",
  "recipe_replica_count": 1,
  "recipe_node_pool_size": 1,
  "recipe_nvidia_gpu_count": 2,
  "recipe_node_autoscaling_params": {
    "min_nodes": 1,
    "max_nodes": 2
  },
  "recipe_pod_autoscaling_params": {
    "min_replicas": 1,
    "max_replicas": 8
  }
}
```

### Example 2: Scaling Across 4 A10 Nodes

- Blueprint requires 1 GPU.
- A VM.GPU.A10.2 node has 2 GPUs, meaning it can support up to 2 replicas per node.
- With node autoscaling, up to 4 nodes can be added, supporting 8 replicas total.

```json
{
  "recipe_node_shape": "VM.GPU.A10.2",
  "recipe_replica_count": 1,
  "recipe_node_pool_size": 1,
  "recipe_nvidia_gpu_count": 1,
  "recipe_node_autoscaling_params": {
    "min_nodes": 1,
    "max_nodes": 4
  },
  "recipe_pod_autoscaling_params": {
    "min_replicas": 1,
    "max_replicas": 8
  }
}
```

### Example 3: Scaling Across 4 A10 Nodes with Advanced Pod Parameters

- Blueprint requires 1 GPU.
- A VM.GPU.A10.2 node has 2 GPUs, meaning it can support up to 2 replicas per node.
- With node autoscaling, up to 4 nodes can be added, supporting 8 replicas total.
- We want to adjust the scale up and scale down times and smoothening windows to scale very quickly.

```json
{
  "recipe_node_shape": "VM.GPU.A10.2",
  "recipe_replica_count": 1,
  "recipe_node_pool_size": 1,
  "recipe_nvidia_gpu_count": 1,
  "recipe_node_autoscaling_params": {
    "min_nodes": 1,
    "max_nodes": 4,
    "collect_metrics_timespan": "2m",
    "scaling_threshold": 0.4,
    "scaling_cooldown": 30,
    "polling_interval": 10,
    "stabilization_window_down": 60,
    "scaling_period_down": 30,
    "stabilization_window_up": 30,
    "scaling_period_up": 15
  },
  "recipe_pod_autoscaling_params": {
    "min_replicas": 1,
    "max_replicas": 8
  }
}
```

## Example Blueprint and Testing

The following [example_blueprint](autoscaling_blueprint.json) shows a minimum basic example of how to use autoscaling with vLLM. Paste this in your deployment, and then post to launch the blueprint.

Note, the `scaling_threshold` parameter here is intentionally set very low to kick off scaling at a lighter load. It is better to use the defaults.

Once the blueprint is ready, follow the example steps to test autoscaling:

1. Get your workspace url. It will be everything after `api` in your deployment. So for example, my api endpoint is api.100-200-160-20.nip.io, so my workspace endpoint is `100-200-160-20.nip.io`. Using my endpoint, the vllm endpoint is the `deployment_name` from the `example_blueprint.json` + my workspace endpoint, so:

`autoscalevllmexample.100-200-160-20.nip.io`

To test this is correct, run:

```bash
curl -L autoscalevllmexample.100-200-160-20.nip.io/metrics
```

Which will give you current metrics vLLM is reporting from your server.

2. Run the following to hit your endpoint with load:

```bash
# Note, python version must be 3.8 < python version < 3.11 for this tool.

git clone https://github.com/ray-project/llmperf.git && cd llmperf
git checkout 03872a48f7df06bb6760bf23d0d2c2784d7d9728
python3 -m venv venv
source venv/bin/activate
pip3 install -e .

# this is the vllm endpoint above, prefixed by https:// and with /v1
export OPENAI_API_BASE="https://autoscalevllmexample.100-200-160-20.nip.io/v1"
export OPENAI_API_KEY="test"
python3 token_benchmark_ray.py \
  --model /models \
  --mean-input-tokens 512 \
  --mean-output-tokens 512 \
  --stddev-input-tokens 10 \
  --stddev-output-tokens 10 \
  --num-concurrent-requests 30 \
  --timeout 3600 \
  --max-num-completed-requests 3000 \
  --results-dir t \
  --llm-api openai
```

3. Advanced users can check the kubernetes cluster locally by watching `kubectl get pods` to see both node and pod autoscaling. Otherwise, go to the OKE cluster in the console, click node pools, go to the blueprint specific node pool, and after a few minutes you'll see a new node appear in the pool. This new node creation typically appears between 8-10% on the llmperf completion bar you see in the terminal when launching the requests (based on the example blueprint provided).
