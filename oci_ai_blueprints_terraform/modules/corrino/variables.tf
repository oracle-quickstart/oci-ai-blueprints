# Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

################################################################################
# OCI Provider Variables
################################################################################
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}


################################################################################
# App Name to identify deployment. Used for naming resources.
################################################################################
variable "app_name" {
  description = "Application name. Will be used as prefix to identify resources, such as OKE, VCN, ATP, and others"
}

variable "deploy_id" {
  description = "combined with app_name to create canonical object names"
}

variable "tag_values" {
  type = map(any)
  default = { "freeformTags" = {
    "Environment" = "Development",  # e.g.: Demo, Sandbox, Development, QA, Stage, ...
    "DeploymentType" = "generic" }, # e.g.: App Type 1, App Type 2, Red, Purple, ...
  "definedTags" = {} }
  description = "Use Tagging to add metadata to resources. All resources created by this stack will be tagged with the selected tag values."
}

################################################################################
# Variables: OCI Networking
################################################################################
## VCN
variable "create_new_vcn" {
  default     = true
  description = "Creates a new Virtual Cloud Network (VCN). If false, the VCN must be provided in the variable 'existent_vcn_ocid'."
}
variable "existent_vcn_ocid" {
  default     = ""
  description = "Using existent Virtual Cloud Network (VCN) OCID."
}
variable "existent_vcn_compartment_ocid" {
  default     = ""
  description = "Compartment OCID for existent Virtual Cloud Network (VCN)."
}
variable "vcn_cidr_blocks" {
  default     = "10.20.0.0/16"
  description = "IPv4 CIDR Blocks for the Virtual Cloud Network (VCN). If use more than one block, separate them with comma. e.g.: 10.20.0.0/16,10.80.0.0/16. If you plan to peer this VCN with another VCN, the VCNs must not have overlapping CIDRs."
}
variable "is_ipv6enabled" {
  default     = false
  description = "Whether IPv6 is enabled for the Virtual Cloud Network (VCN)."
}

variable "ipv6private_cidr_blocks" {
  default     = []
  description = "The list of one or more ULA or Private IPv6 CIDR blocks for the Virtual Cloud Network (VCN)."
}
## Subnets
variable "create_subnets" {
  default     = true
  description = "Create subnets for OKE: Endpoint, Nodes, Load Balancers. If CNI Type OCI_VCN_IP_NATIVE, also creates the PODs VCN. If FSS Mount Targets, also creates the FSS Mount Targets Subnet"
}
variable "create_pod_network_subnet" {
  default     = false
  description = "Create PODs Network subnet for OKE. To be used with CNI Type OCI_VCN_IP_NATIVE"
}
variable "existent_oke_k8s_endpoint_subnet_ocid" {
  default     = ""
  description = "The OCID of the subnet where the Kubernetes cluster endpoint will be hosted"
}
variable "existent_oke_nodes_subnet_ocid" {
  default     = ""
  description = "The OCID of the subnet where the Kubernetes worker nodes will be hosted"
}
variable "existent_oke_load_balancer_subnet_ocid" {
  default     = ""
  description = "The OCID of the subnet where the Kubernetes load balancers will be hosted"
}
variable "existent_oke_vcn_native_pod_networking_subnet_ocid" {
  default     = ""
  description = "The OCID of the subnet where the Kubernetes VCN Native Pod Networking will be hosted"
}
variable "existent_oke_fss_mount_targets_subnet_ocid" {
  default     = ""
  description = "The OCID of the subnet where the Kubernetes FSS mount targets will be hosted"
}
# variable "existent_apigw_fn_subnet_ocid" {
#   default     = ""
#   description = "The OCID of the subnet where the API Gateway and Functions will be hosted"
# }
variable "extra_subnets" {
  default     = []
  description = "Extra subnets to be created."
}
variable "extra_route_tables" {
  default     = []
  description = "Extra route tables to be created."
}
variable "extra_security_lists" {
  default     = []
  description = "Extra security lists to be created."
}
variable "extra_security_list_name_for_api_endpoint" {
  default     = null
  description = "Extra security list name previosly created to be used by the K8s API Endpoint Subnet."
}
variable "extra_security_list_name_for_nodes" {
  default     = null
  description = "Extra security list name previosly created to be used by the Nodes Subnet."
}
variable "extra_security_list_name_for_vcn_native_pod_networking" {
  default     = null
  description = "Extra security list name previosly created to be used by the VCN Native Pod Networking Subnet."
}

################################################################################
# Variables: OKE Network
################################################################################
# OKE Network Visibility (Workers, Endpoint and Load Balancers)
variable "cluster_workers_visibility" {
  default     = "Private"
  description = "The Kubernetes worker nodes that are created will be hosted in public or private subnet(s)"

  validation {
    condition     = var.cluster_workers_visibility == "Private" || var.cluster_workers_visibility == "Public"
    error_message = "Sorry, but cluster visibility can only be Private or Public."
  }
}
variable "cluster_endpoint_visibility" {
  default     = "Public"
  description = "The Kubernetes cluster that is created will be hosted on a public subnet with a public IP address auto-assigned or on a private subnet. If Private, additional configuration will be necessary to run kubectl commands"

  validation {
    condition     = var.cluster_endpoint_visibility == "Private" || var.cluster_endpoint_visibility == "Public"
    error_message = "Sorry, but cluster endpoint visibility can only be Private or Public."
  }
}
variable "cluster_load_balancer_visibility" {
  default     = "Public"
  description = "The Load Balancer that is created will be hosted on a public subnet with a public IP address auto-assigned or on a private subnet. This affects the Kubernetes services, ingress controller and other load balancers resources"

  validation {
    condition     = var.cluster_load_balancer_visibility == "Private" || var.cluster_load_balancer_visibility == "Public"
    error_message = "Sorry, but cluster load balancer visibility can only be Private or Public."
  }
}
variable "pods_network_visibility" {
  default     = "Private"
  description = "The PODs that are created will be hosted on a public subnet with a public IP address auto-assigned or on a private subnet. This affects the Kubernetes services and pods"

  validation {
    condition     = var.pods_network_visibility == "Private" || var.pods_network_visibility == "Public"
    error_message = "Sorry, but PODs Network visibility can only be Private or Public."
  }
}
variable "ingress_load_balancer_visibility" {
  default     = "Public"
  description = "The Load Balancer visibility - Private or Public"
  type        = string
}

################################################################################
# Variables: OKE Cluster
################################################################################
## OKE Cluster Details
variable "create_new_oke_cluster" {
  default     = true
  description = "Creates a new OKE cluster, node pool and network resources"
}
variable "existent_oke_cluster_id" {
  default     = ""
  description = "Using existent OKE Cluster. Only the application and services will be provisioned. If select cluster autoscaler feature, you need to get the node pool id and enter when required"
}
variable "cluster_type" {
  default     = "BASIC_CLUSTER"
  description = "The type of OKE cluster to create. Valid values are: BASIC_CLUSTER or ENHANCED_CLUSTER"

  validation {
    condition     = var.cluster_type == "BASIC_CLUSTER" || var.cluster_type == "ENHANCED_CLUSTER"
    error_message = "Sorry, but cluster visibility can only be BASIC_CLUSTER or ENHANCED_CLUSTER."
  }
}
variable "create_new_compartment_for_oke" {
  default     = false
  description = "Creates new compartment for OKE Nodes and OCI Services deployed.  NOTE: The creation of the compartment increases the deployment time by at least 3 minutes, and can increase by 15 minutes when destroying"
}
variable "oke_compartment_description" {
  default = "Compartment for OKE, Nodes and Services"
}
variable "cluster_cni_type" {
  default     = "FLANNEL_OVERLAY"
  description = "The CNI type to use for the cluster. Valid values are: FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE"

  validation {
    condition     = var.cluster_cni_type == "FLANNEL_OVERLAY" || var.cluster_cni_type == "OCI_VCN_IP_NATIVE"
    error_message = "Sorry, but OKE currently only supports FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE CNI types."
  }
}

## OKE Encryption details
variable "use_encryption_from_oci_vault" {
  default     = false
  description = "By default, Oracle manages the keys that encrypts Kubernetes Secrets at Rest in Etcd, but you can choose a key from a vault that you have access to, if you want greater control over the key's lifecycle and how it's used"
}
variable "create_new_encryption_key" {
  default     = false
  description = "Creates new vault and key on OCI Vault/Key Management/KMS and assign to boot volume of the worker nodes"
}
variable "existent_encryption_key_id" {
  default     = ""
  description = "Use an existent master encryption key to encrypt boot volume and object storage bucket. NOTE: If the key resides in a different compartment or in a different tenancy, make sure you have the proper policies to access, or the provision of the worker nodes will fail"
}
variable "create_vault_policies_for_group" {
  default     = false
  description = "Creates policies to allow the user applying the stack to manage vault and keys. If you are on the Administrators group or already have the policies for a compartment, this policy is not needed. If you do not have access to allow the policy, ask your administrator to include it for you"
}
variable "user_admin_group_for_vault_policy" {
  default     = "Administrators"
  description = "User Identity Group to allow manage vault and keys. The user running the Terraform scripts or Applying the ORM Stack need to be on this group"
}

## OKE Autoscaler
variable "node_pool_autoscaler_enabled_1" {
  default     = true
  description = "Enable Cluster Autoscaler on the node pool (pool1). Node pools will auto scale based on the resources usage and will add or remove nodes (Compute) based on the min and max number of nodes"
}
variable "node_pool_initial_num_worker_nodes_1" {
  default     = 3
  description = "The number of worker nodes in the node pool. If enable Cluster Autoscaler, will assume the minimum number of nodes on the node pool to be scheduled by the Kubernetes (pool1)"
}
variable "node_pool_max_num_worker_nodes_1" {
  default     = 10
  description = "Maximum number of nodes on the node pool to be scheduled by the Kubernetes (pool1)"
}
variable "existent_oke_nodepool_id_for_autoscaler_1" {
  default     = ""
  description = "Nodepool Id of the existent OKE to use with Cluster Autoscaler (pool1)"
}

################################################################################
# Variables: OKE Node Pool 1
################################################################################
## OKE Node Pool Details
variable "k8s_version" {
  default     = "Latest"
  description = "Kubernetes version installed on your Control Plane and worker nodes. If not version select, will use the latest available."
}
### Node Pool 1
variable "node_pool_name_1" {
  default     = "pool1"
  description = "Name of the node pool 1"
}
variable "extra_initial_node_labels_1" {
  default     = []
  description = "Extra initial node labels to be added to the node pool 1"
}
variable "node_pool_cni_type_1" {
  default     = "FLANNEL_OVERLAY"
  description = "The CNI type to use for the cluster. Valid values are: FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE"

  validation {
    condition     = var.node_pool_cni_type_1 == "FLANNEL_OVERLAY" || var.node_pool_cni_type_1 == "OCI_VCN_IP_NATIVE"
    error_message = "Sorry, but OKE currently only supports FLANNEL_OVERLAY or OCI_VCN_IP_NATIVE CNI types."
  }
}

#### ocpus and memory are only used if flex shape is selected
variable "node_pool_instance_shape_1" {
  type = map(any)
  default = {
    "instanceShape" = "VM.Standard.E4.Flex"
    "ocpus"         = 2
    "memory"        = 16
  }
  description = "A shape is a template that determines the number of OCPUs, amount of memory, and other resources allocated to a newly created instance for the Worker Node. Select at least 2 OCPUs and 16GB of memory if using Flex shapes"
}
variable "node_pool_shape_specific_ad_1" {
  description = "The number of the AD to get the shape for the node pool"
  type        = number
  default     = 0

  validation {
    condition     = var.node_pool_shape_specific_ad_1 >= 0 && var.node_pool_shape_specific_ad_1 <= 3
    error_message = "Invalid AD number, should be 0 to get all ADs or 1, 2 or 3 to be a specific AD."
  }
}
variable "node_pool_boot_volume_size_in_gbs_1" {
  default     = "60"
  description = "Specify a custom boot volume size (in GB)"
}
variable "image_operating_system_1" {
  default     = "Oracle Linux"
  description = "The OS/image installed on all nodes in the node pool."
}
variable "image_operating_system_version_1" {
  default     = "8"
  description = "The OS/image version installed on all nodes in the node pool."
}
variable "node_pool_oke_init_params_1" {
  type        = string
  default     = ""
  description = "OKE Init params"
}
variable "node_pool_cloud_init_parts_1" {
  type = list(object({
    content_type = string
    content      = string
    filename     = string
  }))
  default     = []
  description = "Node Pool nodes Cloud init parts"
}
variable "generate_public_ssh_key" {
  default = true
}
variable "public_ssh_key" {
  default     = ""
  description = "In order to access your private nodes with a public SSH key you will need to set up a bastion host (a.k.a. jump box). If using public nodes, bastion is not needed. Left blank to not import keys."
}
################################################################################
# Variables: OKE Extra Node Pools
################################################################################
variable "extra_node_pools" {
  default     = []
  description = "Extra node pools to be added to the cluster"
}

################################################################################
# Variables: Dynamic Group and Policies for OKE
################################################################################
# Create Dynamic Group and Policies
variable "create_dynamic_group_for_nodes_in_compartment" {
  default     = true
  description = "Creates dynamic group of Nodes in the compartment. Note: You need to have proper rights on the Tenancy. If you only have rights in a compartment, uncheck and ask you administrator to create the Dynamic Group for you"
}
variable "existent_dynamic_group_for_nodes_in_compartment" {
  default     = ""
  description = "Enter previous created Dynamic Group for the policies"
}
variable "create_compartment_policies" {
  default     = true
  description = "Creates policies that will reside on the compartment. e.g.: Policies to support Cluster Autoscaler, OCI Logging datasource on Grafana"
}
variable "create_tenancy_policies" {
  default     = false
  description = "Creates policies that need to reside on the tenancy. e.g.: Policies to support OCI Metrics datasource on Grafana"
}
