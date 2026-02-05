# Vehicle Route Optimizer Accelerator Pack

The **Vehicle Route Optimizer Starter Pack** is an AI Accelerator Pack that delivers a combined **hardware and software** solution for route optimization on Oracle Cloud Infrastructure (OCI) by deploying the [cuOpt NIM](https://docs.api.nvidia.com/nim/reference/nvidia-cuopt) with an interactive front-end to interact with the route planner.

## What You Get

- **Hardware:** 8 A100 GPUs (40 GB or 80GB) running on Oracle Kubernetes Engine (OKE) for a fully managed service oriented architecture.
- **Software:** NVIDIA cuOpt route-planning server and custom interactive front-end
  - [cuOpt Server](https://github.com/NVIDIA/cuopt/tree/main/python): API server with built-in queuing for longer-running optimization jobs
  - **Interactive front-end:** Front-end user interface which allows users to interact with a pre-loaded cuOpt data set with an AI chat interface leveraging OCI GenAI PaaS models. Tool calls can directly modify the dataset and replan routes automatically.

Together, the pack brings a route optimization server capable of planning thousands of complex routes per day, as well as real time re-routing capabilities.

## Use Case

Legacy route planning systems can take anywhere from 12-24 hours to plan for the hundreds to thousands of field service workers or engineers traveling to sites throughout the day. This is not just hypothetical - in an early access PoC, we had a partner integrate their route data with the Route Optimizer and cut down their route planning calculation times from 24 hours to 67 seconds - a greater than 1000x speedup. Additionally, due to the performance of the route optimizer, they were able to do in-day replanning of routes lowering missed appt rates by 2%.

## Specs, Additional References, and Architecture

[API Spec](https://docs.nvidia.com/cuopt/user-guide/latest/open-api.html) - click on the link at the top to download

![Vehicle Route Optimizer Architecture](/docs/ai_accelerator_packs/media/cuopt_arch.png)

[Additional Use Cases from NVIDIA](https://docs.api.nvidia.com/nim/reference/nvidia-cuopt)

[Routing Examples](https://docs.nvidia.com/cuopt/user-guide/latest/cuopt-server/examples/routing-examples.html)

## Deployment and Access

You can deploy the Vehicle Route Optimizer Accelerator Pack from the **OCI Console**. In the navigation menu (hamburger or three lines in top left) -> Analytics & AI -> Vehicle Route Optimizer. Choose a deployment size and optionally to enable the frontend-ui, add the portal credentials, and click Create. The console uses the pack's sizing to provision the right GPU compute, OKE cluster, networking, and the Vehicle Route Optimizer software stack.

After deployment you get:

- **OCI AI Blueprints Portal**: The stack exposes the Blueprints portal URL.
- **Route Optimizer API / UI**: For production use, sending vehicle routing problems directly to the API will be the most performant approach. The UI will allow you to interact with the dataset to get a feel.