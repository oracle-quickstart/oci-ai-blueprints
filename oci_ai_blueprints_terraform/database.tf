# Copyright (c) 2020, 2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

##**************************************************************************
##                        Autonomous Database
##**************************************************************************

### creates an ATP database
resource "oci_database_autonomous_database" "autonomous_database" {
  admin_password           = random_string.autonomous_database_admin_password.result
  compartment_id           = var.compartment_ocid
  compute_count            = var.autonomous_database_ecpu_count
  compute_model            = "ECPU" # OCPU is deprecated and there are not other options here.
  data_storage_size_in_tbs = var.autonomous_database_data_storage_size_in_tbs
  data_safe_status         = var.autonomous_database_data_safe_status
  db_version               = var.autonomous_database_db_version
  db_name                  = "${local.db.app_name_for_db}${local.oke.deploy_id}"
  display_name             = "${local.app_name} Db (${local.oke.deploy_id})"
  is_auto_scaling_enabled  = var.autonomous_database_is_auto_scaling_enabled
  is_dedicated             = var.autonomous_database_is_dedicated

  count = 1
  freeform_tags = local.corrino_tags
}


#### Wallet

resource "oci_database_autonomous_database_wallet" "autonomous_database_wallet" {
  autonomous_database_id = oci_database_autonomous_database.autonomous_database[0].id
  password               = random_string.autonomous_database_wallet_password.result
  generate_type          = var.autonomous_database_wallet_generate_type
  base64_encode_content  = true

  count = 1
  #  depends_on = [oci_database_autonomous_database.autonomous_database]
}

resource "kubernetes_secret" "oadb-admin" {
  metadata {
    name = var.oadb_admin_secret_name
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }
  data = {
    oadb_admin_pw = random_string.autonomous_database_admin_password.result
  }
  type = "Opaque"

  count = 1
  #  depends_on = [oci_database_autonomous_database.autonomous_database]
}

resource "kubernetes_secret" "oadb-connection" {
  metadata {
    name = var.oadb_connection_secret_name
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }
  data = {
    oadb_wallet_pw = random_string.autonomous_database_wallet_password.result
    oadb_service   = "${local.db.app_name_for_db}${local.oke.deploy_id}_TP"
  }
  type = "Opaque"

  count = 1
  #  depends_on = [oci_database_autonomous_database.autonomous_database]

}

### OADB Wallet extraction <>
resource "kubernetes_secret" "oadb_wallet_zip" {
  metadata {
    name = "oadb-wallet-zip"
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }
  data = {
    wallet = oci_database_autonomous_database_wallet.autonomous_database_wallet[0].content
  }
  type = "Opaque"

  count = 1
  #  depends_on = [oci_database_autonomous_database.autonomous_database,oci_database_autonomous_database_wallet.autonomous_database_wallet]

}

resource "kubernetes_cluster_role" "secret_creator" {
  metadata {
    name = "secret-creator"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "delete"]
  }

  #  count = var.mushop_mock_mode_all ? 0 : 1
  count = 1
}

resource "kubernetes_cluster_role_binding" "wallet_extractor_crb" {
  metadata {
    name = "wallet-extractor-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.secret_creator[0].metadata.0.name
  }
  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.wallet_extractor_sa[0].metadata.0.name
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }

  #  count = var.mushop_mock_mode_all ? 0 : 1
  count = 1
}

resource "kubernetes_service_account" "wallet_extractor_sa" {
  metadata {
    name = "wallet-extractor-sa"
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }
  secret {
    name = "wallet-extractor-sa-token"
  }

  #  count = var.mushop_mock_mode_all ? 0 : 1
  count = 1
}

resource "kubernetes_secret" "wallet_extractor_sa" {
  metadata {
    name = "wallet-extractor-sa-token"
    #    namespace = kubernetes_namespace.mushop_namespace.id
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.wallet_extractor_sa.0.metadata.0.name
    }
  }
  type = "kubernetes.io/service-account-token"

  #  count = var.mushop_mock_mode_all ? 0 : 1
  count = 1
}

resource "kubernetes_job" "wallet_extractor_job" {
  metadata {
    name = "wallet-extractor-job"
    #    namespace = kubernetes_namespace.mushop_namespace.id
  }
  spec {
    template {
      metadata {}
      spec {
        init_container {
          name    = "wallet-extractor"
          image   = "busybox"
          command = ["/bin/sh", "-c"]
          args    = ["base64 -d /tmp/zip/wallet > /tmp/wallet.zip && unzip /tmp/wallet.zip -d /wallet"]
          volume_mount {
            mount_path = "/tmp/zip"
            name       = "wallet-zip"
            read_only  = true
          }
          volume_mount {
            mount_path = "/wallet"
            name       = "wallet"
          }
        }
        container {
          name    = "wallet-binding"
          image   = "bitnami/kubectl"
          command = ["/bin/sh", "-c"]
          args    = ["kubectl delete secret oadb-wallet --ignore-not-found=true && kubectl create secret generic oadb-wallet --from-file=/wallet"]
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_secret.wallet_extractor_sa.0.metadata.0.name # kubernetes_service_account.wallet_extractor_sa[0].default_secret_name
            read_only  = true
          }
          volume_mount {
            mount_path = "/wallet"
            name       = "wallet"
            read_only  = true
          }
        }
        volume {
          name = kubernetes_secret.wallet_extractor_sa.0.metadata.0.name # kubernetes_service_account.wallet_extractor_sa[0].default_secret_name
          secret {
            secret_name = kubernetes_secret.wallet_extractor_sa.0.metadata.0.name # kubernetes_service_account.wallet_extractor_sa[0].default_secret_name
          }
        }
        volume {
          name = "wallet-zip"
          secret {
            secret_name = kubernetes_secret.oadb_wallet_zip[0].metadata.0.name
          }
        }
        volume {
          name = "wallet"
          empty_dir {}
        }
        restart_policy       = "Never"
        service_account_name = "wallet-extractor-sa"
      }
    }
    backoff_limit              = 1
    ttl_seconds_after_finished = 120
  }

  wait_for_completion = true
  timeouts {
    create = "20m"
    update = "20m"
  }

  #  depends_on = [kubernetes_deployment.cluster_autoscaler_deployment]
  depends_on = [oci_database_autonomous_database_wallet.autonomous_database_wallet]

  #  count = var.mushop_mock_mode_all ? 0 : 1
  count = 1
}
