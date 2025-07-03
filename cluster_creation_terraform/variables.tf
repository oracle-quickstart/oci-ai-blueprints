# Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Authentication Configuration
variable "use_instance_principal" {
  type        = bool
  default     = false
  description = "Whether to use Instance Principal for authentication. If false, user credentials will be used."
}

variable "fingerprint" {
  type        = string
  default     = ""
  description = "API Key Fingerprint for user authentication. Required when use_instance_principal is false."
}

variable "private_key_path" {
  type        = string
  default     = ""
  description = "Path to the private key file for user authentication. Required when use_instance_principal is false."
}

# Networking Configuration Mode
variable "network_configuration_mode" {
  default     = "create_new"
  description = "Whether to create a new VCN or use an existing one"
  type        = string

  validation {
    condition     = contains(["create_new", "bring_your_own"], var.network_configuration_mode)
    error_message = "Network configuration mode must be either 'create_new' or 'bring_your_own'."
  }

}

# Bring Your Own VCN Variables
variable "existing_vcn_id" {
  default     = ""
  description = "OCID of the existing VCN to use. Required when network_configuration_mode is 'bring_your_own'"
  type        = string
}

variable "existing_endpoint_subnet_id" {
  default     = ""
  description = "OCID of the existing subnet for the Kubernetes API endpoint. Required when network_configuration_mode is 'bring_your_own'"
  type        = string
}

variable "existing_node_subnet_id" {
  default     = ""
  description = "OCID of the existing subnet for worker nodes. Required when network_configuration_mode is 'bring_your_own'"
  type        = string
}

variable "existing_lb_subnet_id" {
  default     = ""
  description = "OCID of the existing subnet for load balancers. Required when network_configuration_mode is 'bring_your_own'"
  type        = string
}

# OKE Variables
## OKE Cluster Details
variable "cluster_options_add_ons_is_kubernetes_dashboard_enabled" {
  default = false
}

## OKE Visibility (Workers and Endpoint)

variable "cluster_workers_visibility" {
  default     = "Private"
  description = "The Kubernetes worker nodes that are created will be hosted in public or private subnet(s)"

  validation {
    condition     = var.cluster_workers_visibility == "Private" || var.cluster_workers_visibility == "Public"
    error_message = "Sorry, but cluster visibility can only be Private or Public."
  }
}

variable "cluster_endpoint_visibility_new_vcn" {
  default     = "Public"
  description = "The Kubernetes API endpoint visibility when creating a new VCN (only Public is supported)"
  type        = string

  validation {
    condition     = var.cluster_endpoint_visibility_new_vcn == "Public"
    error_message = "When creating a new VCN, only Public endpoint visibility is supported."
  }
}

variable "cluster_endpoint_visibility_existing_vcn" {
  default     = "Public"
  description = "The Kubernetes API endpoint visibility when using an existing VCN"
  type        = string

  validation {
    condition     = var.cluster_endpoint_visibility_existing_vcn == "Private" || var.cluster_endpoint_visibility_existing_vcn == "Public"
    error_message = "Endpoint visibility must be either 'Private' or 'Public'."
  }
}

# Combined local for backward compatibility
locals {
  cluster_endpoint_visibility = var.network_configuration_mode == "create_new" ? var.cluster_endpoint_visibility_new_vcn : var.cluster_endpoint_visibility_existing_vcn
}

## OKE Node Pool Details
variable "node_pool_name" {
  default     = "pool1"
  description = "Name of the node pool"
}
variable "k8s_version" {
  default     = "v1.31.1"
  description = "Kubernetes version installed on your master and worker nodes"
}
variable "num_pool_workers" {
  default     = 6
  description = "The number of worker nodes in the node pool. If select Cluster Autoscaler, will assume the minimum number of nodes configured"
}

variable "node_pool_instance_shape" {
  type = map(any)
  default = {
    "instanceShape" = "VM.Standard.E3.Flex"
    "ocpus"         = 6
    "memory"        = 64
  }
  description = "A shape is a template that determines the number of OCPUs, amount of memory, and other resources allocated to a newly created instance for the Worker Node. Select at least 2 OCPUs and 16GB of memory if using Flex shapes"
}
variable "node_pool_boot_volume_size_in_gbs" {
  default     = "60"
  description = "Specify a custom boot volume size (in GB)"
}

# Network Details
## CIDRs
variable "network_cidrs" {
  type = map(string)

  default = {
    VCN-CIDR                      = "10.0.0.0/16"
    SUBNET-REGIONAL-CIDR          = "10.0.64.0/20"
    LB-SUBNET-REGIONAL-CIDR       = "10.0.96.0/20"
    ENDPOINT-SUBNET-REGIONAL-CIDR = "10.0.128.0/20"
    ALL-CIDR                      = "0.0.0.0/0"
    PODS-CIDR                     = "10.244.0.0/16"
    KUBERNETES-SERVICE-CIDR       = "10.96.0.0/16"
  }
}

# OCI Provider
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "user_ocid" {
  default = ""
}

# ORM Schema visual control variables
variable "show_advanced" {
  default = false
}

# App Name Locals
locals {
  app_name               = random_string.app_name_autogen.result
  app_name_normalized    = random_string.app_name_autogen.result
  oci_ai_blueprints_link = file("${path.module}/OCI_AI_BLUEPRINTS_LINK")
}

# Networking Locals
locals {
  # Determine which VCN and subnets to use based on configuration mode
  vcn_id = var.network_configuration_mode == "bring_your_own" ? var.existing_vcn_id : oci_core_virtual_network.oke_vcn[0].id
  
  endpoint_subnet_id = var.network_configuration_mode == "bring_your_own" ? var.existing_endpoint_subnet_id : oci_core_subnet.oke_k8s_endpoint_subnet[0].id
  
  node_subnet_id = var.network_configuration_mode == "bring_your_own" ? var.existing_node_subnet_id : oci_core_subnet.oke_nodes_subnet[0].id
  
  lb_subnet_id = var.network_configuration_mode == "bring_your_own" ? var.existing_lb_subnet_id : oci_core_subnet.oke_lb_subnet[0].id
  
  # Only create new network resources when in create_new mode
  create_network_resources = var.network_configuration_mode == "create_new"
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex"
  ]
}