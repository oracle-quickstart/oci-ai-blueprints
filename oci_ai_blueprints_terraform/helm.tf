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

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  # Need to wait for webhooks so we don't hit timing issues.
  wait             = true
  wait_for_jobs    = true
  version          = "2.17.0"

  count = var.bring_your_own_keda ? 0 : 1
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

resource "helm_release" "lws" {
  name             = "lws"
  chart            = "${path.module}/lws" # Use the local path to the chart folder
  namespace        = "lws-system"
  create_namespace = true
  wait             = false
  version          = "0.1.0" // Optional: specify the version if needed

  count = var.bring_your_own_lws ? 0 : 1
}


resource "helm_release" "kueue" {
  name             = "kueue"
  repository       = "oci://registry.k8s.io/kueue/charts"
  chart            = "kueue"
  namespace        = "kueue-system"
  create_namespace = true
  # Need to wait for webhooks so we don't hit timing issues.
  wait             = true
  wait_for_jobs    = true
  version          = "0.11.4"

  count      = var.bring_your_own_kueue ? 0 : 1
  depends_on = [module.oke-quickstart.helm_release_ingress_nginx]
}

