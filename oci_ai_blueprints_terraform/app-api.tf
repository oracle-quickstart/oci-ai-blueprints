resource "kubernetes_service" "corrino_cp_service" {
  metadata {
    name = "corrino-cp"
    annotations = {
      "oci.oraclecloud.com/load-balancer-type"             = "lb"
      "service.beta.kubernetes.io/oci-load-balancer-shape" = "flexible"
    }
  }
  spec {
    selector = {
      app = "corrino-cp"
    }
    port {
      port        = 80
      target_port = 5000
    }
  }
  depends_on = [kubernetes_deployment.corrino_cp_deployment]
}

resource "kubernetes_deployment" "corrino_cp_deployment" {
  metadata {
    name = "corrino-cp"
    labels = {
      app = "corrino-cp"
    }
  }
  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "corrino-cp"
      }
    }
    template {
      metadata {
        labels = {
          app = "corrino-cp"
        }
      }
      spec {
        container {
          name              = "corrino-cp"
          image             = local.app.backend_image_uri
          image_pull_policy = "Always"

          dynamic "env" {
            for_each = local.env_universal
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_app_api
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_app_configmap
            content {
              name = env.value.name
              value_from {
                config_map_key_ref {
                  name = env.value.config_map_name
                  key  = env.value.config_map_key
                }
              }
            }
          }

          dynamic "env" {
            for_each = local.env_psql_configmap
            content {
              name = env.value.name
              value_from {
                config_map_key_ref {
                  name = env.value.config_map_name
                  key  = env.value.config_map_key
                }
              }
            }
          }

          # dynamic "env" {
          #   for_each = local.env_adb_access
          #   content {
          #     name  = env.value.name
          #     value = env.value.value
          #   }
          # }

          # dynamic "env" {
          #   for_each = local.env_adb_access_secrets
          #   content {
          #     name = env.value.name
          #     value_from {
          #       secret_key_ref {
          #         name = env.value.secret_name
          #         key  = env.value.secret_key
          #       }
          #     }
          #   }
          # }

          # volume_mount {
          #   name       = "adb-wallet-volume"
          #   mount_path = "/app/wallet"
          #   read_only  = true
          # }
        }
        # volume {
        #   name = "adb-wallet-volume"
        #   secret {
        #     secret_name = "oadb-wallet"
        #   }
        # }
      }
    }
  }
  depends_on = [kubernetes_job.corrino_migration_job]
}

