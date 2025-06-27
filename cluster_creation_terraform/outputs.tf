# Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Data sources for existing network resources when using bring_your_own mode
data "oci_core_vcn" "existing_vcn" {
  count  = var.network_configuration_mode == "bring_your_own" ? 1 : 0
  vcn_id = var.existing_vcn_id
}

data "oci_core_subnet" "existing_endpoint_subnet" {
  count     = var.network_configuration_mode == "bring_your_own" ? 1 : 0
  subnet_id = var.existing_endpoint_subnet_id
}

data "oci_core_subnet" "existing_node_subnet" {
  count     = var.network_configuration_mode == "bring_your_own" ? 1 : 0
  subnet_id = var.existing_node_subnet_id
}

data "oci_core_subnet" "existing_lb_subnet" {
  count     = var.network_configuration_mode == "bring_your_own" ? 1 : 0
  subnet_id = var.existing_lb_subnet_id
}

output "cluster_creation_stack_version" {
  value = file("${path.module}/CLUSTER_CREATION_STACK_VERSION")
}

output "oke_cluster_name" {
  value = oci_containerengine_cluster.oke_cluster[0].name
}

output "oke_cluster_id" {
  value = oci_containerengine_cluster.oke_cluster[0].id
}

output "oci_ai_blueprints_link_for_button" {
  value = local.oci_ai_blueprints_link
}

output "oci_ai_blueprints_link_for_section" {
  value = local.oci_ai_blueprints_link
}

output "vcn_name" {
  value = var.network_configuration_mode == "bring_your_own" ? data.oci_core_vcn.existing_vcn[0].display_name : oci_core_virtual_network.oke_vcn[0].display_name
}

output "vcn_id" {
  value = local.vcn_id
}

output "node_subnet_name" {
  value = var.network_configuration_mode == "bring_your_own" ? data.oci_core_subnet.existing_node_subnet[0].display_name : oci_core_subnet.oke_nodes_subnet[0].display_name
}

output "node_subnet_id" {
  value = local.node_subnet_id
}

output "lb_subnet_name" {
  value = var.network_configuration_mode == "bring_your_own" ? data.oci_core_subnet.existing_lb_subnet[0].display_name : oci_core_subnet.oke_lb_subnet[0].display_name
}

output "lb_subnet_id" {
  value = local.lb_subnet_id
}

output "endpoint_subnet_name" {
  value = var.network_configuration_mode == "bring_your_own" ? data.oci_core_subnet.existing_endpoint_subnet[0].display_name : oci_core_subnet.oke_k8s_endpoint_subnet[0].display_name
}

output "endpoint_subnet_id" {
  value = local.endpoint_subnet_id
}

