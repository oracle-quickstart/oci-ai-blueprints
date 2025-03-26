resource "kubernetes_job" "corrino_user_job" {
  metadata {
    name      = "corrino-user-job"
  }
  spec {
    template {
      metadata {}
      spec {

        container {
          name    = "corrino-user-job"
          image   = local.app.backend_image_uri
          image_pull_policy = "Always"
          command = ["/bin/sh", "-c"]
          args = ["python3 manage.py create_superuser_if_needed"]

          dynamic "env" {
            for_each = local.env_universal
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_app_user
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          dynamic "env" {
            for_each = local.env_app_jobs
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
            secret_name  = "oadb-wallet"
          }
        }

        restart_policy = "Never"
      }
    }
    backoff_limit              = 0
    ttl_seconds_after_finished = 120
  }

  wait_for_completion        = true
  timeouts {
    create = "10m"
    update = "10m"
  }

  depends_on = [kubernetes_job.corrino_migration_job]

  #  count = var.mushop_mock_mode_all ? 0 : 1
}