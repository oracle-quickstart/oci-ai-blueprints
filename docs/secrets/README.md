# Secrets in AI Blueprints

Secrets enable users to store confidential access in kubernetes without needing to frequently expose them in blueprints, leading to more secure deployments.

 Currently, two types of secrets are supported:

  - `opaque`: general secrets such as API keys, huggingface tokens, which allow users to provide any key / value pair for access
  - `container_registry`: structured secrets for accessing private container registries for private containers to deploy to blueprints, such as private OCI container registries, NVIDIA NGC for NIMs, or Docker.

### Listing, Creating, Updating, and Deleting Secrets with the `/secrets` API endpoint

This API allows users to list, create, update, or delete stored secrets in blueprints. The [schema](./secrest_schema.json) is included for reference.

To see valid API calls for `GET` requests, visit [api docs](../api_documentation.md#list-all-secrets).

`POST` requests to create, update, or delete secrets are described in the table below. Post requests can perform batch operations, with statuses reported for each.

1. Trying to `create` a token which exists will fail
2. Trying to `update` a token which doesn't exist will fail
3. Trying to `delete` a token which doesn't exist will fail

For `opaque` secrets, multiple data keys can exist within a single secret under distinct `key:value` pairs as will be shown in the example table below.

| Mode   | Secret Type   | Example Payload | Response |
| :--:   | :---------:   | :-------------: | :------: |
| `create` | `opaque`    | [create-opaque-secret](./example_opaque_create.json) | `400 BAD REQUEST` for fail or `200 OK` for success |
| `update` | `opaque`    | [update-opaque-secret](./example_opaque_update.json) | `400 BAD REQUEST` for fail or `200 OK` for success |
| `delete` | `opaque`    | [delete-opaque-secret](./example_opaque_delete.json) | `400 BAD REQUEST` for fail or `200 OK` for success |
| `create` | `container_registry` | [create-registry-secret](./example_registry_create.json) | `400 BAD REQUEST` for fail or `200 OK` for success |
| `update` | `container_registry` | [update-registry-secret](./example_registry_update.json) | `400 BAD REQUEST` for fail or `200 OK` for success |
| `delete` | `container_registry` | [delete-registry-secret](./example_registry_delete.json) | `400 BAD REQUEST` for fail or `200 OK` for success |

### Using secrets in Blueprints

Secrets leverage two different blueprint recipe keys depending on the type:

 - `recipe_container_secret_name` (string) -> The name of the container_registry secret where the credentials were stored (e.g "iad-creds" in the [create-registry-secret](./example_registry_create.json))
 - `recipe_environment_secrets` (array[object]) -> An array of objects containing the 3 fields which stores the value of the secret key in the container at the specified environment variable name:
   - `"envvar_name"`: the name of the environment variable the secret should map to
   - `"secret_name"`: the name of the secret which contains the key:value pair
   - `"secret_key"`: the key containing the value you want to use

As an example using a huggingface token, you would store the secret like:

```json
{
    "secrets_payload": [
      {
        "name": "hf-secret",
        "action": "create", 
        "type": "opaque",
        "data": {
          "hf-token": "hf_...<example-token>..."
        }
      }
    ]
}
```

Then, to use it in a blueprint as an environment variable and an argument:
```json
...
"recipe_environment_secrets": [
  {
    "envvar_name": "HF_TOKEN",
    "secret_name": "hf-secret",
    "secret_key": "hf-token"
  }
],
"recipe_container_command_args": [
    "--token",
    "$(HF_TOKEN)",
    ...
]
...
```

### Secrets workflows

The following four examples show common workflows utilizing secrets in different ways:

  - [Using Secrets with NVIDIA NIMs](./using_secrets_with_nvidia_nim.md)
  - [Using Secrets with Huggingface](./using_secrets_with_huggingface.md)
  - [Using Secrets with Docker](./using_secrets_with_docker.md)
  - [Using Secrets with Oracle Container Registry](./using_secrets_with_oracle_container_registry.md)

