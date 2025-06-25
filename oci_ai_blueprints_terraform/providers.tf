# Copyright (c) 2023, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
  auth         = var.use_instance_principal ? "InstancePrincipal" : null

  user_ocid        = var.use_instance_principal ? null : var.user_ocid
  fingerprint      = var.use_instance_principal ? null : var.fingerprint
  private_key_path = var.use_instance_principal ? null : var.private_key_path
}

provider "oci" {
  alias        = "home_region"
  tenancy_ocid = var.tenancy_ocid
  region       = local.home_region
  auth         = var.use_instance_principal ? "InstancePrincipal" : null

  user_ocid        = var.use_instance_principal ? null : var.user_ocid
  fingerprint      = var.use_instance_principal ? null : var.fingerprint
  private_key_path = var.use_instance_principal ? null : var.private_key_path
}

# INTERPOLATION EFFORT
# INTERPOLATION EFFORT

# New configuration to avoid Terraform Kubernetes provider interpolation. https://registry.terraform.io/providers/hashicorp/kubernetes/2.2.0/docs#stacking-with-managed-kubernetes-cluster-resources
# Currently need to uncheck to refresh (--refresh=false) when destroying or else the terraform destroy will fail

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  insecure               = local.external_private_endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", local.cluster_id, "--region", local.cluster_region]
    command     = "oci"
  }
}

# INTERPOLATION EFFORT
# INTERPOLATION EFFORT

#provider "kubernetes" {
##  config_path = "${path.module}/generated/kubeconfig"
##  config_path = "~/.kube/config"
##  config_path = local_file.oke_kubeconfig.file.destination
#  config_path = local_file.oke_kubeconfig
##  config_path = data.oke_kubeconfig
##  depends_on = [local_file.oke_kubeconfig]
#}

# INTERPOLATION EFFORT
# INTERPOLATION EFFORT

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    insecure               = local.external_private_endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["ce", "cluster", "generate-token", "--cluster-id", local.cluster_id, "--region", local.cluster_region]
      command     = "oci"
    }
  }
}

#locals {
#  cluster_endpoint       = yamldecode(data.oci_containerengine_cluster_kube_config.kube_conf.content)["clusters"][0]["cluster"]["server"]
#  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.kube_conf.content)["clusters"][0]["cluster"]["certificate-authority-data"])
#  cluster_id             = yamldecode(data.oci_containerengine_cluster_kube_config.kube_conf.content)["users"][0]["user"]["exec"]["args"][4]
#  cluster_region         = yamldecode(data.oci_containerengine_cluster_kube_config.kube_conf.content)["users"][0]["user"]["exec"]["args"][6]
#  external_private_endpoint = false
#}

locals {
  cluster_endpoint          = yamldecode(data.oci_containerengine_cluster_kube_config.oke_special.content)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate    = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_special.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  cluster_id                = yamldecode(data.oci_containerengine_cluster_kube_config.oke_special.content)["users"][0]["user"]["exec"]["args"][4]
  cluster_region            = yamldecode(data.oci_containerengine_cluster_kube_config.oke_special.content)["users"][0]["user"]["exec"]["args"][6]
  external_private_endpoint = false
}

#locals {
#  cluster_endpoint          = yamldecode(module.corrino.kubeconfig)["clusters"][0]["cluster"]["server"]
#  external_private_endpoint = false
#  # cluster_endpoint = (var.cluster_endpoint_visibility == "Private") ? (
#  #   "https://${module.oke.orm_private_endpoint_oke_api_ip_address}:6443") : (
#  # yamldecode(module.oke.kubeconfig)["clusters"][0]["cluster"]["server"])
#  # external_private_endpoint = (var.cluster_endpoint_visibility == "Private") ? true : false
#  cluster_ca_certificate = base64decode(yamldecode(module.corrino.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])
#  cluster_id             = yamldecode(module.corrino.kubeconfig)["users"][0]["user"]["exec"]["args"][4]
#  cluster_region         = yamldecode(module.corrino.kubeconfig)["users"][0]["user"]["exec"]["args"][6]
#}


#Gets home and current regions
data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }
}

locals {
  home_region = lookup(data.oci_identity_regions.home_region.regions[0], "name")
}
