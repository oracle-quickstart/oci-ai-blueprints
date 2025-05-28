# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 


# Ingress/LoadBalancer variables
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
  default     = "100"
  description = "Enter the maximum size of the flexible shape (Should be bigger than minimum size). The maximum service limit is set by your tenancy limits."
}

## Resource Ingress examples
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
# Deployment Details + Freeform Tags + Defined Tags
variable "oci_tag_values" {
  description = "Tags to be added to the resources"
}

# Ingress-NGINX helm chart
## https://kubernetes.github.io/ingress-nginx/
## https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx
resource "helm_release" "ingress_nginx" {
  name          = "ingress-nginx"
  repository    = local.helm_repository.ingress_nginx
  chart         = "ingress-nginx"
  version       = local.helm_repository.ingress_nginx_version
  namespace     = kubernetes_namespace.cluster_tools.0.id
  # Need to wait for webhooks so we don't hit timing issues.
  wait          = true
  wait_for_jobs = true

  set {
    name  = "controller.metrics.enabled"
    value = true
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape"
    value = var.ingress_load_balancer_shape
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-min"
    value = var.ingress_load_balancer_shape_flex_min
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-max"
    value = var.ingress_load_balancer_shape_flex_max
    type  = "string"
  }

  count = var.ingress_nginx_enabled ? 1 : 0
}

## Kubernetes Service: ingress-nginx-controller
data "kubernetes_service" "ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.cluster_tools.0.id
  }
  depends_on = [helm_release.ingress_nginx]

  count = var.ingress_nginx_enabled ? 1 : 0
}

locals {
  ingress_controller_load_balancer_ip     = var.ingress_nginx_enabled ? data.kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip : "#Ingress_Controller_Not_Deployed"
  ingress_controller_load_balancer_ip_hex = var.ingress_nginx_enabled ? join("", formatlist("%02x", split(".", data.kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip))) : "#Ingress_Controller_Not_Deployed"
  # ingress_controller_load_balancer_hostname = var.ingress_nginx_enabled ? (data.kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.hostname == "" ?
  # (var.ingress_hosts_include_nip_io ? local.app_nip_io_domain : local.ingress_controller_load_balancer_ip) : data.kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.hostname) : "#Ingress_Controller_Not_Deployed"
  ingress_controller_load_balancer_hostname = var.ingress_nginx_enabled ? (
  var.ingress_hosts != "" ? local.ingress_hosts[0] : (var.ingress_hosts_include_nip_io ? local.app_nip_io_domain : local.ingress_controller_load_balancer_ip)) : "#Ingress_Controller_Not_Deployed"

  ingress_nginx_annotations_basic = {
    "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
  }
  ingress_nginx_annotations_tls = {
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
  }
  ingress_nginx_annotations_cert_manager = {
    "cert-manager.io/cluster-issuer"      = var.ingress_cluster_issuer
    "cert-manager.io/acme-challenge-type" = "http01"
  }
  ingress_nginx_annotations = merge(local.ingress_nginx_annotations_basic,
    var.ingress_tls ? local.ingress_nginx_annotations_tls : {},
    (var.ingress_tls && var.cert_manager_enabled) ? local.ingress_nginx_annotations_cert_manager : {}
  )
  ingress_hosts     = compact(concat(split(",", var.ingress_hosts), [local.app_nip_io_domain]))
  app_name          = var.oci_tag_values.freeformTags.AppName
  app_name_for_dns  = substr(lower(replace(local.app_name, "/\\W|_|\\s/", "")), 0, 6)
  app_nip_io_domain = (var.ingress_nginx_enabled && var.ingress_hosts_include_nip_io) ? format("${local.app_name_for_dns}.%s.${var.nip_io_domain}", local.ingress_controller_load_balancer_ip_hex) : ""
}

# Outputs
output "ingress_controller_load_balancer_ip" {
  value = local.ingress_controller_load_balancer_ip
}
# output "ingress_controller_load_balancer_ip_hex" {
#   value = local.ingress_controller_load_balancer_ip_hex
# }
output "ingress_controller_load_balancer_hostname" {
  value = local.ingress_controller_load_balancer_hostname
}

output "url_protocol" {
  value = var.ingress_tls ? "https" : "http"
}
# output "app_domain" {
#   value = (var.ingress_hosts != "") ? local.ingress_controller_load_balancer_hostname : (var.ingress_hosts_include_nip_io ? local.app_nip_io_domain : local.ingress_controller_load_balancer_hostname)
# }
# output "ingress_hosts" {
#   value = local.ingress_hosts
# }
