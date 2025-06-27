# Copyright (c) 2020-2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = local.oke_compartment_ocid
  kubernetes_version = (var.k8s_version == "Latest") ? local.cluster_k8s_latest_version : var.k8s_version
  name               = "${local.app_name} (${random_string.deploy_id.result})"
  vcn_id             = local.vcn_id

  endpoint_config {
    is_public_ip_enabled = (local.cluster_endpoint_visibility == "Private") ? false : true
    subnet_id            = local.endpoint_subnet_id
    nsg_ids              = []
  }
  options {
    service_lb_subnet_ids = [local.lb_subnet_id]
    add_ons {
      is_kubernetes_dashboard_enabled = var.cluster_options_add_ons_is_kubernetes_dashboard_enabled
      is_tiller_enabled               = false # Default is false, left here for reference
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    kubernetes_network_config {
      services_cidr = lookup(var.network_cidrs, "KUBERNETES-SERVICE-CIDR")
      pods_cidr     = lookup(var.network_cidrs, "PODS-CIDR")
    }
  }
  image_policy_config {
    is_policy_enabled = false
  }
  kms_key_id = null
  type       = "ENHANCED_CLUSTER"
  count      = 1
}

resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster[0].id
  compartment_id     = local.oke_compartment_ocid
  kubernetes_version = (var.k8s_version == "Latest") ? local.node_pool_k8s_latest_version : var.k8s_version
  name               = var.node_pool_name
  node_shape         = var.node_pool_instance_shape.instanceShape
  ssh_public_key     = tls_private_key.oke_worker_node_ssh_key.public_key_openssh

  node_config_details {
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ADs.availability_domains

      content {
        availability_domain = placement_configs.value.name
        subnet_id           = local.node_subnet_id
      }
    }
    size = var.num_pool_workers
  }

  dynamic "node_shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      ocpus         = var.node_pool_instance_shape.ocpus
      memory_in_gbs = var.node_pool_instance_shape.memory
    }
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = local.first_compatible_image_id
    boot_volume_size_in_gbs = var.node_pool_boot_volume_size_in_gbs
  }


  initial_node_labels {
    key   = "name"
    value = var.node_pool_name
  }

  count = 1
}

locals {
  oke_compartment_ocid = var.compartment_ocid
}

# Local kubeconfig for when using Terraform locally. Not used by Oracle Resource Manager
resource "local_file" "oke_kubeconfig" {
  content  = data.oci_containerengine_cluster_kube_config.oke.content
  filename = "${path.module}/generated/kubeconfig"
}

# Generate ssh keys to access Worker Nodes, if generate_public_ssh_key=true, applies to the pool
resource "tls_private_key" "oke_worker_node_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Get OKE options
locals {
  cluster_k8s_latest_version   = reverse(sort(data.oci_containerengine_cluster_option.oke.kubernetes_versions))[0]
  node_pool_k8s_latest_version = reverse(sort(data.oci_containerengine_node_pool_option.oke.kubernetes_versions))[0]
  deployed_k8s_version         = (var.k8s_version == "Latest") ? local.cluster_k8s_latest_version : var.k8s_version
}

# Checks if is using Flexible Compute Shapes
locals {
  # Checks if is using Flexible Compute Shapes
  is_flexible_node_shape = contains(split(".", var.node_pool_instance_shape.instanceShape), "Flex")
}