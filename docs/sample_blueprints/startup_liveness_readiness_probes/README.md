# Startup, Liveness, and Readiness Probes

[Startup, Liveness, and Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) are tools you can add to a kubernetes deployment which tell Kubernetes that the node is actually ready. These are most highly relevant in a [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/) where you use a group of pods to serve responses over HTTP.

In the case of LLM inference, a service to serve the LLM can come online but it is not ready to start serving requests immediately because it first has to load the model weights. In this case, kubernetes will see that the service is ready because the container has started, but if you send a request to it while the model is loading it will error because it is not actually ready to serve. Hence, we add probes.

## Readiness Probe

A readiness probe runs continually in the background to determine when a pod is "ready". It has a success threshold of 1, and unlike a startup probe, will not fail your pod. It will run continually until success criteria is met.

In the case of vLLM for example, vLLM exposes a `/health` endpoint that can be queried that will simply return a `200 OK` status when the model has been loaded and vLLM is ready to serve requests, at which point the readiness probe would return "success" and stop running.

## Startup Probe

Given the above, a startup probe is a way to ensure Kubernetes will not route traffic to a container until the startup probe returns success. 

A key criteria of a startup probe is that it will run until it succeeds and then not run anymore. Success criteria is defined in the configuration. If the success criteria is never met, the pod will fail, so set parameters which closely match your deployment characteristics with some buffer room. Startup probes are more common in containers with long or complex deployments.

## Liveness Probe

A liveness probe is very similar to a startup probe, except that it runs continuously in the background to make sure the service is still alive. This is often run much less frequently as a "pulse". If this fails `failure_threshold` times, it will kill the container and restart it. Appropriate for long running services to ensure they are still healthy and serving requests.


## Parameter Description

Startup, liveness, and readiness probes in OCI AI Blueprints utilize the same parameters, simplifying the interface quite a bit. These can be added to any service to define when the service is ready, and if it is still alive:

There is an important consideration to make for the startup probe. If initialization of your application is long (for example you are loading a very large model that takes 30 minutes to load), then it is important to set an `initial_delay_seconds` that reflects that, or set a very high `failure_threshold`, or set a long `period_seconds` such that the time between checks is sufficient.

|         Param         |                        Description                        |    Example    |
| :-------------------: | :-------------------------------------------------------: | :-----------: |
|   failure_threshold   |     Allowable failures until container reports error      |      30       |
|     endpoint_path     |    Endpoint to query to check for readiness / liveness    |    /health    |
|         port          |          Port k8s uses to query `endpoint_path`           |     8000      |
|        scheme         |               protocol to use when querying               | HTTP or HTTPS |
| initial_delay_seconds |           Time before probe begins its testing            |      60       |
|    period_seconds     |         Amount of time between subsequent checks          |       2       |
|   success_threshold   | Number of successful queries before probe returns success |       1       |
|    timeout_seconds    |       Number of seconds after which probe times out       |       1       |

## Examples

The examples below represent the defaults used in the control plane. These are not required, but are recommended for services with any kind of startup time (like LLM inference).

### Minimum Example to Include a Probe

```json
{
  "recipe_startup_probe_params": {
    "endpoint_path": "/health"
  },
  "recipe_liveness_probe_params": {
    "endpoint_path": "/health"
  },
  "recipe_readiness_probe_params": {
    "endpoint_path": "/health"
  }
}
```

### Example with Control Plane Defaults

```json
{
  "recipe_startup_probe_params": {
    "failure_threshold": 30,
    "endpoint_path": "/health",
    "port": 8000,
    "scheme": "HTTP",
    "initial_delay_seconds": 10,
    "period_seconds": 2,
    "success_threshold": 1,
    "timeout_seconds": 1
  },
  "recipe_liveness_probe_params": {
    "failure_threshold": 3,
    "endpoint_path": "/health",
    "port": 8000,
    "scheme": "HTTP",
    "initial_delay_seconds": 600,
    "period_seconds": 600,
    "success_threshold": 1,
    "timeout_seconds": 1
  },
  "recipe_readiness_probe_params": {
    "endpoint_path": "/health",
    "port": 8000,
    "scheme": "HTTP",
    "initial_delay_seconds": 15,
    "period_seconds": 10,
    "success_threshold": 1,
    "timeout_seconds": 2
  }
}
```
