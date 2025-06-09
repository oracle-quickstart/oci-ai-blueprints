resource "kubernetes_config_map" "corrino-configmap" {
  metadata {
    name = "corrino-configmap"
  }


  data = {
    APP_IMAGE_URI                                  = local.app.backend_image_uri
    ADDON_GRAFANA_TOKEN                            = local.addon.grafana_token
    ADDON_GRAFANA_USER                             = local.addon.grafana_user
    BACKEND_SERVICE_NAME                           = local.app.backend_service_name
    COMPARTMENT_ID                                 = local.oci.compartment_id
    CONTROL_PLANE_VERSION                          = var.stack_version
    RELEASE_VERSION                                = var.stack_version
    DJANGO_ALLOWED_HOSTS                           = local.django.allowed_hosts
    DJANGO_CSRF_TRUSTED_ORIGINS                    = local.django.csrf_trusted_origins
    DJANGO_SECRET                                  = local.django.secret
    FRONTEND_HTTPS_FLAG                            = local.app.https_flag
    IMAGE_REGISTRY_BASE_URI                        = local.ocir.base_uri
    LOGGING_LEVEL                                  = local.django.logging_level
    NAMESPACE_NAME                                 = local.oci.namespace_name
    OKE_CLUSTER_ID                                 = local.oci.oke_cluster_id
    OKE_NODE_SUBNET_ID                             = local.network.oke_node_subnet_id
    PUBLIC_ENDPOINT_BASE                           = local.fqdn.name
    RECIPE_BUCKET_NAME                             = local.app.recipe_bucket_name
    RECIPE_VALIDATION_ENABLED                      = local.app.recipe_validation_enabled
    RECIPE_VALIDATION_SHAPE_AVAILABILITY_ENABLED   = local.app.recipe_validation_shape_availability_enabled
    REGION_NAME                                    = local.oci.region_name
    TENANCY_ID                                     = local.oci.tenancy_id
    TENANCY_NAMESPACE                              = local.oci.tenancy_namespace
    DATA_UPLOAD_PATH                               = var.share_data_with_corrino_team_enabled ? local.registration.upload_path : ""
    DEPLOYMENT_UUID                                = random_uuid.registration_id.result
    DATA_SHARING_ENABLED                           = var.share_data_with_corrino_team_enabled ? "True" : "False"
    BLUEPRINTS_OBJECT_STORAGE_URL                  = local.app.blueprints_object_storage_url
    PORTAL_DEMO_FLAG                               = local.app.portal_demo_flag
    SHARED_NODE_POOL_BLUEPRINTS_OBJECT_STORAGE_URL = local.app.shared_node_pool_blueprints_object_storage_url
    SHARED_NODE_POOL_DOCUMENTATION_URL             = local.app.shared_node_pool_documentation_url
    BLUEPRINT_DOCUMENTATION_URL                    = local.app.blueprint_documentation_url
    PROMETHEUS_NAMESPACE                           = local.third_party_namespaces.prometheus_namespace
    POSTGRES_HOST                                  = local.postgres_db.host
    POSTGRES_PORT                                  = local.postgres_db.port
    POSTGRES_DB                                    = local.postgres_db.db_name
    POSTGRES_USER                                  = local.postgres_db.user
    POSTGRES_PASSWORD                              = local.postgres_db.password
  }
}
