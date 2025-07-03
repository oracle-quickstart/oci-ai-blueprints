# Deploying Blueprints into private networks

This document contains two parts. The first describes using our Quickstart to deploy an OKE cluster into a pre-existing private network with no public access, and the second describes deploying blueprints onto an OKE cluster with no public access.

## Deploying OKE Stack into pre-existing private subnets

We do not create new completely locked down private subnets, but we do support them from a "bring your own" perspective if you'd like to deploy a new OKE cluster into one.

Deploying into a private subnet may likely mean the subsequent Blueprints deployment cannot be installed with the "Stack", as the stack communicates with the cluster over a public endpoint from the internet. If it is acceptable for you to have a public API endpoint but only private worker nodes, **return to the original deployment in [getting started](../../../GETTING_STARTED_README.md)**, otherwise continue.

## Terraform Setup

It may be preferable for some users to deploy with terraform in the scenario where you bring your own network. If your networking setup does not allow for installation via the stack deployment in the OCI console, it is still possible to deploy with terraform locally using the following steps:

1. Setup a bastion or get on a workstation with the ability to communicate with your cluster's API Endpoint. An example document is given above.
2. Install the Terraform CLI from [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) from the bastioned host.
3. Install the OCI CLI from [here](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) and configure authentication in your `~/.oci/config` according to [this](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm).
4. Clone our GitHub repository locally, and change directory into `oci-ai-blueprints/oci_ai_blueprints_terraform`
5. Initialize the terraform with `terraform init`.
6. Create a tfvars file in that directory called `terraform.tfvars`. The minimum variables needed are in [example_cluster_tfvars.md](./example_cluster_tfvars.md) and [example_blueprints_tfvars.md](./example_blueprints_tfvars.md) for each respective stack.
7. Run a `terraform plan` to ensure nothing is missing.
8. Run a `terraform apply` to install the Blueprints platform on your OKE cluster.

**Note**: When deploying with terraform, it is important that you specify the correct stack version in the tfvars file. If you use an older version of the stack, this will be used for the blueprints version running in the control plane. If a mistake happens, it is very easy to modify the tfvars file to the correct stack version and reapply your changes, which would force an updated container pull.

## Console based deployment for OKE

1. Click on the deployment button in [this section](../../../GETTING_STARTED_README.md#step-2-deploy-the-vcn-and-oke-cluster), which will take you to the OKE deployment stack.
2. In **Create Stack**:
   - Give your stack a **name** (e.g., _oke-stack_).
   - Select the **compartment** where you want OCI AI Blueprints deployed.
3. Click "Show advanced options?"
4. Under **Network Configuration** click "bring_your_own", and populate the vcn, and subnets for the API Endpoint, Worker Nodes, and Load Balancer.
5. Under **OKE Cluster Configuration** for set both visibility types to **Private**.
6. Populate the number of worker nodes for the control plane, the shape, and the pool name, then click **Next**, then **Create**, and finally choose **Run apply** to provision your cluster.
7. Monitor the progress in **Resource Manager → Stacks**. Once the status is **Succeeded**, you have a functional VCN and an OKE cluster ready to host OCI AI Blueprints.

For documentation on access and networking configurations for locked down environments, visit:
  - [Kubernetes API Endpoint Subnet Configuration](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#subnetconfig__section_kcm_v2b_s4b)
  - [Setting Up a Bastion for Cluster Access](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengsettingupbastion.htm#contengsettingupbastion)

## Console based deployment for Blueprints

This document describes deploying blueprints into private networks. Since private networks are generally blocked from the console, see the terraform steps above.

If you are not blocked from the console, the only change to make from the default deployment is to set **Load Balancer Visibility** to **Private** which is under the **Public Endpoints** section.