## IAM Policies

Many OCI AI Blueprints users choose to give full admin access to OCI AI Blueprints when using it for the first time or developing a POC, and making the permissions more granular overtime. We provide you with two different variations of IAM Policies for you to choose from - depending on your situation.

To learn more details about the policy breakdowns, see the relevant sections below in the [Detailed Policy Breakdown](#detailed-policy-breakdown):
  - [OKE Cluster Stack Creation Policies](#oke-cluster-creation-policies)
  - [Blueprints App Stack Creation Policies](#blueprints-app-stack-creation-policies)
  - [Blueprints Feature Policies](#blueprints-feature-policies)

## Quickstart

### Step 1: Create Dynamic Group in Identity Domain

Inside the OCI console:

1. Open the **navigation menu** and select **Identity & Security**. Under **Identity**, select **Domains**.
2. Select the identity domain you want to work in and select **Dynamic Groups**.
3. Enter the following information:
   - **Name:** A unique name for the group. The name must be unique across all groups in your tenancy (dynamic groups and user groups). You can't change the name later. Avoid entering confidential information.
   - **Description:** A friendly description.
4. Enter the following **Matching rules**. Resources that meet the rule criteria are members of the group:

```
All {instance.compartment.id = '<oci-ai-blueprints_compartment_ocid>'}
```

(Substituting the actual compartment ocid where OCI AI Blueprints will be deployed in place of `<oci-ai-blueprints_compartment_ocid>`)

5. Select Create.

More info on dynamic groups can be found here: https://docs.oracle.com/en-us/iaas/Content/Identity/dynamicgroups/To_create_a_dynamic_group.htm

### Step 2: Add IAM Policies To Root Compartment

The Quickstart takes the approach of giving Blueprints full admin policies. If you would like to narrow the policies down, visit the [detailed policy breakdown](#detailed-policy-breakdown) section below.

- **Note:** `'Default'/'DynamicGroupName'` -> please modify this to match the dynamic group that you created in Step 1 above
- **Note:** All these policies will be in the root compartment of your tenancy (NOT in the OCI AI Blueprints compartment itself)
- **Note:** If you are not an admin of your tenancy, then you will need to have an admin add the following policies for the dynamic group AND the user group that your user belongs if you are the one that will be deploying OCI AI Blueprints (aka you will have the admin create the policies below twice - once for the dynamic group you created in Step 1 and once for the user group that your user belongs to)

```
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect all-resources in tenancy
Allow dynamic-group 'Default'/'DynamicGroupName' to manage all-resources in compartment My-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volumes in TENANCY where request.principal.type = 'cluster'
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volume-attachments in TENANCY where request.principal.type = 'cluster'
```

----
## Detailed Policy Breakdown

The detailed policy breakdown takes the approach of enabling you to provide exactly the policies you need for both stack creation and feature usage. Therefore, this section is split into two parts:
  - [Stack Creation Policies](#stack-creation-policies)
    - [OKE Stack Policies](#oke-cluster-creation-policies)
    - [Blueprints Stack Policies](#blueprints-app-stack-creation-policies)

  - [Blueprints Feature Policies](#blueprints-feature-policies)

### Stack Creation Policies
The below policies are related to the terraform deployments to create each stack for the OKE cluster and the Blueprints platform. 

#### OKE Cluster Creation Policies

OKE Cluster creation allows for two modes:
  - Install OKE Cluster into existing Virtual Network
  - Create Virtual Network and Install OKE Cluster

Because of this, different policy requirements exist for each mode. For specific details about the OKE verbs and virtual network verbs, visit:
  - [OKE Verbs](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/contengpolicyreference.htm#Details_for_Container_Engine_for_Kubernetes)
  - [Virtual Network Verbs](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/corepolicyreference.htm#For2)
  - `GetNodePoolOptions/all` - API used to determine images available for nodes, requires `inspect all-resources in tenancy`.

#### Bring your own network policies
Because we are not creating the virtual network, policy usage can be minimized to "read" permissions on several of the virtual network family members compared to the create policies. The required policies are:

**Note**: 'Default' is the "default" identity domain, and 'DynamicGroupName' is the name of your dynamic group. 'Dennis-Compartment' is an example compartment name. If using nested compartments, the syntax is: Dennis-Compartment:Dennis-ChildA:Dennis-ChildB

```
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect all-resources in tenancy
Allow dynamic-group 'Default'/'DynamicGroupName' to manage clusters in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-node-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read virtual-network-family in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use subnets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use vnics in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use network-security-groups in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use private-ips in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read cluster-work-requests in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-family in compartment Dennis-Compartment
```

#### Create your network policies
To additionally create the virtual network the policies become a bit more open as the `manage` verb encompasses all of the `use` policies above, plus a few more permissions:
```
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect all-resources in tenancy
Allow dynamic-group 'Default'/'DynamicGroupName' to manage clusters in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-node-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage virtual-network-family in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read cluster-work-requests in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-family in compartment Dennis-Compartment
```

### Blueprints App Stack Creation Policies

Blueprints needs to use the cluster, the virtual network, inspect node pools, create and attachvolumes, and create a load balancer.
```
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect all-resources in tenancy
Allow dynamic-group 'Default'/'DynamicGroupName' to use virtual-network-family in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volumes in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volume-attachments in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage load-balancers in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use clusters in compartment Dennis-Compartment
```

### Blueprints Feature Policies

Feature policies describe the policies required to enable all of the Blueprints platform features. Combined policies will be shown first which are the minimum required policies to use all Blueprints features, and then feature specific policies follow with links to documentation. This way, users can selectively opt in or opt out of certain features if policies are prohibitive.

**Full Feature Policies**

```
Allow dynamic-group 'Default'/'DynamicGroupName' to manage clusters in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-node-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-family in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use vnics in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use subnets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read instance-images in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage compute-capacity-reports in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read cluster-work-requests in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read file-systems in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read mount-targets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read export-sets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect private-ips in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read buckets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage objects in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use volumes in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-configurations in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-networks in compartment Dennis-Compartment
```

**Minimum policies for RDMA Enabled Cluster Networks**

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/corepolicyreference.htm#compute-management-family

```
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instances in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use vnics in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use subnets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use network-security-groups in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read instance-images in tenancy
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volume-attachments in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use volumes in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-configurations in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-networks in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use clusters in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to {CLUSTER_JOIN} in compartment Dennis-Compartment
```

**Minimum policies for shared node pool creation**

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/contengpolicyreference.htm

```
Allow dynamic-group 'Default'/'DynamicGroupName' to manage cluster-node-pools in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage instance-family in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use subnets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to use vnics in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read instance-images in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage compute-capacity-reports in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read clusters in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read cluster-work-requests in compartment Dennis-Compartment
```

**Any blueprint read from object storage**

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/objectstoragepolicyreference.htm

```
Allow dynamic-group 'Default'/'DynamicGroupName' to read buckets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read objects in compartment Dennis-Compartment
```

**Any blueprint to read from and write to object storage**

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/objectstoragepolicyreference.htm

```
Allow dynamic-group 'Default'/'DynamicGroupName' to read buckets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to manage objects in compartment Dennis-Compartment
```

**Any blueprint to provision in subcompartment. Also requires addition of subcompartment to dynamic group**

https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim_topic-Provisioning_PVCs_on_BV.htm#Provisioning_Persistent_Volume_Claims_on_the_Block_Volume_Service

```
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volumes in TENANCY where request.principal.type = 'cluster'
Allow dynamic-group 'Default'/'DynamicGroupName' to manage volume-attachments in TENANCY where request.principal.type = 'cluster'
```

**Any blueprint to read from or write to OCI file storage (also requires appropriate security rules)**

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/filestoragepolicyreference.htm

https://docs.oracle.com/en-us/iaas/Content/File/Tasks/securitylistsfilestorage.htm#Configuring_VCN_Security_Rules_for_File_Storage

```
Allow dynamic-group 'Default'/'DynamicGroupName' to read file-systems in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read mount-targets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to read export-sets in compartment Dennis-Compartment
Allow dynamic-group 'Default'/'DynamicGroupName' to inspect private-ips in compartment Dennis-Compartment
```

**Any blueprint to autoscale nodes (not pods)**

To reiterate, if you only want to autoscale pods and not nodes, and full cluster `manage` is not required. `use cluster` with `{CLUSTER_JOIN}` can be used instead.

InstallAddon, UpdateAddon, DeleteAddon APIs require `manage cluster`

https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/contengpolicyreference.htm#Details_for_Container_Engine_for_Kubernetes

```
Allow dynamic-group 'Default'/'DynamicGroupName' to manage clusters in compartment Dennis-Compartment
```