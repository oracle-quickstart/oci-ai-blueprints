# Using Secrets with Huggingface

[Huggingface](https://huggingface.co) is an model and dataset repository for accessing open model weights and datasets. Sometimes, model providers like Meta require a signed user agreement to use their models which in turn requires a user to generate a [user access token](https://huggingface.co/docs/hub/en/security-tokens) to download models.

Since tokens are unique to a user's account, we recommend storing them as secrets to be used in Blueprints.

### Using hf-tokens as secrets

After your secret is generated, store it by posting [the following json](./hf-token-secret.json) to the `/secrets/` endpoint of your assigned API endpoint (e.g. https://api.<ip>.nip.io from your stack after deployment). Substitute your actual hf-token in the `"hf-token"` field in the data.

You should get two success messages after you post secret:
```json
{
    "operations_processed": 1,
    "results": [
        {
            "action": "create",
            "name": "hf-secret",
            "namespace": "default",
            "status": "success",
            "message": "Secret 'hf-secret' created successfully"
        }
    ]
}
```

And the secret should show in your API console at `/secrets` like:
```json
...
    {
        "name": "hf-secret",
        "namespace": "default",
        "type": "Opaque",
        "data_keys": [
            "hf-token"
        ],
        "creation_timestamp": "2025-07-15 11:39 AM UTC"
    },
...
```
This is now usable in Blueprints.

As an example, [the following recipe](./vllm_from_hf.json) will pull the meta-llama/Llama-3.2-1B-Instruct model from huggingface using the secret token we stored in the previous step. This recipe will:

1. Start a container with vLLM
2. Use the environment variable [$HF_TOKEN](https://huggingface.co/docs/huggingface_hub/en/package_reference/environment_variables#hftoken) to validate access to the model repo, which I was approved for ahead of time. This model access is on a per-token basis, so you must have access to the model repo with the associated token.
    - Note: This will not work if the HF_TOKEN associated with your account has not been granted access to the Llama-3.2 repo. 
3. This will allow vLLM to download the model directly, and then serve it over the ingress that Blueprints provides.

Once the inference is endpoint is setup, try it out by getting your assigned service endpoint which will be `http://vllm-from-hf.<ip>.nip.io/` and subtituting it in the below curl. A real example as been provided for you:
```bash
curl -Lk -X 'POST' \
  'http://vllm-from-hf.130-162-248-86.nip.io/v1/chat/completions' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.2-1B-Instruct",
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
  "id": "chatcmpl-b2bb41df3138408493f90a6223cd5ab2",
  "object": "chat.completion",
  "created": 1752595251,
  "model": "meta-llama/Llama-3.2-1B-Instruct",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "reasoning_content": null,
        "content": "I can try to write a song for you. Here's a short song I came up with:\n\n**Title:** \"Lost in the Moment\"\n\n**Verse 1:**\nI see the world through different eyes\nA kaleidoscope of colors, a symphony of surprise\nThe city lights, they whisper my name\nAnd I'm drawn to the rhythm of the flame\n\n**Chorus:**\nWe're lost in the moment, our hearts beating as one\nIn this dark and endless night",
        "tool_calls": []
      },
      "logprobs": null,
      "finish_reason": "length",
      "stop_reason": null
    }
  ],
  "usage": {
    "prompt_tokens": 72,
    "total_tokens": 172,
    "completion_tokens": 100,
    "prompt_tokens_details": null
  },
  "prompt_logprobs": null,
  "kv_transfer_params": null
}
```
