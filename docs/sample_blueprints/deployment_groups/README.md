# Deployment Groups

#### Connected multi-container deployments in a single blueprint

Deployment Groups let you spin up several deployments — each derived from its own blueprint — in a single `POST /deployment` request and treat them as one cohesive application. OCI AI Blueprints automatically sequences those member deployments according to the depends_on relationships you declare, publishes each deployment’s outputs (such as service URLs or internal dns name) for easy discovery, and then injects those outputs wherever you reference the placeholder `${deployment_name.export_key}` inside downstream blueprints. What once required a series of separate API calls stitched together with hard-coded endpoints can now be expressed declaratively in one step, with OCI AI Blueprints resolving every cross-service connection at runtime.

## Pre-Filled Samples

| Feature Showcase                                                                    | Title                                   | Description                                                                                                                                                                                                                                                                                                                                                   | Blueprint File                                   |
| ----------------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| Create multiple deployments using deployment groups using Llama Stack as an example | Deployment Groups Showcase: Llama Stack | Deploys Postgres, ChromaDB, vLLM and Jaegar as separate deployments at once and waits until those deployments have been successfully deployed before deploying the Llama Stack deployment that depends on the initial deployments. We are also using export variables from the Postgres, ChromaDB, vLLM and Jaegar deployments in the Llama Stack deployment. | [llama_stack_basic.json](llama_stack_basic.json) |

---

# In-Depth Feature Overview

## What Are Deployment Groups?

Deployment Groups is a powerful feature that allows you to deploy multiple interconnected containers as a single logical application. Instead of managing individual deployments separately, you can define complex multi-service applications with automatic dependency management, service discovery, and dynamic value injection between components.

## Key Features

### 1. **Dependency Management**

- Define dependencies between sub-deployments using `depends_on`
- Automatic topological sorting ensures correct deployment order
- Circular dependency detection prevents invalid configurations
- Dependent services wait for their dependencies to be ready

### 2. **Service Discovery & Value Injection**

- Sub-deployments can export values (service URLs, internal DNS names, etc.)
- Reference values from other deployments dynamically using `${deployment_name.export_var_name}` syntax (e.g., `${database.internal_dns_name}` automatically becomes the actual internal dns name from the "database" sub_deployment when deployed)
- Dynamic value resolution at deployment time
- Works in any blueprint field: image URIs, ports, environment variables, command args, etc.

### 3. **Unified Management**

- Deploy multiple services (blueprints) with a single POST /deployment API call
- Group-level operations for deployment, monitoring, and cleanup
- Consistent lifecycle management across all components

### 4. **Backward Compatibility**

- Existing single deployments continue to work unchanged
- Same API endpoints (`/deployment`) for both single deployments and deployment groups
- No breaking changes to current workflows

## API Endpoints

### Main Endpoints

| Endpoint                  | Method | Description                                           |
| ------------------------- | ------ | ----------------------------------------------------- |
| `/deployment`             | POST   | Create single deployment OR deployment group          |
| `/deployment_groups`      | GET    | List all deployment groups                            |
| `/deployment_groups/{id}` | GET    | Get specific deployment group details                 |
| `/undeploy`               | POST   | Undeploy single deployment OR entire deployment group |

### Deployment Groups API Response

**List Deployment Groups** (`GET /deployment_groups`)

```json
{
  "deployment_groups": [
    {
      "deployment_group_id": "abc123",
      "deployment_group_name": "llama-stack",
      "creation_date": "2025-01-15 14:30:00 UTC",
      "deployments": [
        {
          "mode": "service",
          "recipe_id": "postgres",
          "deployment_uuid": "def456",
          "deployment_name": "postgres-llama-stack",
          "sub_deployment_name": "postgres",
          "deployment_status": "monitoring",
          "creation_date": "2025-01-15 14:30:00 UTC"
        },
        {
          "mode": "service",
          "recipe_id": "vllm",
          "deployment_uuid": "ghi789",
          "deployment_name": "vllm-llama-stack",
          "sub_deployment_name": "vllm",
          "deployment_status": "monitoring",
          "creation_date": "2025-01-15 14:31:00 UTC"
        }
      ]
    }
  ]
}
```

**Get Specific Deployment Group** (`GET /deployment_groups/{id}`)

```json
{
  "deployment_group_id": "abc123",
  "deployment_group_name": "llama-stack",
  "creation_date": "2025-01-15 14:30:00 UTC",
  "deployments": [
    {
      "mode": "service",
      "recipe_id": "postgres",
      "deployment_uuid": "def456",
      "deployment_name": "postgres-llama-stack",
      "sub_deployment_name": "postgres",
      "deployment_status": "monitoring",
      "creation_date": "2025-01-15 14:30:00 UTC"
    }
  ]
}
```

## Schema Structure

### Deployment Group Schema

```json
{
  "deployment_group": {
    "name": "string",
    "deployments": [
      {
        "name": "string",
        "recipe": {
          // Standard recipe configuration
          "deployment_name": "string",
          "recipe_mode": "service|job|update|shared_node_pool|team"
          // ... all other recipe fields
        },
        "depends_on": ["string"], // Optional: names of dependencies
        "exports": ["string"] // Optional: values to export
      }
    ]
  }
}
```

### Available Export Types

- `service_url` - Public endpoint (load balancer URL)
- `internal_dns_name` - Cluster-internal DNS record for service-to-service communication

## How It Works

### 1. Deployment Creation

When you submit a deployment group, the system:

1. **Validates** the configuration and checks for circular dependencies
2. **Parses** sub-deployments and resolves dependency order
3. **Creates** individual deployments with unique names
4. **Schedules** deployments based on dependency relationships

### 2. Dependency Resolution

- Sub-deployments without dependencies start immediately
- Dependent sub-deployments wait in `SCHEDULED` state
- As dependencies reach `MONITORING` state, dependent deployments activate
- Automatic retry logic handles temporary export collection failures

### 3. Value Injection

- When a sub-deployment becomes ready, its exports are collected
- Placeholders like `${postgres.internal_dns_name}` are resolved
- Recipe configurations are updated with actual values
- Dependent deployments deploy with resolved configurations

## Real-World Example: LLaMA Stack Application

An example can be found here: [llama-stack_blueprint](llama_stack_basic.json)

### What Happens During LLaMA Stack Blueprint Deployment:

1. **Postgres deploys first** (no dependencies)

   - Exports: `internal_dns_name: "postgres-llama-stack.default.svc.cluster.local"`

2. **vLLM deploys second** (no dependencies)

   - Exports: `internal_dns_name: "vllm-llama-stack.default.svc.cluster.local"`

3. **ChromaDB deploys third** (no dependencies)

   - Exports: `internal_dns_name: "chroma-llama-stack.default.svc.cluster.local"`

4. **Jager deploys fourth** (no dependencies)

   - Exports: `internal_dns_name: "jaeger-llama-stack.default.svc.cluster.local"`

5. **LLaMA Stack App deploys last** (depends on postgres, vllm, chromadb and jager deployments)
   - Environment variables get resolved:
     - `VLLM_URL: "http://vllm-llama-stack.default.svc.cluster.local/v1"`
     - `POSTGRES_HOST: "postgres-llama-stack.default.svc.cluster.local"`
     - `CHROMADB_URL: "http://chroma-llama-stack.default.svc.cluster.local:8000"`
     - `OTEL_TRACE_ENDPOINT: "http://jaeger-llama-stack.default.svc.cluster.local/jaeger/v1/traces"`

## Advanced Features

### 1. **Flexible Value Injection**

The `${sub_deployment.export}` syntax works in any blueprint field:

```json
{
  "name": "api-service",
  "depends_on": ["database", "config"],
  "recipe": {
    "recipe_image_uri": "registry.com/${config.app_version}/api",
    "recipe_container_port": "${config.port}",
    "recipe_container_command_args": [
      "--database-url",
      "${database.internal_dns_name}",
      "--config-endpoint",
      "${config.service_url}"
    ],
    "recipe_container_env": [
      { "key": "DB_HOST", "value": "${database.internal_dns_name}" },
      { "key": "CONFIG_URL", "value": "${config.service_url}" }
    ]
  }
}
```

### 2. **Group-Level Operations**

**Undeploy Entire Group:**

```bash
POST /undeploy
{
  "deployment_group_id": "abc123"
}
```

- Undeploys all sub-deployments in reverse dependency order
- Ensures dependents are removed before their dependencies

**Monitor Group Status:**

```bash
GET /deployment_groups/abc123
```

- Shows status of all sub-deployments
- Tracks deployment progress and any issues

### 3. **Error Handling & Resilience**

The system includes robust error handling:

- **Export Collection Failures**: If a service isn't ready to export values, dependent deployments wait for the next processing cycle
- **Dependency Validation**: Circular dependencies and missing references are caught during validation
- **Graceful Degradation**: Recipe properties are still available even if export collection fails

### 4. **Validation Features**

Built-in validation ensures:

- No circular dependencies
- All dependencies exist in the group
- Required exports are declared
- Proper schema compliance
- Unique sub-deployment names

## Migration Guide

### From Single Recipes to Deployment Groups

**Before (Multiple API calls):**

```bash
# Deploy database
POST /deployment
{"recipe_mode": "service", "deployment_name": "my-db", ...}

# Deploy API (manually specify database URL)
POST /deployment
{"recipe_mode": "service", "deployment_name": "my-api",
 "recipe_container_env": [{"key": "DB_URL", "value": "hardcoded-url"}]}
```

**After (Single API call):**

```bash
POST /deployment
{
  "deployment_group": {
    "name": "my-app",
    "deployments": [
      {
        "name": "database",
        "recipe": {"deployment_name": "my-db", ...},
        "exports": ["internal_dns_name"]
      },
      {
        "name": "api",
        "depends_on": ["database"],
        "recipe": {
          "deployment_name": "my-api",
          "recipe_container_env": [
            {"key": "DB_URL", "value": "${database.internal_dns_name}"}
          ]
        }
      }
    ]
  }
}
```

## Best Practices

1. **Use Meaningful Names**: Choose descriptive names for sub-deployments
2. **Minimize Dependencies**: Keep coupling between services as loose as possible
3. **Export Only What's Needed**: Only export values that other services actually use
4. **Plan Deployment Order**: Consider the logical deployment sequence when designing dependencies
5. **Handle Failures Gracefully**: Design services to handle temporary unavailability of dependencies
6. **Use Internal DNS**: Prefer `internal_dns_name` over `service_url` for service-to-service communication
7. **Group Related Services**: Keep logically related services together in the same deployment group

## Troubleshooting

### Common Issues:

1. **"Circular dependency detected"**

   - Check your `depends_on` relationships for cycles
   - Ensure no sub-deployment depends on itself directly or indirectly

2. **"Missing dependency"**

   - Verify all names in `depends_on` match actual sub-deployment names
   - Check for typos in dependency names

3. **"Export not available"**

   - Ensure the exporting service declares the export in its `exports` array
   - Check that the service is in `MONITORING` state
   - Verify the export type is supported (`service_url`, `internal_dns_name`)

4. **"Dependencies not satisfied"**
   - Check the status of dependency services
   - Look for any failures in the dependency chain
   - Review sub_deployment logs for export collection errors

### Monitoring Deployment Groups:

Use the deployment groups API to monitor progress:

```bash
GET /deployment_groups/{id}
```

Look for:

- Sub-deployment statuses (`scheduled`, `active`, `monitoring`, `failed`)
- Creation timestamps to track deployment progress
- Any sub-deployments stuck in `scheduled` state (indicates dependency issues)

The Deployment Groups feature transforms complex multi-service applications from a manual orchestration challenge into a declarative, automated deployment experience while maintaining full backward compatibility with existing workflows.
