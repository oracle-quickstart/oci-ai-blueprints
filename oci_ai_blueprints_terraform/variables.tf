# Copyright (c) 2023 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

# -----------------------------------
# OCI
# -----------------------------------

variable "existent_oke_cluster_id" {}

variable "existent_vcn_ocid" {}

variable "existent_vcn_compartment_ocid" {}

variable "existent_oke_k8s_endpoint_subnet_ocid" {}

variable "existent_oke_nodes_subnet_ocid" {}

variable "existent_oke_load_balancer_subnet_ocid" {}

# -----------------------------------
# OCI
# -----------------------------------

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}

# -----------------------------------
# Corrino App
# -----------------------------------

# variable "app_name" {
#   type    = string
#   default = "work"
#   validation {
#     condition     = can(regex("^([A-Za-z0-9]){1,6}$", var.app_name))
#     error_message = "Please provide a Workspace Name (aka app_name) that is between 1 and 6 alphanumeric characters in length."
#   }
# 
# }

# variable "deploy_id" {
#   type    = string
#   default = "deploy"
#   validation {
#     condition     = can(regex("^([A-Za-z0-9]){1,6}$", var.deploy_id))
#     error_message = "Please provide a Deploy ID that is between 1 and 6 alphanumeric characters in length."
#   }

# }

variable "policy_creation_enabled" {
  description = "Create policies to enable apps to view and manage compute resources. If selected and user does not have permissions to create policies in root tenancy, build will fail."
  type        = bool
  default     = false
}

variable "stack_version" {
  type = string
}

variable "share_data_with_corrino_team_enabled" {
  description = "Allow this Terraform to send a small registration file to OCI AI Blueprints team."
  type        = bool
  default     = true
}

# -----------------------------------
# Corrino User
# -----------------------------------

variable "corrino_admin_username" {
  description = "The user name used to login to OCI AI Blueprints"
  type        = string
}

variable "corrino_admin_nonce" {
  description = "The password used to login to OCI AI Blueprints"
  type        = string
}

variable "corrino_admin_email" {
  description = "The email address used to identify the OCI AI Blueprints user"
  type        = string
}

# -----------------------------------
# Corrino FQDN
# -----------------------------------

# This is populated from schema.yaml from an enumeration with one of three possible values:
#    - nip.io
#    - corrino-oci.com
#    - custom

variable "fqdn_domain_mode_selector" {
  type    = string
  default = "nip.io"
}

variable "fqdn_custom_domain" {
  description = "Your custom FQDN can be a simple top-level domain or an A-Record for a top-level domain.  Either method requires that you modify the domain registrar records to send traffic to the load balancer public IP that is provisioned for you."
  type        = string
  default     = ""
}

# -----------------------------------
# Bring your own cluster
# -----------------------------------

variable "bring_your_own_cluster" {
  type    = bool
  default = false
}

variable "bring_your_own_grafana" {
  type    = bool
  default = false
}

variable "existent_grafana_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_prometheus" {
  type    = bool
  default = false
}

variable "existent_prometheus_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_mlflow" {
  type    = bool
  default = false
}

variable "existent_mlflow_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_nvidia_gpu_operator" {
  type    = bool
  default = false
}

variable "existent_nvidia_gpu_operator_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_metrics_server" {
  type    = bool
  default = false
}

variable "existent_metrics_server_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_keda" {
  type    = bool
  default = false
}

variable "existent_keda_namespace" {
  type    = string
  default = ""
}

variable "bring_your_own_lws" {
  type    = bool
  default = false
}

variable "bring_your_own_kueue" {
  type    = bool
  default = false
}

variable "existent_kueue_namespace" {
  type    = string
  default = ""
}


# -----------------------------------
# Helm
# -----------------------------------

variable "metrics_server_enabled" {
  type    = bool
  default = true
}
variable "ingress_nginx_enabled" {
  type    = bool
  default = true
}
variable "cert_manager_enabled" {
  type    = bool
  default = true
}
variable "prometheus_enabled" {
  type    = bool
  default = true
}
variable "grafana_enabled" {
  type    = bool
  default = true
}
variable "mlflow_enabled" {
  type    = bool
  default = true
}

# -----------------------------------
# Autonomous Database
# -----------------------------------

variable "oadb_admin_user_name" {
  default = "admin"
}
variable "oadb_admin_secret_name" {
  default = "oadb-admin"
}
variable "oadb_connection_secret_name" {
  default = "oadb-connection"
}
variable "oadb_wallet_secret_name" {
  default = "oadb-wallet"
}

variable "autonomous_database_cpu_core_count" {
  default = 1
}

variable "autonomous_database_data_storage_size_in_tbs" {
  default = 1
}

variable "autonomous_database_data_safe_status" {
  default = "NOT_REGISTERED" # REGISTERED || NOT_REGISTERED

  validation {
    condition     = var.autonomous_database_data_safe_status == "REGISTERED" || var.autonomous_database_data_safe_status == "NOT_REGISTERED"
    error_message = "Sorry, but database license model can only be REGISTERED or NOT_REGISTERED."
  }
}

variable "autonomous_database_db_version" {
  default = "19c"
}

variable "autonomous_database_license_model" {
  default = "LICENSE_INCLUDED" # LICENSE_INCLUDED || BRING_YOUR_OWN_LICENSE

  validation {
    condition     = var.autonomous_database_license_model == "BRING_YOUR_OWN_LICENSE" || var.autonomous_database_license_model == "LICENSE_INCLUDED"
    error_message = "Sorry, but database license model can only be BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED."
  }
}

variable "autonomous_database_is_auto_scaling_enabled" {
  default = false
}

variable "autonomous_database_is_free_tier" {
  default = false
}
variable "autonomous_database_visibility" {
  default = "Public"

  validation {
    condition     = var.autonomous_database_visibility == "Private" || var.autonomous_database_visibility == "Public"
    error_message = "Database visibility must be be Private or Public."
  }
}
variable "autonomous_database_wallet_generate_type" {
  default = "SINGLE"
}

