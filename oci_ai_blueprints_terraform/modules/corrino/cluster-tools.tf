# Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

################################################################################
# Module: Kubernetes Cluster Tools
################################################################################
module "cluster-tools" {
  source = "./modules/cluster-tools"

  # Oracle Cloud Infrastructure Tenancy and Compartment OCID
  tenancy_ocid = var.tenancy_ocid
  # compartment_ocid = var.compartment_ocid
  region = var.region

  # Deployment Tags + Freeform Tags + Defined Tags
  oci_tag_values = local.oci_tag_values

  # Cluster Tools
  ## Namespace
  cluster_tools_namespace = "cluster-tools"

  ## Ingress Controller
  ingress_nginx_enabled                = var.ingress_nginx_enabled
  ingress_load_balancer_shape          = var.ingress_load_balancer_shape
  ingress_load_balancer_shape_flex_min = var.ingress_load_balancer_shape_flex_min
  ingress_load_balancer_shape_flex_max = var.ingress_load_balancer_shape_flex_max

  ## Ingress
  ingress_hosts                = var.ingress_hosts
  ingress_tls                  = var.ingress_tls
  ingress_cluster_issuer       = var.ingress_cluster_issuer
  ingress_email_issuer         = var.ingress_email_issuer
  ingress_hosts_include_nip_io = var.ingress_hosts_include_nip_io
  nip_io_domain                = var.nip_io_domain

  ## Cert Manager
  cert_manager_enabled = var.cert_manager_enabled

  ## Metrics Server
  metrics_server_enabled = var.metrics_server_enabled

  ## Prometheus
  prometheus_enabled            = var.prometheus_enabled
  existent_prometheus_namespace = var.existent_prometheus_namespace

  ## Grafana
  grafana_enabled = var.grafana_enabled

  depends_on = [module.oke, module.oke_node_pools, module.oke_cluster_autoscaler]
}

# Kubernetes Cluster Tools
## IngressController/LoadBalancer
variable "ingress_nginx_enabled" {
  default     = true
  description = "Enable Ingress Nginx for Kubernetes Services (This option provision a Load Balancer)"
}
variable "ingress_load_balancer_shape" {
  default     = "flexible" # Flexible, 10Mbps, 100Mbps, 400Mbps or 8000Mps
  description = "Shape that will be included on the Ingress annotation for the OCI Load Balancer creation"
}
variable "ingress_load_balancer_shape_flex_min" {
  default     = "10"
  description = "Enter the minimum size of the flexible shape."
}
variable "ingress_load_balancer_shape_flex_max" {
  default     = "100" # From 10 to 8000. Cannot be lower than ingress_load_balancer_shape_flex_min
  description = "Enter the maximum size of the flexible shape (Should be bigger than minimum size). The maximum service limit is set by your tenancy limits."
}
## Ingresses
variable "ingress_hosts" {
  default     = ""
  description = "Enter a valid full qualified domain name (FQDN). You will need to map the domain name to the EXTERNAL-IP address on your DNS provider (DNS Registry type - A). If you have multiple domain names, include separated by comma. e.g.: mushop.example.com,catshop.com"
}
variable "ingress_hosts_include_nip_io" {
  default     = true
  description = "Include app_name.HEXXX.nip.io on the ingress hosts. e.g.: mushop.HEXXX.nip.io"
}
variable "nip_io_domain" {
  default     = "nip.io"
  description = "Dynamic wildcard DNS for the application hostname. Should support hex notation. e.g.: nip.io"
}
variable "ingress_tls" {
  default     = false
  description = "If enabled, will generate SSL certificates to enable HTTPS for the ingress using the Certificate Issuer"
}
variable "ingress_cluster_issuer" {
  default     = "letsencrypt-prod"
  description = "Certificate issuer type. Currently supports the free Let's Encrypt and Self-Signed. Only *letsencrypt-prod* generates valid certificates"
}
variable "ingress_email_issuer" {
  default     = "no-reply@example.cloud"
  description = "You must replace this email address with your own. The certificate provider will use this to contact you about expiring certificates, and issues related to your account."
}

## Cert Manager
variable "cert_manager_enabled" {
  default     = false
  description = "Enable x509 Certificate Management"
}

## Metrics Server
variable "metrics_server_enabled" {
  default     = true
  description = "Enable Metrics Server for Metrics, HPA, VPA and Cluster Autoscaler"
}

## Prometheus
variable "prometheus_enabled" {
  default     = false
  description = "Enable Prometheus"
}

variable "existent_prometheus_namespace" {
  default     = ""
  description = "Existing prometheus namespace if bringing your own cluster"
}

## Grafana
variable "grafana_enabled" {
  default     = false
  description = "Enable Grafana Dashboards. Includes example dashboards and Prometheus, OCI Logging and OCI Metrics datasources"
}

# Cluster Tools Outputs
## grafana
output "grafana_admin_password" {
  value     = module.cluster-tools.grafana_admin_password
}

## Ingress Controller
locals {
  app_domain   = module.cluster-tools.ingress_controller_load_balancer_hostname
  url_protocol = module.cluster-tools.url_protocol
}

output "grafana_url" {
  value       = (var.grafana_enabled && var.ingress_nginx_enabled) ? format("${local.url_protocol}://%s/grafana", local.app_domain) : null
  description = "Grafana Dashboards URL"
}

output "app_url" {
  value       = (var.ingress_nginx_enabled) ? format("${local.url_protocol}://%s", local.app_domain) : null
  description = "Application URL"
}
