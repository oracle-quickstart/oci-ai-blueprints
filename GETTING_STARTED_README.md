# Getting Started with OCI AI Blueprints

**❗❗IMPORTANT: The instructions below are for creating a new OKE cluster and installing OCI AI Blueprints to it. If you'd like to install OCI AI Blueprints to an existing OKE cluster, follow the steps here: [Install OCI AI Blueprints to an Existing OKE Cluster](./INSTALLING_ONTO_EXISTING_CLUSTER_README.md)**

This guide helps you install and use **OCI AI Blueprints** for the first time. You will:

1. Ensure you have the correct IAM policies in place.
2. Deploy a dedicated **VCN and OKE cluster** stack.
3. Deploy the **OCI AI Blueprints** application onto the new cluster.
4. Access the OCI AI Blueprints portal to deploy a sample blueprint.
5. Access the OCI AI Blueprints API to deploy a sample blueprint.
6. Clean up resources when you’re done.

---

## Step 1: Set Up Policies in Your Tenancy

1. If you are **not** a tenancy administrator, ask your admin to set up the required policies in the **root compartment**. These policies are listed [here](docs/iam_policies/README.md).
2. If you **are** a tenancy administrator, Resource Manager will typically deploy the minimal required policies automatically, but you can reference the same [IAM policies doc](docs/iam_policies/README.md) for advanced or custom configurations if needed.

---

## Step 2: Deploy the VCN and OKE Cluster

Instead of creating an OKE cluster manually, you can deploy a **VCN + OKE cluster** in one click. Use the button below to open Oracle Cloud’s Resource Manager:

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-ai-blueprints/releases/download/release-2025-04-22/cluster_release-2025-04-22.zip)

1. Click **Deploy to Oracle Cloud** above.
2. In **Create Stack**:
   - Give your stack a **name** (e.g., _oke-stack_).
   - Select the **compartment** where you want OCI AI Blueprints deployed.
   - Provide any additional parameters (such as node size, node count) according to your preferences.
3. Click **Next**, then **Create**, and finally choose **Run apply** to provision your cluster.
4. Monitor the progress in **Resource Manager → Stacks**. Once the status is **Succeeded**, you have a functional VCN and an OKE cluster ready to host OCI AI Blueprints.

---

## Step 3: Deploy the OCI AI Blueprints Application

Now that your cluster is ready, follow these steps to install OCI AI Blueprints onto it:

1. Click the **Deploy to Oracle Cloud** button below to open another Resource Manager stack—this one for OCI AI Blueprints:

   [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-ai-blueprints/releases/download/release-2025-04-22/app_release-2025-04-22.zip)

2. In the **Create Stack** wizard:
   - Provide a **name** (e.g., _oci-ai-blueprints-stack_).
   - Choose the **same compartment** where your OKE cluster resides.
   - Make sure you select the **OKE cluster** you just created. Depending on the stack’s parameters, you may need to specify:
     - The OKE cluster OCID.
     - The node pool, if prompted.
     - Your desired admin credentials for logging into the OCI AI Blueprints portal.
3. Click **Next**, then **Create**, and choose **Run apply** in the **Review** section.
4. After the job completes, go to **Resource Manager → Stacks → (Your OCI AI Blueprints Stack)**.
5. Under **Application Information**, you will see the **Portal URL** and **API URL**. You may also see generated admin credentials (if you didn't supply your own).

---

## Step 4: Access the Portal & Deploy a Sample Blueprint

1. **Open the Portal**: Go to the **Portal URL** from **Step 3** in your web browser.
2. **Log In**: Enter the username and password you set during stack creation (or check the Resource Manager output variables if you left the defaults).
3. **Deploy a Sample Blueprint**:
   - From the OCI AI Blueprints portal home screen, select **Deploy** on one of the blueprints (e.g., an LLM inference blueprint).
   - A list of **pre-filled samples** for that blueprint will appear, select one and you can simply click **Deploy**. (Advanced users can modify parameters like GPU shape or model ID.)
4. **Monitor Deployment**: The portal will show the status of your deployment. Once it transitions to a **Running** or **Monitoring** state, you can test the endpoint as described in the portal UI.

---

## Step 5: Access the AI Blueprints API

1. Follow the instruction to access the AI Blueprints API via web and/or CURL/Postman: [Ways to Access OCI AI Blueprints](./docs/api_documentation/accessing_oci_ai_blueprints/README.md#ways-to-access-oci-ai-blueprints)

---

## Cleanup

When you are finished, you can remove the resources you created in **two steps**, in this order:

1. **Destroy the OCI AI Blueprints Stack**

   - Go to **Resource Manager → Stacks** in the OCI Console.
   - Select the stack you used to install **OCI AI Blueprints** (from Step 3).
   - Choose **Terraform Actions → Destroy**, confirm, and wait until the job succeeds.

2. **Destroy the OKE Cluster & VCN Stack**
   - Return to **Resource Manager → Stacks**.
   - Select the stack you used to create your **cluster & VCN** (from Step 2).
   - Choose **Terraform Actions → Destroy**, confirm, and wait until it finishes.

Following this order ensures you do not have leftover services or dependencies in your tenancy. Once both stacks are destroyed, your tenancy will be free of any OCI AI Blueprints-related resources.

---

## Need Help?

- Check out [Known Issues & Solutions](docs/known_issues/README.md) for troubleshooting common problems.
- For questions or additional support, contact [vishnu.kammari@oracle.com](mailto:vishnu.kammari@oracle.com) or [grant.neuman@oracle.com](mailto:grant.neuman@oracle.com).
