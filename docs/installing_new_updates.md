# Installing New Updates

## Overview

The OCI AI Blueprints team regularly publishes **full-stack release packages** (control plane, frontend, blueprints, Terraform).  
To upgrade your existing deployment, replace your stack’s source zip with the **latest package** from GitHub Releases and re-apply the stack in **OCI Resource Manager**.

---

## Upgrade Steps

1. **Download and unzip the latest release package**

   - Go to **GitHub → Releases** for OCI AI Blueprints  
     <https://github.com/oracle-quickstart/oci-ai-blueprints/releases>
   - Download the file that ends with `_app.zip` (for example `vX.Y.Z_app.zip`) and unzip it.

2. Open **OCI Console → Resource Manager → Stacks**.

3. Select the stack you originally used to deploy **OCI AI Blueprints**.

4. Click **Edit → Edit Stack**.

5. **Upload** the unzipped package (the `.zip` downloaded in Step 1).

   > _Tip: the file name should match the release you just downloaded._

6. Click **Next → Next → Confirm** to save the new source.

7. Press **Apply** (top-right). A new job starts automatically.

8. Wait until the job’s **State** is **Succeeded** — your entire stack is now updated.

---

## Technical Background

Updating the stack zip prompts **Resource Manager** to pull the newest Terraform code and container images.  
During _Apply_, OKE deployments roll automatically, so no manual pod restarts are needed.

---

## Error Handling

If a job fails or you see errors in the console, please contact:

- Vishnu Kammari — <vishnu.kammari@oracle.com>
- Grant Neuman — <grant.neuman@oracle.com>

Include the stack name and the failed job ID to help us troubleshoot quickly.
