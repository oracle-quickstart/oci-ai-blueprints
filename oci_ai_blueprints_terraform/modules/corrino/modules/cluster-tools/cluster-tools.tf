# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Create namespace cluster-tools for supporting services
resource "kubernetes_namespace" "cluster_tools" {
  metadata {
    name = var.cluster_tools_namespace
  }

  count = local.use_cluster_tools_namespace ? 1 : 0
}

locals {
  # Helm repos
  # Updated versions for K8s v1.34+ compatibility (incl. docker.io registry for image pulls)
  helm_repository = {
    ingress_nginx          = "https://kubernetes.github.io/ingress-nginx"
    ingress_nginx_version  = "4.13.3"
    jetstack               = "https://charts.jetstack.io" # cert-manager
    jetstack_version       = "1.10.1"                     # cert-manager
    grafana                = "https://grafana.github.io/helm-charts"
    grafana_version        = "10.1.4"
    prometheus             = "https://prometheus-community.github.io/helm-charts"
    prometheus_version     = "27.42.2"
    metrics_server         = "https://kubernetes-sigs.github.io/metrics-server"
    metrics_server_version = "3.8.3"
  }
  use_cluster_tools_namespace = anytrue([var.grafana_enabled, var.ingress_nginx_enabled, var.cert_manager_enabled, var.prometheus_enabled]) ? true : false
}

# OCI Provider
variable "tenancy_ocid" {}
# variable "compartment_ocid" {}
variable "region" {}

# Namespace
variable "cluster_tools_namespace" {
  default = "cluster-tools"
}

