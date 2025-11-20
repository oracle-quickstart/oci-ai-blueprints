# Inference Gateway

#### Kong-powered API gateway for AI model inference routing and management

The Inference Gateway is a dedicated Kong-based API gateway that provides unified access, routing, and management capabilities for AI model inference endpoints deployed on the OCI AI Blueprints platform. This gateway serves as a centralized entry point for all inference requests, enabling advanced traffic management, load balancing, and API governance for your AI workloads.

## Pre-Filled Samples

| Feature Showcase                                                                                              | Title                     | Description                                                       | Blueprint File                                           |
| ------------------------------------------------------------------------------------------------------------- | ------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------- |
| Validates use of inference gateway feature set of extended url, model header based routing, and a per-model api-key | Serve OpenAI gpt-oss-120b on H100 GPUs behind inference gateway | Serve gpt-oss-120b model behind inference gateway on 2 NVIDIA H100 GPUs | [example_vllm_gpt_oss_120b.json](./example_vllm_gpt_oss_120b.json) |
| Serve with other Llama-4 Maverick model behind inference gateway on same MI300x to validate header based routing and unique api-keys per model | Serve Llama4-Scout on MI300x GPUs behind inference gateway| Serve Llama-4-Scout-17B-16E-Instruct behind inference gateway on 4 AMD MI300x GPUs with extended url, header based routing, and model api-key | [example_vllm_llama4_scout.json](./example_vllm_llama4_scout.json) |
| Serve with other Llama-4 Scout model behind inference gateway on same MI300x to validate header based routing and unique api-keys per model | Serve Llama4-Maverick on MI300x GPUs behind inference gateway | Serve Llama-4-Maverick-17B-128E-Instruct-FP8 behind inference gateway on 4 AMD MI300x GPUs with extended url, header based routing, and model api-key | [example_vllm_llama4_maverick.json](./example_vllm_llama4_maverick.json) |


# What is the Inference Gateway?

The Inference Gateway leverages Kong Gateway to provide a robust, scalable API management layer specifically designed for AI model inference. It acts as a reverse proxy that sits between client applications and your deployed AI models, offering features like:

- **Unified API Endpoint**: Single point of access for all your deployed AI models
- **Load Balancing**: Intelligent request distribution across multiple model instances
- **Traffic Management**: Rate limiting, request routing, and performance optimization
- **Security**: Authentication, authorization, and API key management
- **Monitoring**: Request logging, metrics collection, and observability
- **Protocol Translation**: Support for various API protocols and formats

## Key Features

### Kong Gateway Integration
- **Version**: Kong Gateway 3.9 with Helm chart version 2.51.0
- **Database-less Mode**: Operates in DB-less mode for simplified deployment and management
- **Kubernetes Native**: Full integration with Kubernetes using Kong Ingress Controller
- **Auto-scaling**: Configured with horizontal pod autoscaling (2-3 replicas, 70% CPU threshold)

### Network Configuration
- **Load Balancer**: OCI flexible load balancer with configurable shapes (10-100 Mbps)
- **Protocol Support**: Both HTTP (port 80) and HTTPS (port 443) endpoints
- **Private Network Support**: Optional private load balancer for secure internal access
- **External Access**: Automatic nip.io domain generation for easy external access

### Resource Management
- **CPU**: 500m requests, 1000m limits per pod
- **Memory**: 512Mi requests, 1Gi limits per pod
- **High Availability**: Multiple replicas with automatic failover
- **Performance Monitoring**: Built-in status endpoints for health checks

## Deployment Options

### Automatic Deployment (Default)
When deploying OCI AI Blueprints, Kong is automatically installed and configured unless explicitly disabled:

```terraform
# Kong is deployed by default
bring_your_own_kong = false  # Default value
```

The system will:
1. Deploy Kong Gateway in the `kong` namespace
2. Configure OCI Load Balancer with flexible shape
3. Set up automatic SSL/TLS termination
4. Generate a publicly accessible URL: `https://<kong-ip>.nip.io`

### Bring Your Own Kong (BYOK)
For existing clusters with Kong already installed:

```terraform
# Use existing Kong installation
bring_your_own_kong = true
existent_kong_namespace = "your-kong-namespace"
```

When using BYOK:
- The platform will not deploy a new Kong instance
- You must configure your existing Kong to route to deployed AI models
- The inference gateway URL will show as disabled in outputs

## Configuration Details

### Service Configuration
The Kong proxy service is configured with:

```yaml
proxy:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "100"
  http:
    servicePort: 80
    containerPort: 8000
  tls:
    servicePort: 443
    containerPort: 8443
```

### Admin Interface
Kong's admin interface is available internally for configuration management:
- **HTTP Admin**: Port 8001 (ClusterIP)
- **HTTPS Admin**: Port 8442 (ClusterIP)
- **Status Endpoint**: Ports 8100/8101 for health monitoring

### Private Network Deployment
For private clusters, the load balancer is automatically configured as internal:

```yaml
proxy:
  annotations:
    service.beta.kubernetes.io/oci-load-balancer-internal: "true"
```

## Usage Examples

### Blueprints API Spec:

To deploy your model behind the unified inference URL with Blueprints, the following API specification is required:

 - `recipe_inference_gateway` (object) - the key required to encapsulate inference gateway features.
   - `model_name` (string) **required** - Model name which will be used as header to identify model behind the gateway - MUST BE UNIQUE per route as routes will fail if 2 models behind the same route share the same model name.
     - Example: `"model_name": "gpt-oss-120b"`
     - Usage: `curl -X POST <gateway url>/v1/chat/completions -H "X-Model: gpt-oss-120b" ...`
   - `url_path` (string) **optional** - additional url path to add to gateway for this serving deployment
     - Example: `"url_path": "/ai/models"`
     - Usage: `curl -X POST http://10-76-0-10/ai/models/v1/chat/completions ...`
   - `api_key` (string) **optional** - api key to use for this model in the inference gateway - MUST BE UNIQUE as these cannot be reused across models
     - Example: `"api_key": "123abc456ABC"`
     - Usage: `curl -X POST <gateway url>/v1/chat/completions -H "apikey: 123abc456ABC" ...`

**Minimum Requirement**:

```json
    ...
    "recipe_inference_gateway": {
        "model_name": "gpt-oss-120b"
    }
    ...
```

**All options enabled**
```json
   ...
   "recipe_inference_gateway": {
        "model_name": "gpt-oss-120b",
        "url_path": "/ai/models",
        "api_key": "123abc456ABC"
   }
   ...
```

## Example Blueprints Table

| Blueprint Name | Model | Shape | Description |
| :------------: | :---: | :---: | :---------: |
| [vLLM OpenAI/gpt-oss-120b H100](./example_vllm_gpt_oss_120b.json) | [openai/gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b) | BM.GPU.H100.8 | Serves open source OpenAI Model with vLLM on NVIDIA H100 Bare metal host using 2 GPUs using the inference gateway |
| [vLLM meta-llama/Llama-4-Scout-17B-16E-Instruct MI300x](./example_vllm_llama4_scout.json) |[meta-llama/Llama-4-Scout-17B-16E-Instruct](https://huggingface.co/meta-llama/Llama-4-Scout-17B-16E-Instruct) | BM.GPU.MI300X.8 | Serves open source Llama4-Scout Model with vLLM on AMD MI300x Bare metal host using 4 GPUs using the inference gateway with model stored on Local NVMe |
| [vLLM meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8 MI300x](./example_vllm_llama4_maverick.json) | [meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8](https://huggingface.co/meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8) | BM.GPU.MI300X.8 | Serves open source Llama4-Maverick-fp8 Model with vLLM on AMD MI300x Bare metal host using 4 GPUs using the inference gateway with model stored on Local NVMe |

### Accessing Deployed Models
Once the Inference Gateway is deployed, you can access your AI models through the unified endpoint. For example, if you had all 3 blueprints above deployed and your endpoint was https://140-10-23-76.nip.io you could access all 3 models like:

```bash
curl -X POST https://140-10-23-76.nip.io/ai/models/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Model: "gpt-oss-120b"
  -H "apikey: "<api-key-from-gpt-blueprint>"
  -d '{"model": "openai/gpt-oss-120b", "messages": [{"role": "user", "content": "What is Kong Gateway?"}], "max_tokens": 200}'

curl -X POST https://140-10-23-76.nip.io/ai/models/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Model: "scout"
  -H "apikey: "<api-key-from-scout-blueprint>"
  -d '{"model": "Llama-4-Scout-17B-16E-Instruct", "messages": [{"role": "user", "content": "What is Kong Gateway?"}], "max_tokens": 200}'

curl -X POST https://140-10-23-76.nip.io/ai/models/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Model: "maverick"
  -H "apikey: "<api-key-from-maverick-blueprint>"
  -d '{"model": "Llama-4-Maverick-17B-128E-Instruct-FP8", "messages": [{"role": "user", "content": "What is Kong Gateway?"}], "max_tokens": 200}'
```

### Health Check
Monitor gateway health using the status endpoint (you may need to open a network port for this if desired):

```bash
curl https://<kong-ip>.nip.io:8100/status
```

## Security Considerations

### Network Security
- Load balancer security groups restrict access to necessary ports
- Private deployment option for internal-only access
- TLS termination at the load balancer level

### API Security
Kong provides extensive security features that can be configured:
- API key authentication
- Rate limiting and throttling <not implemented, post an issue if desired>
- Single unified URL for all model endpoints

## Troubleshooting

### Common Issues

**Gateway URL shows as null in outputs**
- Verify `bring_your_own_kong` is set to `false`
- Check that Kong pods are running in the `kong` namespace visible in the blueprints portal
- Ensure load balancer has been assigned an external IP

**Unable to access inference endpoints**
- Verify security group rules allow traffic on ports 80/443
- Check that target AI model services are running and healthy
- Confirm Kong ingress rules are properly configured

**Performance issues**
- Monitor resource utilization of Kong pods
- Consider scaling up the load balancer shape
- Review auto-scaling configuration

### Debug Commands on Kubernetes side

```bash
# Check Kong deployment status
kubectl get pods -n kong

# View Kong service details
kubectl get svc kong-kong-proxy -n kong

# Check load balancer assignment
kubectl describe svc kong-kong-proxy -n kong

# View Kong logs
kubectl logs -n kong deployment/kong-kong
```

## Version Information

- **Kong Gateway**: 3.9
- **Helm Chart**: 2.51.0
- **Repository**: https://charts.konghq.com
- **OCI Integration**: Native OCI Load Balancer support

## Next Steps

After deploying the Inference Gateway:

1. **Configure Routes**: Set up Kong ingress resources for your AI models
2. **Implement Security**: Configure authentication and rate limiting policies
3. **Monitor Performance**: Set up alerting and monitoring dashboards
4. **Scale Resources**: Adjust Kong replicas and load balancer shapes based on traffic

The Inference Gateway provides a production-ready foundation for managing AI model inference at scale, offering the flexibility and reliability needed for enterprise AI deployments on Oracle Cloud Infrastructure.
