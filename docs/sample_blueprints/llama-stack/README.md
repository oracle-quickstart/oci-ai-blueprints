# Llama Stack on OCI

#### Pre-packaged GenAI runtime — vLLM + ChromaDB + Postgres (optional Jaeger) ready for one-click deployment

Deploy Llama Stack on OCI via OCI AI Blueprints. In order to get the full Llama Stack Application up and running, you will need to deploy the following pre-filled samples in a specific order. Before deploying the pre-filled samples, make sure to have two object storage buckets created in the same compartment that OCI AI Blueprints is deployed into named `chromadb` and `llamastack`.

Order of Pre-Filled Sample Deployments:

1. vLLM Inference Engine
2. Postgres DB
3. Chroma DB
4. Jaegar
5. Llama Stack Main App

## Pre-Filled Samples

| Feature Showcase                                                               | Title                                     | Description                                                                                                                                                  | Blueprint File                                 |
| ------------------------------------------------------------------------------ | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------- |
| vLLM inference engine for large language model serving                         | vLLM Inference with Llama 3.1 8B Instruct | Deploys a vLLM inference service running NousResearch/Meta-Llama-3.1-8B-Instruct model with GPU acceleration on VM.GPU.A10.2 nodes.                          | [vllm_llama_stack.json](vllm_llama_stack.json) |
| PostgreSQL database backend for Llama Stack data persistence                   | PostgreSQL Database for Llama Stack       | Deploys a PostgreSQL database instance that serves as the primary data store for Llama Stack application state and metadata.                                 | [postgres_db.json](postgres_db.json)           |
| ChromaDB vector database for retrieval-augmented generation (RAG) capabilities | ChromaDB Vector Database                  | Deploys ChromaDB vector database with persistent storage for embedding storage and similarity search in RAG workflows.                                       | [chroma_db.json](chroma_db.json)               |
| Jaeger distributed tracing for observability and telemetry                     | Jaeger Tracing Service                    | Deploys Jaeger for distributed tracing and telemetry collection to monitor and debug Llama Stack operations.                                                 | [jaegar.json](jaegar.json)                     |
| Main Llama Stack application that orchestrates all components                  | Llama Stack Main Application              | Deploys the main Llama Stack application that connects to vLLM, PostgreSQL, ChromaDB, and Jaeger to provide a unified API for inference, RAG, and telemetry. | [llamastack.json](llamastack.json)             |

---

# In-Depth Feature Overview

## What is Llama Stack?

Llama Stack standardizes the core building blocks that simplify AI-application development:

- **Unified API layer** – inference, RAG, agents, tools, safety, evals, telemetry
- **Plugin architecture** – swap any backend (vector store, tracing sink, etc.)
- **Verified distributions** – single container images for easy rollout
- **Multiple developer interfaces** – CLI and SDKs for Python, TS, iOS, Android
- **End-to-end reference apps** – blueprints for production-grade workloads

See the upstream project for full details: (https://github.com/meta-llama/llama-stack)[https://github.com/meta-llama/llama-stack]

## Installation Notes

Make sure to have two object storage buckets created in the same compartment that OCI AI Blueprints is deployed into named `chromadb` and `llamastack`.

When deploying the llama-stack pre-filled sample, make sure that you update the deployment name and model name in the environment variables if you are not using the exact pre-filled samples in this blueprint:

- if you named your chroma_db deployment "helloWorld", then the `CHROMADB_URL` environment variable would be `http://recipe-helloWorld.default.svc.cluster.local` (The pattern is `http://recipe-<deployment_name>.default.svc.cluster.local`)

- if you named your postgres_db deployment "fooBar", then `POSTGRES_HOST` environment variable would be `recipe-fooBar.default.svc.cluster.local` (The pattern is `http://recipe-<deployment_name>.default.svc.cluster.local`)

- Make sure to change the model to the one you used in your vllm instance, the environment variable is INFERENCE_MODEL. In the example, we are using `NousResearch/Meta-Llama-3.1-8B-Instruct`

- Make sure to keep the ports as is, for example in your postgres deployment, make sure to leave the `recipe_container_port` set to `5432` and `recipe_host_port` to `5432` as llamastack is specifically looking for postgres to be on these ports. The same is for jaegar being on `4318` at the endpoint `/jaegar`. And lastly chromadb `recipe_container_port` needs to be set to `8000` and `recipe_host_port` to `8000`. Your llamastack deployment will fail if you do not use these ports.

## Verify Installation

To test your llama stack implementation please follow the steps below.

1. Set an environment variable for OPENAI_API_KEY to a dummy value (`export OPENAI_API_KEY="dummy-key"`)

2. Install uv command line interface tool via the steps [here](https://docs.astral.sh/uv/getting-started/installation/)

3. Clone the following repo: [https://github.com/meta-llama/llama-stack-evals](https://github.com/meta-llama/llama-stack-evals)

4. Go to your llama-stack deployment and grab the `Public Endpoint` (ex: `llamastack-app7.129-213-194-241.nip.io`)

5. Run the following curl command to test the model list feature: `curl http://<llama_stack_deployment_endpoint>/v1/openai/v1/models`

6. You can use llama-stack-evals repo (which you previously cloned) to run verifications / benchmark evaluations against this llama stack deployments’s OpenAI endpoint.

```
cd llama-stack-evals # make sure you are in the llama-stack-evals repo

uvx llama-stack-evals run-tests --openai-compat-endpoint http://<llama_stack_deployment_endpoint>/v1/openai/v1 --model "<MODEL_YOU_USED_IN_VLLM_DEPLOYMENT>"

# ex: uvx llama-stack-evals run-tests --openai-compat-endpoint http://llamastack-app7.129-213-194-241.nip.io/v1/openai/v1 --model "/models/NousResearch/Meta-Llama-3.1-8B-Instruct"
```

## How to Use It

Llama Stack has many different use cases and are thoroughly detailed here, in the following tutorial: [https://llama-stack.readthedocs.io/en/latest/getting_started/detailed_tutorial.html](https://llama-stack.readthedocs.io/en/latest/getting_started/detailed_tutorial.html)

## FAQs

1. How can I configure the vLLM pre-filled sample (e.g. I want to deploy a different model with vLLM; a custom model)?

- Any vLLM inference server and model that is compatible with vLLM will work with the Llama Stack implementation. Follow our [llm_inference_with_vllm blueprint](../llm_inference_with_vllm/README.md) for more details on setting up vLLM.

2. Can I use a different inference engine than vLLM?

- At this time, we have only tested vLLM as the inference engine for Llama Stack. vLLM is an OpenAI compatible server so in theory any inference engine that follows the same OpenAI API spec should work as well, but again this has not been tested by our team.

3. How do I use the Llama Stack deployment after I deploy it?
   Please refer to the [how to use it section](#how-to-use-it) above.
