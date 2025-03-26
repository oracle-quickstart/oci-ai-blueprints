

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

data "oci_containerengine_cluster_kube_config" "oke_special" {
  cluster_id = var.existent_oke_cluster_id
}

#data "kubernetes_ingress" "corrino_cp_ingress" {
#  metadata {
#    name      = local.app.backend_service_name_ingress
#    namespace = "default"
#  }
#
#  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
#  count = var.ingress_nginx_enabled ? 1 : 0
#}

#data "kubernetes_service" "corrino_cp_service" {
#  metadata {
#    name      = local.app.backend_service_name
#    namespace = "default"
#  }
#  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
#  count = var.ingress_nginx_enabled ? 1 : 0
#}

data "kubernetes_service" "ingress_nginx_controller_service" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "cluster-tools"
  }
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
  count = var.ingress_nginx_enabled ? 1 : 0
}

data "kubernetes_secret" "grafana_password" {
  metadata {
    name      = "grafana"
    namespace = "cluster-tools"
  }
  depends_on = [module.oke-quickstart.helm_release_grafana]
  count = var.grafana_enabled ? 1 : 0
}

