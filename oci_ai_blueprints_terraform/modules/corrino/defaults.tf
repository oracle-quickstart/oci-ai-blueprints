# Copyright (c) 2022-2023 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# File Version: 0.1.0

# Dependencies:
#   - terraform-oci-networking module

################################################################################
# If you have extra configurations to add, you can add them here.
# It's supported to include:
#   - Extra Node Pools and their configurations
#   - Extra subnets
#   - Extra route tables and security lists
################################################################################

################################################################################
# Deployment Defaults
################################################################################
locals {
#  deploy_id   = random_string.deploy_id.result
  deploy_id   = var.deploy_id
  deploy_tags = { "DeploymentID" = local.deploy_id, "AppName" = local.app_name, "Quickstart" = "terraform-oci-oke-quickstart", "OKEclusterName" = "${local.app_name} (${local.deploy_id})" }
  oci_tag_values = {
    "freeformTags" = merge(var.tag_values.freeformTags, local.deploy_tags),
    "definedTags"  = var.tag_values.definedTags
  }
  app_name            = var.app_name
  app_name_normalized = substr(replace(lower(local.app_name), " ", "-"), 0, 6)
  app_name_for_dns    = substr(lower(replace(local.app_name, "/\\W|_|\\s/", "")), 0, 6)
}

#resource "random_string" "deploy_id" {
#  length  = 4
#  special = false
#}

################################################################################
# Required locals for the oci-networking and oke modules
################################################################################
locals {
  node_pools                    = concat(local.node_pool_1, local.extra_node_pools, var.extra_node_pools)
  create_new_vcn                = (var.create_new_oke_cluster && var.create_new_vcn) ? true : false
  vcn_display_name              = "[${local.app_name}] VCN for OKE (${local.deploy_id})"
  create_subnets                = (var.create_subnets) ? true : false
  subnets                       = concat(local.subnets_oke, local.extra_subnets, var.extra_subnets)
  route_tables                  = concat(local.route_tables_oke, var.extra_route_tables)
  security_lists                = concat(local.security_lists_oke, var.extra_security_lists)
  resolved_vcn_compartment_ocid = (var.create_new_compartment_for_oke ? local.oke_compartment_ocid : var.compartment_ocid)
  pre_vcn_cidr_blocks           = split(",", var.vcn_cidr_blocks)
  vcn_cidr_blocks               = contains(module.vcn.cidr_blocks, local.pre_vcn_cidr_blocks[0]) ? distinct(concat([local.pre_vcn_cidr_blocks[0]], module.vcn.cidr_blocks)) : module.vcn.cidr_blocks
  
  # Calculate VCN prefix length to determine available bits for subnetting
  vcn_prefix_length = tonumber(split("/", local.vcn_cidr_blocks[0])[1])
  # Maximum bits available for subnetting (IPv4 limit is /32)
  max_available_bits = 32 - local.vcn_prefix_length
  
  # Flexible subnet bit calculations based on VCN size
  # For /16 VCN: use original calculations
  # For /24 VCN: use smaller subnet allocations
  endpoint_newbits = local.max_available_bits >= 12 ? 12 : local.max_available_bits >= 8 ? 8 : local.max_available_bits >= 4 ? 4 : 2
  nodes_newbits = local.max_available_bits >= 6 ? 6 : local.max_available_bits >= 4 ? 4 : 2
  lb_newbits = local.max_available_bits >= 6 ? 6 : local.max_available_bits >= 4 ? 4 : 2
  fss_newbits = local.max_available_bits >= 10 ? 10 : local.max_available_bits >= 6 ? 6 : local.max_available_bits >= 4 ? 4 : 2
  apigw_newbits = local.max_available_bits >= 8 ? 8 : local.max_available_bits >= 4 ? 4 : 2
  vcn_native_newbits = local.max_available_bits >= 1 ? 1 : 0
  bastion_newbits = local.max_available_bits >= 12 ? 12 : local.max_available_bits >= 8 ? 8 : local.max_available_bits >= 4 ? 4 : 2
  
  network_cidrs = {
    VCN-MAIN-CIDR                                  = local.vcn_cidr_blocks[0]                                                         # e.g.: "10.20.0.0/16" = 65536 usable IPs
    ENDPOINT-REGIONAL-SUBNET-CIDR                  = cidrsubnet(local.vcn_cidr_blocks[0], local.endpoint_newbits, 0)                 # Flexible endpoint subnet
    NODES-REGIONAL-SUBNET-CIDR                     = cidrsubnet(local.vcn_cidr_blocks[0], local.nodes_newbits, 1)                   # Flexible nodes subnet  
    LB-REGIONAL-SUBNET-CIDR                        = cidrsubnet(local.vcn_cidr_blocks[0], local.lb_newbits, 2)                      # Flexible LB subnet
    FSS-MOUNT-TARGETS-REGIONAL-SUBNET-CIDR         = cidrsubnet(local.vcn_cidr_blocks[0], local.fss_newbits, 3)                     # Flexible FSS subnet
    APIGW-FN-REGIONAL-SUBNET-CIDR                  = cidrsubnet(local.vcn_cidr_blocks[0], local.apigw_newbits, 4)                   # Flexible API Gateway subnet
    VCN-NATIVE-POD-NETWORKING-REGIONAL-SUBNET-CIDR = local.vcn_native_newbits > 0 ? cidrsubnet(local.vcn_cidr_blocks[0], local.vcn_native_newbits, 1) : "10.244.0.0/16" # Flexible VCN-native or fallback
    BASTION-REGIONAL-SUBNET-CIDR                   = cidrsubnet(local.vcn_cidr_blocks[0], local.bastion_newbits, 5)                 # Flexible bastion subnet
    PODS-CIDR                                      = "10.244.0.0/16"
    KUBERNETES-SERVICE-CIDR                        = "10.96.0.0/16"
    ALL-CIDR                                       = "0.0.0.0/0"
  }
}

################################################################################
# Extra OKE node pools
# Example commented out below
################################################################################
locals {
  extra_node_pools = [
    # {
    #   node_pool_name                            = "GPU" # Must be unique
    #   node_pool_autoscaler_enabled            = false
    #   node_pool_min_nodes                       = 1
    #   node_pool_max_nodes                       = 2
    #   node_k8s_version                          = var.k8s_version
    #   node_pool_shape                           = "BM.GPU.A10.4"
    #   node_pool_shape_specific_ad                = 3 # Optional, if not provided or set = 0, will be randomly assigned
    #   node_pool_node_shape_config_ocpus         = 1
    #   node_pool_node_shape_config_memory_in_gbs = 1
    #   node_pool_boot_volume_size_in_gbs         = "100"
    #   existent_oke_nodepool_id_for_autoscaler   = null
    #   node_pool_alternative_subnet              = null # Optional, name of previously created subnet
    #   image_operating_system                    = null
    #   image_operating_system_version            = null
    #   extra_initial_node_labels                 = [{ key = "app.pixel/gpu", value = "true" }]
    #   cni_type                                  = "FLANNEL_OVERLAY" # "FLANNEL_OVERLAY" or "OCI_VCN_IP_NATIVE"
    # },
  ]
}

locals {
  extra_subnets = [
    # {
    #   subnet_name                = "opensearch_subnet"
    #   cidr_block                 = cidrsubnet(local.vcn_cidr_blocks[0], 8, 35) # e.g.: "10.20.35.0/24" = 254 usable IPs (10.20.35.0 - 10.20.35.255)
    #   display_name               = "OCI OpenSearch Service subnet (${local.deploy_id})" # If null, is autogenerated
    #   dns_label                  = "opensearch${local.deploy_id}" # If null, disable dns label
    #   prohibit_public_ip_on_vnic = false
    #   prohibit_internet_ingress  = false
    #   route_table_id             = module.route_tables["public"].route_table_id # If null, the VCN's default route table is used
    #   alternative_route_table_name    = null # Optional, Name of the previously created route table
    #   dhcp_options_id            = module.vcn.default_dhcp_options_id # If null, the VCN's default set of DHCP options is used
    #   security_list_ids          = [module.security_lists["opensearch_security_list"].security_list_id] # If null, the VCN's default security list is used
    #   extra_security_list_names  = [] # Optional, Names of the previously created security lists
    #   ipv6cidr_block             = null # If null, no IPv6 CIDR block is assigned
    # },
  ]
}