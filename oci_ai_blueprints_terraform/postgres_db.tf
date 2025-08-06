# PostgreSQL Database Resources
# Deployed to support the Corrino Control Plane

# ConfigMap for PostgreSQL configuration
resource "kubernetes_config_map" "postgres_secret" {
  metadata {
    name = "bp-postgres-secret"
    labels = {
      app = "bp-postgres"
    }
  }

  data = {
    POSTGRES_DB       = local.postgres_db.db_name
    POSTGRES_USER     = local.postgres_db.user
    POSTGRES_PASSWORD = local.postgres_db.password
  }
}

# PersistentVolumeClaim for PostgreSQL data
resource "kubernetes_persistent_volume_claim_v1" "postgresql_pv_claim" {
  metadata {
    name = "bp-postgresql-pv-claim"
  }

  spec {
    storage_class_name = "oci-bv"
    access_modes       = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }

  wait_until_bound = false

  timeouts {
    create = "5m"
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres" {
  metadata {
    name = "bp-postgres"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "bp-postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "bp-postgres"
        }
      }

      spec {
        # Init container to prepare data directory
        init_container {
          name  = "init-pgdata-dir"
          image = "docker.io/library/busybox:1.34"
          
          command = [
            "sh",
            "-c",
            "mkdir -p /var/lib/postgresql/data/pgdata && chown -R 999:999 /var/lib/postgresql/data"
          ]

          volume_mount {
            name       = "bp-postgresdata"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        # PostgreSQL container
        container {
          name              = "bp-postgres"
          image             = "docker.io/library/postgres:14"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres_secret.metadata[0].name
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "bp-postgresdata"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "bp-postgresdata"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgresql_pv_claim.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map.postgres_secret,
    kubernetes_persistent_volume_claim_v1.postgresql_pv_claim
  ]
}

# PostgreSQL Service (ClusterIP - cluster-internal access)
# Creates cluster-internal DNS name: postgres.default.svc.cluster.local
resource "kubernetes_service" "postgres" {
  metadata {
    name = "bp-postgres"
    labels = {
      app = "bp-postgres"
    }
  }

  spec {
    # type = "ClusterIP"  # Default type, can be omitted
    
    selector = {
      app = "bp-postgres"
    }

    port {
      name        = "postgres"
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
  }

  depends_on = [kubernetes_deployment.postgres]
}

# Data source to get the service information (used in locals.tf)
data "kubernetes_service" "postgres_service" {
  metadata {
    name = kubernetes_service.postgres.metadata[0].name
  }

  depends_on = [kubernetes_service.postgres]
}
