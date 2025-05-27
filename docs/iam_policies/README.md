## IAM Policies

Many OCI AI Blueprints users choose to give full admin access to OCI AI Blueprints when using it for the first time or developing a POC, and making the permissions more granular overtime. We provide you with two different variations of IAM Policies for you to choose from - depending on your situation.

## Step 1: Create Dynamic Group in Identity Domain

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

## Step 2: Add IAM Policies To Root Compartment

- **Note:** `'IdentityDomainName'/'DynamicGroupName'` -> please modify this to match the dynamic group that you created in Step 1 above
- **Note:** All these policies will be in the root compartment of your tenancy (NOT in the OCI AI Blueprints compartment itself)
- **Note:** If you are not an admin of your tenancy, then you will need to have an admin add the following policies for the dynamic group AND the user group that your user belongs if you are the one that will be deploying OCI AI Blueprints (aka you will have the admin create the policies below twice - once for the dynamic group you created in Step 1 and once for the user group that your user belongs to)

**Option #1: Full Admin Access:**

```
Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to inspect all-resources in tenancy
Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage all-resources in compartment {comparment_name}
```

**Option #2: Fine-Grain Access:**

```
Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to inspect all-resources in tenancy

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage instance-family in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use subnets in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage virtual-network-family in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use vnics in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use network-security-groups in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage public-ips in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage cluster-family in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage orm-stacks in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage orm-jobs in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage vcns in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage subnets in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage internet-gateways in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage nat-gateways in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage route-tables in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage security-lists in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to inspect clusters in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use cluster-node-pools in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to read cluster-work-requests in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage service-gateways in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use cloud-shell in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to read vaults in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to read keys in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to use compute-capacity-reservations in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to read metrics in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage autonomous-database-family in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to read virtual-network-family in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to inspect compartments in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to manage cluster-node-pools in compartment {compartment_name}

Allow dynamic-group 'IdentityDomainName'/'DynamicGroupName' to {CLUSTER_JOIN} in compartment {compartment_name}
```
