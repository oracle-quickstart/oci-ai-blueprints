# Custom DNS for AI Accelerator Packs

By default, AI Accelerator Packs use an automatic domain powered by [nip.io](https://nip.io), which requires no DNS configuration. For production deployments, you can configure your own custom domain to provide professional, branded URLs for your services.

## When to Use Custom DNS

| Scenario                   | Recommended Option                                      |
| -------------------------- | ------------------------------------------------------- |
| Development and testing    | Default (nip.io) - works immediately, no setup required |
| Demos and proof-of-concept | Default (nip.io) - quick and easy                       |
| Production deployments     | **Custom DNS** - professional URLs, better security     |
| Enterprise environments    | **Custom DNS** - integrates with corporate domains      |

## Prerequisites

Before enabling custom DNS, ensure you have:

1. **Domain Ownership** - You own or control the domain you want to use
2. **DNS Registrar Access** - You can create DNS records for your domain
3. **Understanding of A-Records** - Basic knowledge of DNS A-record configuration

## Availability

Custom DNS is available for most AI Accelerator Packs:

| Accelerator Pack                         | Custom DNS Support |
| ---------------------------------------- | ------------------ |
| Delivery Vehicle Route Optimizer (cuOpt) | Yes                |
| Video Search & Summarization (VSS)       | Yes                |
| AI-Q with Shared Services (PaaS RAG)     | Yes                |
| Oracle-Net Self-Hosted (Enterprise RAG)  | Yes                |

## Configuration Steps

### Step 1: Enable Custom DNS

During stack configuration in OCI Resource Manager:

1. Expand the **Advanced Options** section
2. Check the **Use Custom DNS** checkbox
3. The **Custom Domain** field will appear

### Step 2: Enter Your Domain

In the **Custom Domain** field, enter your base domain:

- **Correct format:** `ai.mycompany.com`
- **Do NOT include:** wildcard (`*`) or protocol (`https://`)

**Examples of valid inputs:**

- `ai.mycompany.com`
- `ml.example.org`
- `blueprints.internal.corp.com`

### Step 3: Deploy the Stack (Initial Attempt)

1. Complete the remaining configuration options
2. Click **Create** to deploy the stack
3. **The deployment will fail** - this is expected because DNS is not yet configured
4. You will see a DNS configuration warning in the logs showing the required setup

### Step 4: Configure DNS

After the initial deployment fails, configure your DNS:

1. **Find the Load Balancer IP**

   You can find the IP in one of two places:

   - **Application Information tab** - Look for **Load Balancer IP Address** in the **DNS Configuration Required** section
   - **Terraform logs** - Search for the DNS configuration warning message which displays the IP address

2. **Create a Wildcard A-Record**

   In your DNS registrar, create a new DNS A record that resolves `*.yourdomain.com` to the Load Balancer IP.

   | Setting         | Value                            |
   | --------------- | -------------------------------- |
   | Record Type     | A                                |
   | Value/Points To | The Load Balancer IP from step 1 |
   | TTL             | 300 (or your preferred value)    |

   **For the Record Name:**

   - Start with `*` (the wildcard)
   - If your desired custom domain adds a prefix to the domain you own, include that prefix after the `*`

   | Example                                                                 | Explanation                     |
   | ----------------------------------------------------------------------- | ------------------------------- |
   | You own `mycompany.com` and want custom domain `ai.mycompany.com`       | Enter `*.ai` as the record name |
   | You own `mycompany.com` and want custom domain `mycompany.com` directly | Enter `*` as the record name    |
   | You own `example.org` and want custom domain `ml.example.org`           | Enter `*.ml` as the record name |

   **Why a wildcard?** The system creates multiple subdomains (api, blueprints, grafana, etc.) under your custom domain, so a wildcard record covers them all.

### Step 5: Re-Apply the Stack

After configuring DNS and waiting for propagation:

1. Return to your stack in OCI Resource Manager
2. Click **Apply** to re-run the deployment
3. The deployment will now succeed because DNS resolves correctly
4. Check the **Application Information** tab for your service URLs

### Step 6: Verify and Access

1. **Wait for DNS Propagation** - If you just configured DNS, this typically takes 5-30 minutes but can take up to 48 hours depending on your DNS provider and TTL settings

2. **SSL Certificates** - Once DNS resolves, Let's Encrypt automatically provisions SSL certificates for your domains

3. **Access Your Services** - Navigate to your new URLs (see Services and Subdomains below)

## Services and Subdomains

When you configure custom DNS with a base domain (e.g., `ai.mycompany.com`), the following subdomains are created:

| Subdomain           | Purpose                   | Example URL                           |
| ------------------- | ------------------------- | ------------------------------------- |
| `api`               | OCI AI Blueprints API     | `https://api.ai.mycompany.com`        |
| `blueprints`        | Management Portal         | `https://blueprints.ai.mycompany.com` |
| `grafana`           | Monitoring Dashboard      | `https://grafana.ai.mycompany.com`    |
| `prometheus`        | Metrics Collection        | `https://prometheus.ai.mycompany.com` |
| `<deployment-name>` | Your Deployed Application | `https://vss.ai.mycompany.com`        |

The deployment name subdomain varies based on your Accelerator Pack (e.g., `cuopt`, `vss`, `frontend`). Your deployed application URL will be displayed in the **Application Information** tab after deployment completes.

## Troubleshooting

### Deployment Fails with Connection Errors

**Cause:** DNS is not configured or has not propagated yet.

**Solution:**

1. Verify you created the wildcard A-record correctly
2. Check DNS propagation using an online tool or `nslookup *.yourdomain.com`
3. Wait for propagation to complete
4. Re-apply the stack (click **Apply** again)

### SSL Certificate Warnings in Browser

**Cause:** DNS recently propagated and certificates are still being provisioned.

**Solution:**

1. Wait 5-10 minutes for Let's Encrypt to issue certificates
2. Clear your browser cache
3. Try accessing in an incognito/private window

### DNS Not Resolving

**Cause:** A-record configuration issue or propagation delay.

**Solution:**

1. Verify the A-record is a **wildcard** (`*`) record
2. Confirm the IP address matches the Load Balancer IP from stack outputs
3. Check if your DNS provider requires the full subdomain (e.g., `*.ai.mycompany.com` vs just `*`)
4. Wait for DNS propagation (can take up to 48 hours)

### Services Work but Application URL Doesn't

**Cause:** The application deployment may still be in progress.

**Solution:**

1. Check the stack logs for deployment status
2. Access the Management Portal (`blueprints.yourdomain.com`) to verify deployment status
3. Wait for the application deployment to complete

## Frequently Asked Questions

**Can I change my domain after deployment?**

Yes. Update the **Custom Domain** field in your stack configuration and click **Apply**. You will need to update your DNS A-record to point to the same Load Balancer IP.

**What happens if I don't configure DNS after enabling custom DNS?**

The initial deployment will fail because the system cannot reach the API at your custom domain. This is expected. After the failure, retrieve the Load Balancer IP from the logs or Application Information tab, configure your DNS A-record, wait for propagation, and then click **Apply** to re-run the deployment.

**How long does DNS propagation take?**

Typically 5-30 minutes, but it can take up to 48 hours depending on your DNS provider and the TTL (Time To Live) setting on your DNS records.

**Can I use a subdomain of my existing domain?**

Yes. For example, if you own `mycompany.com`, you can use `ai.mycompany.com` as your custom domain. The system will create subdomains like `api.ai.mycompany.com`.

**Is HTTPS automatically enabled?**

Yes. Once DNS is configured and propagated, Let's Encrypt automatically provisions SSL certificates for all subdomains. All traffic is encrypted via HTTPS.

**Can I use my own SSL certificates instead of Let's Encrypt?**

The default configuration uses Let's Encrypt for automatic certificate management. Custom certificate configuration requires manual Kubernetes configuration after deployment.
