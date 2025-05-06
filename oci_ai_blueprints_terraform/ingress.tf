resource "kubernetes_ingress_v1" "corrino_cp_ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "corrino-cp-ingress"
    annotations = {
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.public_endpoint.api]
      secret_name = "corrino-cp-tls"
    }
    rule {
      host = local.public_endpoint.api
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.corrino_cp_service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "kubernetes_ingress_v1" "oci_ai_blueprints_portal_ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "oci-ai-blueprints-portal-ingress"
    annotations = {
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.public_endpoint.blueprint_portal]
      secret_name = "oci-ai-blueprints-portal-tls"
    }
    rule {
      host = local.public_endpoint.blueprint_portal
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.oci_ai_blueprints_portal_service.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "kubernetes_ingress_v1" "grafana_ingress" {
  wait_for_load_balancer = true
  metadata {
    name      = "grafana-ingress"
    namespace = "cluster-tools"
    annotations = {
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.public_endpoint.grafana]
      secret_name = "grafana-tls"
    }
    rule {
      host = local.public_endpoint.grafana
      http {
        path {
          path = "/"
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
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "kubernetes_ingress_v1" "prometheus_ingress" {
  wait_for_load_balancer = true
  metadata {
    name      = "prometheus-ingress"
    namespace = "cluster-tools"
    annotations = {
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.public_endpoint.prometheus]
      secret_name = "prometheus-tls"
    }
    rule {
      host = local.public_endpoint.prometheus
      http {
        path {
          path = "/"
          backend {
            service {
              name = "prometheus-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "kubernetes_ingress_v1" "mlflow_ingress" {
  wait_for_load_balancer = true
  metadata {
    name      = "mlflow-ingress"
    namespace = "cluster-tools"
    annotations = {
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.public_endpoint.mlflow]
      secret_name = "mlflow-tls"
    }
    rule {
      host = local.public_endpoint.mlflow
      http {
        path {
          path = "/"
          backend {
            service {
              name = "mlflow"
              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}
