# Autoscaling

#### Scale inference workloads based on traffic load

OCI AI Blueprints supports automatic scaling (autoscaling) of inference workloads to handle varying traffic loads efficiently. This means that when demand increases, OCI AI Blueprints can spin up more pods (containers running your inference jobs) and, if needed, provision additional GPU nodes. When demand decreases, it scales back down to save resources and cost.

## Pre-Filled Samples

| Feature Showcase                                                                                    | Title                                                 | Description                                                                                                                                                             | Blueprint File                                           |
| --------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| Demonstrate automatic scaling of inference workloads with both pod-level and node-level autoscaling | vLLM Inference with Automatic Scaling on VM.GPU.A10.2 | Deploys a vLLM inference service with automatic scaling capabilities, scaling from 1-4 pods and 1-2 nodes based on traffic load using VM.GPU.A10.2 with 1 GPU per node. | [autoscaling_blueprint.json](autoscaling_blueprint.json) |
