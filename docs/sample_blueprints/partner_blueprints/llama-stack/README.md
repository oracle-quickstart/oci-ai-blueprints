# Llama Stack on OCI

#### Pre-packaged GenAI runtime — vLLM + ChromaDB + Postgres (optional Jaeger) ready for one-click deployment

Deploy Llama Stack on OCI via OCI AI Blueprints. For more information on Llama Stack: https://github.com/meta-llama/llama-stack

We are using Postgres for the backend store, chromaDB for the vector database, Jaeger for tracing and vLLM for inference serving.

## Pre-Filled Samples

| Feature Showcase                     | Title                        | Description                                                                                                                                                            | Blueprint File                                   |
| ------------------------------------ | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| Full Llama Stack Basic Configuration | Llama 3.1 8B Model with vLLM | Deploys a Llama Stack on OCI AI Blueprints with Postgres, ChromaDB, vLLM and Jaegar. Uses Llama 3.1 8B model on one A10 VM to showcase the usage of LLama Stack on OCI | [llama_stack_basic.json](llama_stack_basic.json) |

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

-- Set `INFERENCE_MODEL` to the model name your vLLM server exposes. If you launched vLLM with `--served-model-name` (which is what is done in the vllm pre-filled sample here), use that value; otherwise, use the value passed to --model (vllm defaults to this value when `--served-model-name` is omitted). In this example, the value for `INFERENCE_MODEL` is `NousResearch/Meta-Llama-3.1-8B-Instruct`.

- Make sure to keep the ports as is, for example in your postgres deployment, make sure to leave the `recipe_container_port` set to `5432` and `recipe_host_port` to `5432` as llamastack is specifically looking for postgres to be on these ports. The same is for jaegar being on `4318` at the endpoint `/jaegar`. And lastly chromadb `recipe_container_port` needs to be set to `8000` and `recipe_host_port` to `8000`. Your llamastack deployment will fail if you do not use these ports.

## Verify Installation

To test your llama stack implementation please follow the steps below.

1. Set an environment variable for OPENAI_API_KEY to a dummy value (`export OPENAI_API_KEY="dummy-key"`)

2. Install uv command line interface tool via the steps [here](https://docs.astral.sh/uv/getting-started/installation/)

3. Clone the following repo: [https://github.com/meta-llama/llama-stack-evals](https://github.com/meta-llama/llama-stack-evals)

4. Go to your llama-stack deployment and grab the `Public Endpoint` (ex: `llamastack-app7.129-213-194-241.nip.io`)

5. Run the following curl command to test the model list feature: `curl http://<llama_stack_deployment_endpoint>/v1/openai/v1/models`

6. You can use llama-stack-evals repo (which you previously cloned) to run verifications / benchmark evaluations against this llama stack deployments’s OpenAI endpoint. Note: If you are using the blueprint unmodified (aka using the NousResearch/Meta-Llama-3.1-8B-Instruct model, some of the tests will fail on purpose since this tests multi-modal inputs which this model does not support)

```
cd llama-stack-evals # make sure you are in the llama-stack-evals repo

uvx llama-stack-evals run-tests --openai-compat-endpoint http://<llama_stack_deployment_endpoint>/v1/openai/v1 --model "<MODEL_YOU_USED_IN_VLLM_DEPLOYMENT>"

# ex: uvx llama-stack-evals run-tests --openai-compat-endpoint http://llamastack-app7.129-213-194-241.nip.io/v1/openai/v1 --model "NousResearch/Meta-Llama-3.1-8B-Instruct"
```

## How to Use It

Llama Stack has many different use cases and are thoroughly detailed here, in the following tutorial: [https://llama-stack.readthedocs.io/en/latest/getting_started/detailed_tutorial.html](https://llama-stack.readthedocs.io/en/latest/getting_started/detailed_tutorial.html)

## FAQs

1. How can I configure the vLLM pre-filled sample (e.g. I want to deploy a different model with vLLM; a custom model)?

- Any vLLM inference server and model that is compatible with vLLM will work with the Llama Stack implementation. Follow our [llm_inference_with_vllm blueprint](../../model_serving/llm_inference_with_vllm/README.md) for more details on setting up vLLM.

2. Can I use a different inference engine than vLLM?

- At this time, we have only tested vLLM as the inference engine for Llama Stack. vLLM is an OpenAI compatible server so in theory any inference engine that follows the same OpenAI API spec should work as well, but again this has not been tested by our team.

3. How do I use the Llama Stack deployment after I deploy it?
   Please refer to the [how to use it section](#how-to-use-it) above.
