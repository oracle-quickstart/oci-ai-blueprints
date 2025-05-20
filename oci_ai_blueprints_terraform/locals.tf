locals {

  ts = timestamp()

  app_name = random_string.generated_workspace_name.result

  deploy_id = random_string.generated_deployment_name.result

  app = {
    backend_service_name         = "corrino-cp"
    backend_service_name_origin  = "http://corrino-cp"
    backend_service_name_ingress = "corrino-cp-ingress"
    #    backend_image_uri_base                       = join(":", [local.ocir.base_uri, local.ocir.backend_image])
    backend_image_uri = format("${local.ocir.base_uri}:${local.ocir.backend_image}-${var.stack_version}")
    #frontend_image_uri                           = join(":", [local.ocir.base_uri, local.ocir.frontend_image])
    blueprint_portal_image_uri                     = format("${local.ocir.base_uri}:${local.ocir.blueprint_portal_image}-${var.stack_version}")
    recipe_bucket_name                             = "corrino-recipes"
    recipe_validation_enabled                      = "True"
    recipe_validation_shape_availability_enabled   = "True"
    https_flag                                     = "False"
    portal_demo_flag                               = "False"
    blueprints_object_storage_url                  = "https://iduyx1qnmway.objectstorage.us-ashburn-1.oci.customer-oci.com/n/iduyx1qnmway/b/blueprints/o/blueprints.json"
    shared_node_pool_blueprints_object_storage_url = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/Fg9xXHJ0jreGQlI7t0tjjbHQ4TTZrtMb8vEaaN1apQn1JrtPk-iXzxXFXhfTMv6F/n/iduyx1qnmway/b/blueprints/o/shared_node_pools.json"
    shared_node_pool_documentation_url             = "https://github.com/oracle-quickstart/oci-ai-blueprints/tree/main/docs/shared_node_pools"
    blueprint_documentation_url                    = "https://github.com/oracle-quickstart/oci-ai-blueprints/tree/main/docs/api_documentation"
  }

  registration = {
    #object_filename = format("corrino-registration-%s", random_string.registration_id.result)
    object_filename = "corrino_registration.json"
    object_filepath = format("%s/%s", abspath(path.root), random_uuid.registration_id.result)
    object_content = jsonencode({
      "Registration ID"       = random_uuid.registration_id.result
      "Deploy DateTime"       = local.ts
      "Administrator"         = var.corrino_admin_email
      "Workspace Name"        = local.app_name
      "Deploy ID"             = local.deploy_id
      "Control Plane Version" = var.stack_version
      "FQDN"                  = local.fqdn.name
      "Tenancy OCID"          = local.oci.tenancy_id
      "OKE Cluster OCID"      = local.oke.cluster_ocid
      "Region"                = local.oci.region_name
    })
    upload_path = "https://objectstorage.us-ashburn-1.oraclecloud.com/p/bqCfQwvzAZPCnxehCZs1Le5V2Pajn3j4JsFzb5CWHRNvtQ4Je-Lk_ApwCcurdpYT/n/iduyx1qnmway/b/corrino-terraform-registry/o/${random_uuid.registration_id.result}/"
  }

  corrino_tags = {
    "corrino_installed" = timestamp()
    "corrino_uuid"      = random_uuid.registration_id.result
  }

  oke = {
    deploy_id    = local.deploy_id
    cluster_ocid = var.existent_oke_cluster_id
  }

  db = {
    app_name_for_db = regex("[[:alnum:]]{1,10}", local.app_name)
  }

  addon = {
    grafana_user  = "admin"
    grafana_token = module.oke-quickstart.grafana_admin_password
  }

  django = {
    logging_level        = "DEBUG"
    secret               = random_string.corrino_django_secret.result
    allowed_hosts        = join(",", [local.network.localhost, local.network.loopback, local.public_endpoint.api, local.app.backend_service_name])
    csrf_trusted_origins = join(",", [local.network.localhost_origin, local.network.loopback_origin, local.public_endpoint.api_origin_secure, local.public_endpoint.api_origin_insecure, local.app.backend_service_name_origin])
  }

  oci = {
    tenancy_id        = var.tenancy_ocid
    tenancy_namespace = data.oci_objectstorage_namespace.ns.namespace
    namespace_name    = data.oci_objectstorage_namespace.ns.namespace
    compartment_id    = var.compartment_ocid
    oke_cluster_id    = local.oke.cluster_ocid
    region_name       = var.region
  }

  network = {
    localhost          = "localhost"
    localhost_origin   = "http://localhost"
    loopback           = "127.0.0.1"
    loopback_origin    = "http://127.0.0.1"
    external_ip        = var.ingress_nginx_enabled ? data.kubernetes_service.ingress_nginx_controller_service.0.status.0.load_balancer.0.ingress.0.ip : "#Ingress_Not_Deployed"
    oke_node_subnet_id = var.existent_oke_nodes_subnet_ocid
  }

  registry = {
    subdomain                = "iad.ocir.io"
    name                     = "corrino-devops-repository"
    source_tenancy_namespace = "iduyx1qnmway"
  }

  ocir = {
    base_uri      = join("/", [local.registry.subdomain, local.registry.source_tenancy_namespace, local.registry.name])
    backend_image = "oci-corrino-cp"
    #frontend_image         = "corrino-portal"
    blueprint_portal_image = "oci-ai-blueprints-portal"
    cli_util_amd64_image   = "oci-util-amd64"
    cli_util_arm64_image   = "oci-util-arm64"
    pod_util_amd64_image   = "pod-util-amd64"
    pod_util_arm64_image   = "pod-util-arm64"
  }

  domain = {
    corrino_oci_mode = "corrino-oci.com"
    corrino_oci_fqdn = format("%s.corrino-oci.com", random_string.subdomain.result)

    nip_io_mode = "nip.io"
    nip_io_fqdn = format("%s.nip.io", replace(local.network.external_ip, ".", "-"))

    custom_mode = "custom"
    custom_fqdn = var.fqdn_custom_domain
  }

  fqdn = {
    name                = var.fqdn_domain_mode_selector == local.domain.custom_mode ? local.domain.custom_fqdn : (var.fqdn_domain_mode_selector == local.domain.nip_io_mode ? local.domain.nip_io_fqdn : local.domain.corrino_oci_fqdn)
    is_nip_io_mode      = var.fqdn_domain_mode_selector == local.domain.nip_io_mode ? true : false
    is_corrino_com_mode = var.fqdn_domain_mode_selector == local.domain.corrino_oci_mode ? true : false
    is_custom_mode      = var.fqdn_domain_mode_selector == local.domain.custom_mode ? true : false
  }

  public_endpoint = {
    api                 = join(".", ["api", local.fqdn.name])
    api_origin_insecure = join(".", ["http://api", local.fqdn.name])
    api_origin_secure   = join(".", ["https://api", local.fqdn.name])
    #portal              = join(".", ["portal", local.fqdn.name])
    blueprint_portal = join(".", ["blueprints", local.fqdn.name])
    mlflow           = join(".", ["mlflow", local.fqdn.name])
    prometheus       = join(".", ["prometheus", local.fqdn.name])
    grafana          = join(".", ["grafana", local.fqdn.name])
  }

  third_party_namespaces = {
    prometheus_namespace = var.bring_your_own_prometheus ? var.existent_prometheus_namespace : data.kubernetes_namespace.cluster_tools_namespace.0.id
  }

  env_universal = [
    {
      name  = "OCI_CLI_PROFILE"
      value = "instance_principal"
    },
    {
      name  = "TERRAFORM_TIMESTAMP"
      value = local.ts
    }
  ]

  env_app_jobs = [
    {
      name  = "CP_BACKGROUND_PROCESSING_ENABLED"
      value = "False"
    }
  ]

  env_app_user = [
    {
      name  = "DJANGO_SUPERUSER_USERNAME"
      value = var.corrino_admin_username
    },
    {
      name  = "DJANGO_SUPERUSER_PASSWORD"
      value = var.corrino_admin_nonce
    },
    {
      name  = "DJANGO_SUPERUSER_EMAIL"
      value = var.corrino_admin_email
    }
  ]

  env_adb_access = [
    {
      name  = "ADB_USER"
      value = var.oadb_admin_user_name
    },
    {
      name  = "TNS_ADMIN"
      value = "/app/wallet"
    }
  ]

  env_app_api = [
    {
      name  = "CP_BACKGROUND_PROCESSING_ENABLED"
      value = "False"
    }
  ]

  env_app_api_background = [
    {
      name  = "CP_BACKGROUND_PROCESSING_ENABLED"
      value = "True"
    }
  ]

  env_app_configmap = [
    {
      name            = "ADDON_GRAFANA_TOKEN"
      config_map_name = "corrino-configmap"
      config_map_key  = "ADDON_GRAFANA_TOKEN"
    },
    {
      name            = "ADDON_GRAFANA_USER"
      config_map_name = "corrino-configmap"
      config_map_key  = "ADDON_GRAFANA_USER"
    },
    {
      name            = "APP_IMAGE_URI"
      config_map_name = "corrino-configmap"
      config_map_key  = "APP_IMAGE_URI"
    },
    {
      name            = "BACKEND_SERVICE_NAME"
      config_map_name = "corrino-configmap"
      config_map_key  = "BACKEND_SERVICE_NAME"
    },
    {
      name            = "COMPARTMENT_ID"
      config_map_name = "corrino-configmap"
      config_map_key  = "COMPARTMENT_ID"
    },
    {
      name            = "CONTROL_PLANE_VERSION"
      config_map_name = "corrino-configmap"
      config_map_key  = "CONTROL_PLANE_VERSION"
    },
    {
      name            = "DJANGO_ALLOWED_HOSTS"
      config_map_name = "corrino-configmap"
      config_map_key  = "DJANGO_ALLOWED_HOSTS"
    },
    {
      name            = "DJANGO_CSRF_TRUSTED_ORIGINS"
      config_map_name = "corrino-configmap"
      config_map_key  = "DJANGO_CSRF_TRUSTED_ORIGINS"
    },
    {
      name            = "DJANGO_SECRET"
      config_map_name = "corrino-configmap"
      config_map_key  = "DJANGO_SECRET"
    },
    {
      name            = "FRONTEND_HTTPS_FLAG"
      config_map_name = "corrino-configmap"
      config_map_key  = "FRONTEND_HTTPS_FLAG"
    },
    {
      name            = "IMAGE_REGISTRY_BASE_URI"
      config_map_name = "corrino-configmap"
      config_map_key  = "IMAGE_REGISTRY_BASE_URI"
    },
    {
      name            = "LOGGING_LEVEL"
      config_map_name = "corrino-configmap"
      config_map_key  = "LOGGING_LEVEL"
    },
    {
      name            = "NAMESPACE_NAME"
      config_map_name = "corrino-configmap"
      config_map_key  = "NAMESPACE_NAME"
    },
    {
      name            = "OKE_CLUSTER_ID"
      config_map_name = "corrino-configmap"
      config_map_key  = "OKE_CLUSTER_ID"
    },
    {
      name            = "OKE_NODE_SUBNET_ID"
      config_map_name = "corrino-configmap"
      config_map_key  = "OKE_NODE_SUBNET_ID"
    },
    {
      name            = "PUBLIC_ENDPOINT_BASE"
      config_map_name = "corrino-configmap"
      config_map_key  = "PUBLIC_ENDPOINT_BASE"
    },
    {
      name            = "RECIPE_BUCKET_NAME"
      config_map_name = "corrino-configmap"
      config_map_key  = "RECIPE_BUCKET_NAME"
    },
    {
      name            = "RECIPE_VALIDATION_ENABLED"
      config_map_name = "corrino-configmap"
      config_map_key  = "RECIPE_VALIDATION_ENABLED"
    },
    {
      name            = "RECIPE_VALIDATION_SHAPE_AVAILABILITY_ENABLED"
      config_map_name = "corrino-configmap"
      config_map_key  = "RECIPE_VALIDATION_SHAPE_AVAILABILITY_ENABLED"
    },
    {
      name            = "REGION_NAME"
      config_map_name = "corrino-configmap"
      config_map_key  = "REGION_NAME"
    },
    {
      name            = "TENANCY_ID"
      config_map_name = "corrino-configmap"
      config_map_key  = "TENANCY_ID"
    },
    {
      name            = "TENANCY_NAMESPACE"
      config_map_name = "corrino-configmap"
      config_map_key  = "TENANCY_NAMESPACE"
    },
    {
      name            = "API_BASE_URL"
      config_map_name = "corrino-configmap"
      config_map_key  = "BACKEND_SERVICE_NAME"
    },
    {
      name            = "PORTAL_DEMO_FLAG"
      config_map_name = "corrino-configmap"
      config_map_key  = "PORTAL_DEMO_FLAG"
    },
    {
      name            = "BLUEPRINTS_OBJECT_STORAGE_URL"
      config_map_name = "corrino-configmap"
      config_map_key  = "BLUEPRINTS_OBJECT_STORAGE_URL"
    },
    {
      name            = "SHARED_NODE_POOL_BLUEPRINTS_OBJECT_STORAGE_URL"
      config_map_name = "corrino-configmap"
      config_map_key  = "SHARED_NODE_POOL_BLUEPRINTS_OBJECT_STORAGE_URL"
    },
    {
      name            = "SHARED_NODE_POOL_DOCUMENTATION_URL"
      config_map_name = "corrino-configmap"
      config_map_key  = "SHARED_NODE_POOL_DOCUMENTATION_URL"
    },
    {
      name            = "BLUEPRINT_DOCUMENTATION_URL"
      config_map_name = "corrino-configmap"
      config_map_key  = "BLUEPRINT_DOCUMENTATION_URL"
    },
    {
      name            = "DATA_SHARING_ENABLED"
      config_map_name = "corrino-configmap"
      config_map_key  = "DATA_SHARING_ENABLED"
    },
    {
      name            = "DATA_UPLOAD_PATH"
      config_map_name = "corrino-configmap"
      config_map_key  = "DATA_UPLOAD_PATH"
    },
    {
      name            = "DEPLOYMENT_UUID"
      config_map_name = "corrino-configmap"
      config_map_key  = "DEPLOYMENT_UUID"
    },
    {
      name            = "PROMETHEUS_NAMESPACE"
      config_map_name = "corrino-configmap"
      config_map_key  = "PROMETHEUS_NAMESPACE"
    }
  ]

  env_adb_access_secrets = [
    {
      name        = "ADB_NAME"
      secret_name = var.oadb_connection_secret_name
      secret_key  = "oadb_service"
    },
    {
      name        = "ADB_WALLET_PASSWORD"
      secret_name = var.oadb_connection_secret_name
      secret_key  = "oadb_wallet_pw"
    },
    {
      name        = "ADB_USER_PASSWORD"
      secret_name = var.oadb_admin_secret_name
      secret_key  = "oadb_admin_pw"
    }
  ]

}



