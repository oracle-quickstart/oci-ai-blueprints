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

## Notes

Make sure to have two object storage buckets created in the same compartment that OCI AI Blueprints is deployed into named `chromadb` and `llamastack`.

When deploying the llama-stack pre-filled sample, make sure that you update the deployment name and model name in the environment variables if you are not using the exact pre-filled samples in this blueprint:

- if you named your chroma_db deployment "helloWorld", then the `CHROMADB_URL` environment variable would be `http://recipe-helloWorld.default.svc.cluster.local` (The pattern is `http://recipe-<deployment_name>.default.svc.cluster.local`)

- if you named your postgres_db deployment "fooBar", then `POSTGRES_HOST` environment variable would be `recipe-fooBar.default.svc.cluster.local` (The pattern is `http://recipe-<deployment_name>.default.svc.cluster.local`)

- Make sure to change the model to the one you used in your vllm instance, the environment variable is INFERENCE_MODEL. In the example, we are using `NousResearch/Meta-Llama-3.1-8B-Instruct`

- Make sure to keep the ports as is, for example in your postgres deployment, make sure to leave the `recipe_container_port` set to `5432` and `recipe_host_port` to `5432` as llamastack is specifically looking for postgres to be on these ports. The same is for jaegar being on `4318` at the endpoint `/jaegar`. And lastly chromadb `recipe_container_port` needs to be set to `8000` and `recipe_host_port` to `8000`. Your llamastack deployment will fail if you do not use these ports.
