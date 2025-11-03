resource "helm_release" "mlflow" {
  name       = "mlflow"
  repository = "https://community-charts.github.io/helm-charts"
  chart      = "mlflow"
  namespace  = "cluster-tools"
  wait       = false
  version    = "0.16.5"

  values = [
    <<EOF
extraVolumes:
  - name: mlflow-volume
    persistentVolumeClaim:
      claimName: mlflow-pvc

extraVolumeMounts:
  - name: mlflow-volume
    mountPath: /mlruns

extraArgs:
  backendStoreUri: file:///mlruns/store
  defaultArtifactRoot: /mlruns/artifacts

extraEnvVars:
  MLFLOW_TRACKING_URI: file:///mlruns/store
EOF
  ]

  depends_on = [kubernetes_persistent_volume_claim_v1.mlflow]
  count      = var.bring_your_own_mlflow ? 0 : 1
}

resource "kubernetes_persistent_volume_claim_v1" "mlflow" {
  metadata {
    name      = "mlflow-pvc"
    namespace = "cluster-tools"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "50Gi"
      }
    }

    storage_class_name = "oci-bv"
  }

  wait_until_bound = false

  timeouts {
    create = "5m"
  }

  depends_on = [kubernetes_ingress_v1.grafana_ingress]
  count      = var.bring_your_own_mlflow ? 0 : 1
}

resource "helm_release" "nvidia-dcgm" {
  name             = "nvidia-dcgm"
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  chart            = "gpu-operator"
  namespace        = "gpu-operator"
  create_namespace = true
  wait             = false
  version          = "v25.3.0"

  # Create the release if either DCGM or MIG is enabled.
  count = var.bring_your_own_nvidia_gpu_operator ? 0 : 1

  dynamic "set" {
    for_each = var.bring_your_own_nvidia_gpu_operator ? [] : [1]
    content {
      name  = "mig.strategy"
      value = "mixed"
    }
  }
}

resource "helm_release" "amd_device_metrics_exporter" {
  count             = var.bring_your_own_amd_metrics_exporter ? 0 : 1
  namespace         = "cluster-tools"
  name              = "amd-device-metrics-exporter"
  chart             = "device-metrics-exporter-charts"
  repository        = "https://rocm.github.io/device-metrics-exporter"
  version           = "v1.3.1"
  values            = ["${file("./files/amd-device-metrics-exporter/values.yaml")}"]
  create_namespace  = false
  recreate_pods     = true
  force_update      = true
  dependency_update = true
  wait              = false
  max_history       = 1
  depends_on        = [null_resource.webhook_charts_ready, module.oke-quickstart.helm_release_prometheus]
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  # Need to wait for webhooks so we don't hit timing issues.
  wait          = true
  wait_for_jobs = true
  version       = "2.17.0"

  count      = var.bring_your_own_keda ? 0 : 1
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "helm_release" "lws" {
  name             = "lws"
  repository       = "oci://registry.k8s.io/lws/charts"
  chart            = "lws"
  namespace        = "lws-system"
  create_namespace = true
  # Need to wait for webhooks so we don't hit timing issues.
  wait       = true
  version    = "0.7.0"
  verify     = false # Skip verification to avoid issues in OCI stacks
  count      = var.bring_your_own_lws ? 0 : 1
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}


resource "helm_release" "kueue" {
  name             = "kueue"
  repository       = "oci://registry.k8s.io/kueue/charts"
  chart            = "kueue"
  namespace        = "kueue-system"
  create_namespace = true
  # Critical: wait for all components including webhooks to be ready
  wait             = true
  wait_for_jobs    = true
  timeout          = 600   # 10 minutes timeout to ensure webhooks are ready
  disable_webhooks = false # Ensure webhooks are enabled
  verify           = false # Skip verification to avoid issues in OCI stacks
  version          = "0.11.4"

  # Ensure webhook readiness
  set {
    name  = "controllerManager.webhookService.port"
    value = "9443"
  }

  # Enable health checks 
  set {
    name  = "controllerManager.healthProbeBindAddress"
    value = ":8081"
  }

  # Set proper resource limits to ensure stability
  set {
    name  = "controllerManager.resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "controllerManager.resources.requests.memory"
    value = "256Mi"
  }

  count      = var.bring_your_own_kueue ? 0 : 1
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

# Data source to ensure Kueue webhook service exists before proceeding
data "kubernetes_service" "kueue_webhook" {
  count = var.bring_your_own_kueue ? 0 : 1

  metadata {
    name      = "kueue-webhook-service"
    namespace = "kueue-system"
  }

  depends_on = [helm_release.kueue]
}

resource "helm_release" "kong" {
  name             = "kong"
  repository       = "https://charts.konghq.com"
  chart            = "kong"
  namespace        = "kong"
  create_namespace = true
  wait             = true # must be true so that we can get load balancer ip for url.
  version          = "2.51.0"

  values = ["${file("./files/kong/values.yaml")}"]

  dynamic "set" {
    for_each = var.cluster_load_balancer_visibility == "Private" ? [1] : []
    content {
      name  = "proxy.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-internal"
      value = "true"
      type  = "string"
    }
  }

  count      = var.bring_your_own_kong ? 0 : 1
  depends_on = [null_resource.webhook_charts_ready]
}

