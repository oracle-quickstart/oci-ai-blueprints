# Secrets in AI Blueprints

This README is split into two parts:

  1. [Listing, Creating, Updating, and Deleting Secrets with the `/secrets` API endpoint](./README.md#listing-creating-updating-and-deleting-secrets-with-the-secrets-api-endpoint)
  2. [Using secrets in blueprints](./README.md#using-secrets-in-blueprints)

Secrets enable users to store confidential access in kubernetes without needing to frequently expose them in blueprints, leading to more secure deployments.

 Currently, two types of secrets are supported:

  - `opaque`: general secrets such as API keys, huggingface tokens, which allow users to provide any key / value pair for access
  - `container_registry`: structured secrets for accessing private container registries for private containers to deploy to blueprints, such as private OCI container registries, NVIDIA NGC for NIMs, or Docker.

In the sections below, we will show you how to both create and use these secrets in Blueprints.

#### Listing, Creating, Updating, and Deleting Secrets with the `/secrets` API endpoint

This API allows users to list, create, update, or delete stored secrets in blueprints. The [schema](./secrest_schema.json) is included for reference.

To see valid API calls for `GET` requests, visit [api docs](../../api_documentation.md#list-all-secrets).

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





#### Using secrets in blueprints