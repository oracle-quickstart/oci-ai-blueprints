
resource "kubernetes_deployment" "corrino_cp_background_deployment" {
  metadata {
    name = "corrino-cp-background"
    labels = {
      app = "corrino-cp-background"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "corrino-cp-background"
      }
    }
    template {
      metadata {
        labels = {
          app = "corrino-cp-background"
        }
      }
      spec {
        container {
          name              = "corrino-cp-background"
          image             = local.app.backend_image_uri
          image_pull_policy = "Always"
          command           = ["/bin/sh", "-c"]
          args              = ["python3 manage.py runserver"]
          dynamic "env" {
            for_each = local.env_universal
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_app_api_background
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

          dynamic "env" {
            for_each = local.env_adb_access
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_adb_access_secrets
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name = env.value.secret_name
                  key  = env.value.secret_key
                }
              }
            }
          }

          volume_mount {
            name       = "adb-wallet-volume"
            mount_path = "/app/wallet"
            read_only  = true
          }
        }
        volume {
          name = "adb-wallet-volume"
          secret {
            secret_name = "oadb-wallet"
          }
        }
      }
    }
  }
  depends_on = [kubernetes_job.corrino_migration_job]
}

