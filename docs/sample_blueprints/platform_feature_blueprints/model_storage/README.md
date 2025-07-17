# Model Storage

#### Download and store models from HuggingFace to OCI Object Storage for efficient blueprint deployment

Model storage is a critical component for AI/ML workloads, providing efficient access to large language models and other AI assets. OCI AI Blueprints supports storing models in OCI Object Storage, which offers faster loading times and better resource management compared to downloading models directly from HuggingFace during container startup.

This blueprint provides automated workflows to download models from HuggingFace (both open and gated models) and store them in OCI Object Storage buckets. Once stored, these models can be efficiently accessed by inference blueprints through pre-authenticated requests (PARs) or direct bucket access, significantly reducing deployment times and improving reliability.

The system supports both open-source models that require no authentication and closed/gated models that require HuggingFace tokens for access. Models are downloaded using optimized parallel workers and stored with appropriate volume sizing to accommodate large model files.

## Pre-Filled Samples

| Feature Showcase                                                                    | Title                                               | Description                                                                                                                                                           | Blueprint File                                                                                     |
| ----------------------------------------------------------------------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Download gated HuggingFace models requiring authentication tokens to Object Storage | Download Closed HuggingFace Model to Object Storage | Downloads gated/closed HuggingFace models that require authentication tokens and stores them in OCI Object Storage for efficient access by inference blueprints.      | [download_closed_hf_model_to_object_storage.json](download_closed_hf_model_to_object_storage.json) |
| Download open-source HuggingFace models without authentication to Object Storage    | Download Open HuggingFace Model to Object Storage   | Downloads open-source HuggingFace models without requiring authentication and stores them in OCI Object Storage with optimized parallel downloading for large models. | [download_open_hf_model_to_object_storage.json](download_open_hf_model_to_object_storage.json)     |

---

# In-Depth Feature Overview

You have two options to store your model so that a blueprint has access to it:

## Option 1: Object Storage

OCI AI Blueprints will automatically create an ephemeral volume, mount it to the container and download the contents of your object storage bucket.

### How To

**Step 1 [OPTIONAL]**:

If serving large models from huggingface, it is recommended to first download them to object storage because they are loaded much more quickly from object storage than via python applications which build in the ability to pull them.

To download a model from huggingface to object storage, check out [this doc](../../../common_workflows/working_with_large_models/README.md).

**Step 2:**

You can host your model via object storage by:

1. Creating a PAR for the bucket that contains your model (`par` in the example below)
2. Specifying the mount location or the directory where the application inside the container will be expecting your model to be (`mount_location` in the example below)
3. The volume size for the ephermal volume: where your object storage contents will be downloaded into - so make sure the volume is large enough (`volume_size_in_gbs` in the example below)
4. The specific folder inside the object storage bucket to download - if this is not specified, the entire object storage bucket will be downloaded to the ephemeral volume (`include` in the example below)

Include the `input_object_storage` JSON object in your deployment payload (`/deployment` POST API):

```json
"input_object_storage": [
	{
		"par": "https://objectstorage.us-ashburn-1.oraclecloud.com/p/IFknABDAjiiF5LATogUbRCcVQ9KL6aFUC1j-P5NSeUcaB2lntXLaR935rxa-E-u1/n/iduyx1qnmway/b/corrino_hf_oss_models/o/",
		"mount_location": "/models",
		"volume_size_in_gbs": 500,
		"include": ["NousResearch/Meta-Llama-3.1-8B-Instruct"]
	}
],
```

Notes:

- You will need to create a PAR for the model in your object storage bucket and pass it in as shown above
- On the backend, OCI AI Blueprints creates an ephemeral volume and mounts it to the mount location directory inside the container
- The mount location is the directory inside the container that the contents of the bucket will be dumped into
- The application running inside the container will access the model from the `/models` directory (using the example above - but the directory can be renamed as you see fit)
- The application running inside the container will access the model from the /models directory (again, using the example from above)
- `include` field inside the `input_object_storage` object inside your payload (shown above) is used to specify which folder inside the bucket to download to the ephemeral volume (that the container has access to via the mount_location directory
- The entire bucket will be dumped into the ephermal volume / container mount directory if include is not provided to specify the folder inside the folder to download
