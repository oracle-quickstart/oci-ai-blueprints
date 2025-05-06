# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Grafana variables
variable "grafana_enabled" {
  default     = true
  description = "Enable Grafana Dashboards. Includes example dashboards and Prometheus, OCI Logging and OCI Metrics datasources"
}

# Grafana Helm chart
## https://github.com/grafana/helm-charts/blob/main/charts/grafana/README.md
## https://artifacthub.io/packages/helm/grafana/grafana
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = local.helm_repository.grafana
  chart      = "grafana"
  version    = local.helm_repository.grafana_version
  namespace  = kubernetes_namespace.cluster_tools.0.id
  wait       = false

  set {
    name  = "grafana\\.ini.server.root_url"
    value = "%(protocol)s://%(domain)s:%(http_port)s/grafana"
    type  = "string"
  }

  set {
    name  = "grafana\\.ini.server.serve_from_sub_path"
    value = "true"
  }

  values = [
    <<EOF
dashboards:
  default:
    k8s-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    k8s-cluster-metrics:
      gnetId: 11663
      revision: 1
      datasource: Prometheus
    k8s-cluster-metrics-simple:
      gnetId: 6417
      revision: 1
      datasource: Prometheus
    k8s-pods-monitoring:
      gnetId: 13498
      revision: 1
      datasource: Prometheus
    k8s-memory:
      gnetId: 13421
      revision: 1
      datasource: Prometheus
    k8s-networking:
      gnetId: 12658
      revision: 1
      datasource: Prometheus
    k8s-cluster-autoscaler:
      gnetId: 3831
      revision: 1
      datasource: Prometheus
    k8s-hpa:
      gnetId: 10257
      revision: 1
      datasource: Prometheus
    k8s-pods:
      gnetId: 6336
      revision: 1
      datasource: Prometheus
    spring-boot:
      gnetId: 12464
      revision: 2
      datasource: Prometheus
    nginx-ingress-controller:
      gnetId: 9614
      revision: 1
      datasource: Prometheus
    oci-compute:
      gnetId: 13596
      revision: 1
      datasource: Oracle Cloud Infrastructure Metrics
    oci-oke:
      gnetId: 13594
      revision: 1
      datasource: Oracle Cloud Infrastructure Metrics
    nvidia-dcgm:
      gnetId: 12239
      revision: 2
      datasource: Prometheus
dashboardProviders:
   dashboardproviders.yaml:
     apiVersion: 1
     providers:
     - name: 'default'
       orgId: 1
       folder: ''
       type: file
       disableDeletion: true
       editable: true
       options:
         path: /var/lib/grafana/dashboards/default
sidecar:
  datasources:
    enabled: true
    label: grafana_datasource
  dashboards:
    enabled: true
    label: grafana_dashboard
persistence:
  enabled: true
  existingClaim: grafana-pvc
plugins:
  - oci-logs-datasource
  - oci-metrics-datasource
  - grafana-kubernetes-app
  - grafana-worldmap-panel
  - grafana-piechart-panel
  - btplc-status-dot-panel
datasources: 
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.${coalesce(var.existent_prometheus_namespace, kubernetes_namespace.cluster_tools.0.id)}.svc.cluster.local
      access: proxy
      isDefault: true
      disableDeletion: true
      editable: false
    - name: Oracle Cloud Infrastructure Metrics
      type: oci-metrics-datasource
      access: proxy
      disableDeletion: true
      editable: true
      jsonData:
        tenancyOCID: ${var.tenancy_ocid}
        defaultRegion: ${var.region}
        environment: "OCI Instance"
    - name: Oracle Cloud Infrastructure Logs
      type: oci-logs-datasource
      access: proxy
      disableDeletion: true
      editable: true
      jsonData:
        tenancyOCID: ${var.tenancy_ocid}
        defaultRegion: ${var.region}
        environment: "OCI Instance"
EOF
  ]

  depends_on = [kubernetes_persistent_volume_claim_v1.grafana]
  count = var.grafana_enabled ? 1 : 0
}

resource "kubernetes_config_map" "vllm_dashboard" {
  metadata {
    name      = "vllm-custom-dashboard"
    namespace = kubernetes_namespace.cluster_tools[0].id
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "vllm-dashboard.json" = file("${path.module}/dashboards/vllm-dashboard.json")
  }
}

resource "kubernetes_persistent_volume_claim_v1" "grafana" {
  metadata {
    name      = "grafana-pvc"
    namespace = kubernetes_namespace.cluster_tools.0.id
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "50Gi"
      }
    }

    storage_class_name = "oci-bv"
  }

  wait_until_bound = false

  timeouts {
    create = "5m"
  }

  depends_on = [ kubernetes_persistent_volume_claim_v1.prometheus ]
  count = var.grafana_enabled ? 1 : 0
}

## Grafana Ingress
resource "kubernetes_ingress_v1" "grafana" {
  wait_for_load_balancer = true
  metadata {
    name        = "grafana"
    namespace   = kubernetes_namespace.cluster_tools.0.id
    annotations = local.ingress_nginx_annotations
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    dynamic "rule" {
      for_each = local.ingress_hosts
      content {
        host = rule.value
        http {
          path {
            path      = "/grafana(/|$)(.*)"
            path_type = "Prefix"
            backend {
              service {
                name = "grafana"
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "grafana-${var.ingress_cluster_issuer}-tls"
      hosts       = local.ingress_hosts
    }
  }
  depends_on = [helm_release.ingress_nginx, helm_release.grafana]

  count = (var.grafana_enabled && var.ingress_nginx_enabled) ? 1 : 0
}

## Kubernetes Secret: Grafana Admin Password
data "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.cluster_tools.0.id
  }
  depends_on = [helm_release.grafana]

  count = var.grafana_enabled ? 1 : 0
}

locals {
  grafana_admin_password = var.grafana_enabled ? data.kubernetes_secret.grafana.0.data.admin-password : "Grafana_Not_Deployed"
}

output "grafana_admin_password" {
  value     = var.grafana_enabled ? nonsensitive(local.grafana_admin_password) : "Grafana_Not_Deployed"
}
