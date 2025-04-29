# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

# Prometheus variables
variable "prometheus_enabled" {
  default     = true
  description = "Enable Prometheus"
}

variable "existent_prometheus_namespace" {
  default     = ""
  description = "Existing prometheus namespace if bringing your own cluster."
}

# Prometheus Helm chart
## https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/README.md
## https://artifacthub.io/packages/helm/prometheus-community/prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = local.helm_repository.prometheus
  chart      = "prometheus"
  version    = local.helm_repository.prometheus_version
  namespace  = kubernetes_namespace.cluster_tools.0.id
  wait       = false


  values = [
    <<EOF
extraScrapeConfigs: |
    - job_name: 'ingress-nginx'
      metrics_path: /metrics
      scrape_interval: 5s
      static_configs:
        - targets:
          - ingress-nginx-controller-metrics:9913
nodeExporter:
  hostRootfs: false

server:
  persistentVolume:
    enabled: true
    existingClaim: prometheus-pvc

EOF
  ]

  depends_on = [kubernetes_persistent_volume_claim_v1.prometheus]
  count = var.prometheus_enabled ? 1 : 0
}

resource "kubernetes_persistent_volume_claim_v1" "prometheus" {
  metadata {
    name      = "prometheus-pvc"
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
  count = var.prometheus_enabled ? 1 : 0
}
