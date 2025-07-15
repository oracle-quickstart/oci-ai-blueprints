# Using Secrets with NVIDIA NIM

[NVIDIA NIM](https://developer.nvidia.com/nim?sortBy=developer_learning_library%2Fsort%2Ffeatured_in.nim%3Adesc%2Ctitle%3Aasc&hitsPerPage=12) provides containers to self-host GPU-accelerated inferencing microservices for pretrained or customized AI models and integrates seamlessly with OCI AI Blueprints.

To use NIM, you must first [generate your API key](https://docs.nvidia.com/ngc/gpu-cloud/ngc-user-guide/index.html#generating-api-key) which will be used as a secret by Blueprints. Once you have your API key generated, you are ready to use NIM in Blueprints.

### Using NIM

First, store your ngc-api key by posting [the following json](./nim_secret.json) to the `/secrets/` endpoint of your assigned API endpoint (e.g. https://api.<ip>.nip.io from your stack after deployment). Substitute your actual ngc-api key for both the "password" in the `container_registry` secret, and the `"NGC_API_KEY"` in the `opaque` secret.

You should get two success messages after you post the keys, and the secrets should show in your API console at `/secrets` like:

```
...
{
        "name": "ngc-api-secret",
        "namespace": "default",
        "type": "Opaque",
        "data_keys": [
            "NGC_API_KEY"
        ],
        "creation_timestamp": "2025-07-11 07:46 AM UTC"
    },
    {
        "name": "ngc-secret",
        "namespace": "default",
        "type": "kubernetes.io/dockerconfigjson",
        "data_keys": [
            ".dockerconfigjson"
        ],
        "creation_timestamp": "2025-07-11 07:53 AM UTC"
    },
...
```
Now, they are usable inside a blueprint.

At this point, using the NIM is simple. Paste the [the following blueprint](./nim_inference.json) to serve llama-3.2-3b-instruct on a VM.GPU.A10.1 shape to test it out. This will serve the model over an OPENAI_API compatible endpoint, meaning we can interact with it via the /v1/chat/completions extension of the url.

Once the inference is endpoint is setup, try it out by getting your assigned service endpoint which will be `http://nim.<ip>.nip.io/` and subtituting it in the below curl. A real example as been provided for you:

```bash
curl -Lk -X 'POST' \
  'http://nim.130-162-248-86.nip.io/v1/chat/completions' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta/llama-3.2-3b-instruct",
    "messages": [
      {
        "role":"user",
        "content":"Hello! How are you?"
      },
      {
        "role":"assistant",
        "content":"Hi! I am quite well, how can I help you today?"
      },
      {
        "role":"user",
        "content":"Can you write me a song?"
      }
    ],
    "top_p": 1,
    "n": 1,
    "max_tokens": 100,
    "stream": false,
    "frequency_penalty": 1.0,
    "stop": ["hello"]
  }' | jq
```

Which responds:
```json
{
  "id": "chat-221b08c67fcb43d4bd14251c921e614e",
  "object": "chat.completion",
  "created": 1752577471,
  "model": "meta/llama-3.2-3b-instruct",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I'd be happy to write a song for you. Can you give me some details about the type of song you'd like?\n\n* What genre is it (e.g., pop, rock, country)?\n* Is there a specific theme or topic (e.g., love, heartbreak, childhood memories)?\n* Do you want the song to have a fast tempo or a slow one?\n* Are there any specific instruments or sounds that feature prominently in your ideal song?\n* Would you like me to come"
      },
      "logprobs": null,
      "finish_reason": "length",
      "stop_reason": null
    }
  ],
  "usage": {
    "prompt_tokens": 72,
    "total_tokens": 172,
    "completion_tokens": 100
  },
  "prompt_logprobs": null
}
```

