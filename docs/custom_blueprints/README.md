# Custom Blueprints

Welcome to the world of **OCI AI Blueprints**! This guide provides a detailed walkthrough on how to create, publish, and maintain custom blueprints. By the end, you will understand how custom blueprints, pre-filled samples, and the associated JSON schemas all come together to streamline AI deployments on Oracle Cloud Infrastructure (OCI).

---

## What Are Custom Blueprints?

**Custom Blueprints** are community-contributed templates (or "recipes") designed to handle specialized AI/ML use cases. Think of each blueprint as a **reusable and shareable** configuration that defines:

1. **Which container image** to use (the AI/ML application you want to run)
2. **What resources** (such as CPU, GPU, memory, or storage) it needs
3. **How it should run** (environment variables, command-line arguments, ports, replicas, etc.)

### Why Create a Custom Blueprint?

1. **Address Unique Needs:** You might have a special workflow—like integrating a third-party API or needing a particular AI framework—that no existing blueprint covers. Creating a custom blueprint solves that problem.
2. **Share Innovations:** Once you contribute your custom blueprint, anyone using **OCI AI Blueprints** can benefit. The entire community can learn from and build upon your solution.
3. **Standardize Deployments:** By defining everything in a blueprint, you ensure that teams deploy consistent, fully tested configurations without manual setup each time.

### Examples

- **"RAG Blueprint with 23.ai integration"** to demonstrate retrieval-augmented generation using an external service.
- **"Agentic Blueprint"** for specialized agent-like workflows that require advanced orchestration.

---

## What Are Pre-Filled Samples?

**Pre-Filled Samples** are **ready-to-deploy variations** of a blueprint. While a blueprint outlines the general structure of a deployment, a pre-filled sample provides **specific, pre-configured parameters**. Think of it as a “sample recipe” that demonstrates:

1. **Realistic Configurations:** Concrete examples of how to set environment variables, arguments, and other options.
2. **Adaptable Deployments:** How to customize the same blueprint to serve different models, data sets, or resource requirements.
3. **Deployment Best Practices:** Proper usage of resources like GPU, CPU, and disk volumes for optimal performance.

### Why Use Pre-Filled Samples?

- **Get Started Quickly:** If you’re unsure how to configure a blueprint, start with a sample that has working defaults.
- **Learn by Example:** Seeing a fully functioning configuration helps you understand how the blueprint’s parameters work.
- **Avoid Pitfalls:** Samples are typically vetted and tested to reduce common mistakes or misconfigurations.

**In short**, Pre-Filled Samples make blueprints **more accessible and easier to adapt** to your own needs.

---

## How Do Custom Blueprints and Pre-Filled Samples Relate to Their JSON Schemas?

When you build a custom blueprint, you must ensure your JSON file meets the specifications of the **Blueprint JSON Schema**. Within that same JSON file, there is an array called `pre_filled_samples`—each element of which is defined by the **Pre-Filled Sample JSON Schema**.

1. **Blueprint JSON Schema**  
   Defines the overall structure of a blueprint - including the metadata for the blueprint and the pre-filled samples (an array of pre-filled sample json objects).

2. **Pre-Filled Sample JSON Schema**  
   Governs the format of each individual **pre-filled sample** object. All items in the `pre_filled_samples` array must conform to this schema. This ensures consistency and compatibility across different deployments.

By leveraging both schemas, you guarantee that your main blueprint configuration and the included pre-filled samples are recognized and supported by OCI AI Blueprints.

---

## Publishing Custom Blueprints: Step-by-Step Guide

Follow these steps to create, validate, and publish your custom blueprint. This process ensures that all relevant details align with the **Blueprint JSON Schema** and that your pre-filled samples align with the **Pre-Filled Sample JSON Schema**. Please use the [api documentation](../../docs/api_documentation.md) for understanding of each parameter in the pre-filled sample payload.

1. **Upload Your Container Image to a Registry**

   - Build your Docker or OCI-compliant container image (containing your AI/ML application).
   - Push it to a public container registry (for example, Oracle Container Registry, Docker Hub, or any registry you choose), ensuring others can pull it.

2. **Create and Test a Pre-Filled Sample Deployment**

   - Refer to the **Example Pre-Filled Sample** below to see how you might structure your JSON.
   - Confirm the sample’s JSON meets the requirements of the **Pre-Filled Sample JSON Schema**.
   - Deploy it on **OCI AI Blueprints** to confirm everything works (e.g., the container runs, the resources are allocated properly, etc.).

3. **Create the `custom-blueprint.json` File**

   - Construct a new JSON file that follows the [Blueprint JSON Schema](../custom_blueprints/blueprint_json_schema.json).
   - Provide **2–3 Pre-Filled Samples** to help users get started quickly.

4. **Validate Your JSON Schemas**

   - Use an online validator like [jsonschemavalidator.net](https://www.jsonschemavalidator.net/) to confirm the overall blueprint JSON meets the **Blueprint JSON Schema**, and each sample in `pre_filled_samples` meets the **Pre-Filled Sample JSON Schema**.
   - This step helps catch typos or missing fields before you publish.

5. **Test the Pre-Filled Samples on Your Own Instance**

   - Deploy each pre-filled sample in your own **OCI AI Blueprints** environment.
   - Verify they run successfully and produce the expected results.

6. **Send the `custom-blueprint.json` File to the OCI AI Blueprints Team**

   - Provide them with your final, validated JSON file for review.
   - They can help ensure the blueprint meets quality standards.

7. **Submit Changes to GitHub**
   - Fork or clone this GitHub repository containing official OCI AI Blueprints.
   - Add or modify your files as needed, and then submit a **pull request**.
   - The **OCI AI Blueprints** team will review, provide feedback if necessary, and merge your changes once approved.

---

## Maintaining Custom Blueprints

**Staying current** and **ensuring usability** are crucial for any blueprint:

- **Schema Updates:** Keep your blueprint aligned with the latest **Blueprint JSON Schema** and ensure your pre-filled samples follow the **Pre-Filled Sample JSON Schema** if new fields or deprecations occur.
- **Issue Tracking:** Watch for GitHub issues related to your blueprint—bugs, feature requests, or improvements—and address them promptly.
- **Version History:** If you introduce breaking changes, consider how to maintain backward compatibility or document upgrade steps for existing users.

---

## Blueprint JSON Schema

The **Blueprint JSON Schema** is the official definition of all fields a blueprint must include, such as `recipe_id`, `recipe_mode`, `recipe_image_uri`, and more. It also requires that any `pre_filled_samples` array reference separate schemas for each item in that array.

You can find the blueprint schema here:  
[**Blueprint JSON Schema**](../custom_blueprints/blueprint_json_schema.json)

---

## Pre-Filled Sample JSON Schema

All pre-filled sample objects will be objects inside the `pre_filled_samples` array in the [**Blueprint JSON Schema**](../custom_blueprints/blueprint_json_schema.json). This schema dictates exactly which fields a valid pre-filled sample must include (e.g., `deployment_name`, `recipe_node_shape`, environment variables, etc.).

---

## Example Pre-Filled Sample

Below is an **example** demonstrating how you might configure one entry in the `pre_filled_samples` array of your custom blueprint. It targets vLLM inference on an NVIDIA GPU shape:

```json
{
  "recipe_id": "llm_inference_nvidia",
  "recipe_mode": "service",
  "deployment_name": "vLLM Inference Deployment",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:vllmv0.6.2",
  "recipe_node_shape": "VM.GPU.A10.2",
  "input_object_storage": [
    {
      "par": "https://objectstorage.us-ashburn-1.oraclecloud.com/p/IFknABDAjiiF5LATogUbRCcVQ9KL6aFUC1j-P5NSeUcaB2lntXLaR935rxa-E-u1/n/iduyx1qnmway/b/corrino_hf_oss_models/o/",
      "mount_location": "/models",
      "volume_size_in_gbs": 500,
      "include": ["NousResearch/Meta-Llama-3.1-8B-Instruct"]
    }
  ],
  "recipe_container_env": [
    {
      "key": "tensor_parallel_size",
      "value": "2"
    },
    {
      "key": "model_name",
      "value": "NousResearch/Meta-Llama-3.1-8B-Instruct"
    },
    {
      "key": "Model_Path",
      "value": "/models/NousResearch/Meta-Llama-3.1-8B-Instruct"
    }
  ],
  "recipe_replica_count": 1,
  "recipe_container_port": "8000",
  "recipe_nvidia_gpu_count": 2,
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_container_command_args": [
    "--model",
    "$(Model_Path)",
    "--tensor-parallel-size",
    "$(tensor_parallel_size)"
  ],
  "recipe_ephemeral_storage_size": 100,
  "recipe_shared_memory_volume_size_limit_in_mb": 200
}
```

**Key elements to note in this sample:**

- **`recipe_id` and `recipe_mode`**: Identify the blueprint and indicate how it runs (service vs. batch).
- **`recipe_image_uri`**: Points to a public container image in a registry.
- **`recipe_node_shape`**: Defines the hardware resources (here, a GPU shape).
- **`input_object_storage`**: Tells OCI AI Blueprints which object storage resources to mount, and where.
- **`recipe_container_env`**: Environment variables used inside the container (e.g., model names, paths, configuration values).
- **`recipe_container_command_args`**: Command-line arguments that the container uses to start up.
- **`recipe_ephemeral_storage_size`**: Temporary disk space needed by the container.
- **`recipe_shared_memory_volume_size_limit_in_mb`**: Allocated shared memory for specific operations, often crucial for GPU-based ML tasks.

By adapting these fields to your own project requirements—such as using a different container image or adjusting GPU count—you can deploy your custom AI/ML applications within **OCI AI Blueprints** quickly.

---

## Conclusion

Creating and sharing **Custom Blueprints** and **Pre-Filled Samples** is a powerful way to **scale AI deployments** and **foster community collaboration** within OCI AI Blueprints. By adhering to both the **Blueprint JSON Schema** and the **Pre-Filled Sample JSON Schema**, you ensure your configurations are consistent, testable, and easy to adopt. We encourage you to contribute your innovations, learn from existing community samples, and help build a richer ecosystem for all.

**Thank you** for choosing OCI AI Blueprints. We look forward to seeing your next custom creation!
