# Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

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
  value = var.oci_ai_blueprints_link_variable
}

output "oci_ai_blueprints_link_for_section" {
  value = var.oci_ai_blueprints_link_variable
}

output "vcn_name" {
  value = oci_core_virtual_network.oke_vcn[0].display_name
}

output "vcn_id" {
  value = oci_core_virtual_network.oke_vcn[0].id
}

output "node_subnet_name" {
  value = oci_core_subnet.oke_nodes_subnet[0].display_name
}

output "node_subnet_id" {
  value = oci_core_subnet.oke_nodes_subnet[0].id
}

output "lb_subnet_name" {
  value = oci_core_subnet.oke_lb_subnet[0].display_name
}

output "lb_subnet_id" {
  value = oci_core_subnet.oke_lb_subnet[0].id
}

output "endpoint_subnet_name" {
  value = oci_core_subnet.oke_k8s_endpoint_subnet[0].display_name
}

output "endpoint_subnet_id" {
  value = oci_core_subnet.oke_k8s_endpoint_subnet[0].id
}

