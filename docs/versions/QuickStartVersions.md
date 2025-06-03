# OCI AI Blueprints Quickstart Software Versions

The following table describes software versions for tagged releases of this quickstart software repository, with most recent tags listed first.

This will be replaced as soon as we start tagging. Wanted framework in place.

<details>
<summary><strong>v1.0.2</strong></summary>

## Cluster Creation Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.5       |
|    Provider    |      oci       |      oracle/oci      |        >=5        |
|    Provider    |   kubernetes   | hashicorp/kubernetes |      >=2.27       |
|    Provider    |      helm      |    hashicorp/helm    |      >=2.12       |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |       >=2.5       |
|    Provider    |     random     |   hashicorp/random   |       >=3.6       |

### Oracle Services

|         Service          | Version |
| :----------------------: | :-----: |
| Oracle Kubernetes Engine | v1.31.1 |

---

---

## OCI AI Blueprints Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.1       |
|    Provider    |      oci       |      oracle/oci      | 4 <= version < 5  |
|    Provider    |   kubernetes   | hashicorp/kubernetes |        >=2        |
|    Provider    |      helm      |    hashicorp/helm    |        >=2        |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |        >=2        |
|    Provider    |     random     |   hashicorp/random   |        >=3        |

### Helm Chart Versions

|     Chart Name      | Version |                     Chart URL                      |
| :-----------------: | :-----: | :------------------------------------------------: |
|       Grafana       | 6.47.1  |       https://grafana.github.io/helm-charts        |
|     Prometheus      | 19.0.1  | https://prometheus-community.github.io/helm-charts |
|   Metrics Server    |  3.8.3  |  https://kubernetes-sigs.github.io/metrics-server  |
|    Ingress Nginx    |  4.4.0  |     https://kubernetes.github.io/ingress-nginx     |
|       MLFlow        | 0.16.5  |   https://community-charts.github.io/helm-charts   |
| NVIDIA GPU Operator | v25.3.0 |         https://helm.ngc.nvidia.com/nvidia         |
|        Keda         | 2.17.0  |         https://kedacore.github.io/charts          |
|   LeaderWorkerSet   |  0.1.0  |                       local                        |
|        Kueue        | 0.11.4  |         oci://registry.k8s.io/kueue/charts         |

### Container Versions

| Container                | Version |                     Repository                     |
| :----------------------- | :-----: | :------------------------------------------------: |
| oci-corrino-cp           | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |
| oci-ai-blueprints-portal | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |

### Oracle Services

|          Service           | Version |
| :------------------------: | :-----: |
| Oracle Autonomous Database |   19c   |

</details>
<details>
<summary><strong>v1.0.1</strong></summary>

## Cluster Creation Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.5       |
|    Provider    |      oci       |      oracle/oci      |        >=5        |
|    Provider    |   kubernetes   | hashicorp/kubernetes |      >=2.27       |
|    Provider    |      helm      |    hashicorp/helm    |      >=2.12       |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |       >=2.5       |
|    Provider    |     random     |   hashicorp/random   |       >=3.6       |

### Oracle Services

|         Service          | Version |
| :----------------------: | :-----: |
| Oracle Kubernetes Engine | v1.31.1 |

---

---

## OCI AI Blueprints Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.1       |
|    Provider    |      oci       |      oracle/oci      | 4 <= version < 5  |
|    Provider    |   kubernetes   | hashicorp/kubernetes |        >=2        |
|    Provider    |      helm      |    hashicorp/helm    |        >=2        |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |        >=2        |
|    Provider    |     random     |   hashicorp/random   |        >=3        |

### Helm Chart Versions

|     Chart Name      | Version |                     Chart URL                      |
| :-----------------: | :-----: | :------------------------------------------------: |
|       Grafana       | 6.47.1  |       https://grafana.github.io/helm-charts        |
|     Prometheus      | 19.0.1  | https://prometheus-community.github.io/helm-charts |
|   Metrics Server    |  3.8.3  |  https://kubernetes-sigs.github.io/metrics-server  |
|    Ingress Nginx    |  4.4.0  |     https://kubernetes.github.io/ingress-nginx     |
|       MLFlow        | 0.16.5  |   https://community-charts.github.io/helm-charts   |
| NVIDIA GPU Operator | v25.3.0 |         https://helm.ngc.nvidia.com/nvidia         |
|        Keda         | 2.17.0  |         https://kedacore.github.io/charts          |
|   LeaderWorkerSet   |  0.1.0  |                       local                        |
|        Kueue        | 0.11.4  |         oci://registry.k8s.io/kueue/charts         |

### Container Versions

| Container                | Version |                     Repository                     |
| :----------------------- | :-----: | :------------------------------------------------: |
| oci-corrino-cp           | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |
| oci-ai-blueprints-portal | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |

### Oracle Services

|          Service           | Version |
| :------------------------: | :-----: |
| Oracle Autonomous Database |   19c   |

</details>

<details>
<summary><strong>release-2025-05-16</strong></summary>

## Cluster Creation Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.5       |
|    Provider    |      oci       |      oracle/oci      |        >=5        |
|    Provider    |   kubernetes   | hashicorp/kubernetes |      >=2.27       |
|    Provider    |      helm      |    hashicorp/helm    |      >=2.12       |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |       >=2.5       |
|    Provider    |     random     |   hashicorp/random   |       >=3.6       |

### Oracle Services

|         Service          | Version |
| :----------------------: | :-----: |
| Oracle Kubernetes Engine | v1.31.1 |

---

---

## OCI AI Blueprints Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.1       |
|    Provider    |      oci       |      oracle/oci      | 4 <= version < 5  |
|    Provider    |   kubernetes   | hashicorp/kubernetes |        >=2        |
|    Provider    |      helm      |    hashicorp/helm    |        >=2        |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |        >=2        |
|    Provider    |     random     |   hashicorp/random   |        >=3        |

### Helm Chart Versions

|     Chart Name      | Version |                     Chart URL                      |
| :-----------------: | :-----: | :------------------------------------------------: |
|       Grafana       | 6.47.1  |       https://grafana.github.io/helm-charts        |
|     Prometheus      | 19.0.1  | https://prometheus-community.github.io/helm-charts |
|   Metrics Server    |  3.8.3  |  https://kubernetes-sigs.github.io/metrics-server  |
|    Ingress Nginx    |  4.4.0  |     https://kubernetes.github.io/ingress-nginx     |
|       MLFlow        | 0.16.5  |   https://community-charts.github.io/helm-charts   |
| NVIDIA GPU Operator | v25.3.0 |         https://helm.ngc.nvidia.com/nvidia         |
|        Keda         | 2.17.0  |         https://kedacore.github.io/charts          |
|   LeaderWorkerSet   |  0.1.0  |                       local                        |
|        Kueue        | 0.11.4  |         oci://registry.k8s.io/kueue/charts         |

### Container Versions

| Container                | Version |                     Repository                     |
| :----------------------- | :-----: | :------------------------------------------------: |
| oci-corrino-cp           | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |
| oci-ai-blueprints-portal | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |

### Oracle Services

|          Service           | Version |
| :------------------------: | :-----: |
| Oracle Autonomous Database |   19c   |

</details>

<details>
<summary><strong>release-2025-04-22</strong></summary>

## Cluster Creation Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.5       |
|    Provider    |      oci       |      oracle/oci      |        >=5        |
|    Provider    |   kubernetes   | hashicorp/kubernetes |      >=2.27       |
|    Provider    |      helm      |    hashicorp/helm    |      >=2.12       |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |       >=2.5       |
|    Provider    |     random     |   hashicorp/random   |       >=3.6       |

### Oracle Services

|         Service          | Version |
| :----------------------: | :-----: |
| Oracle Kubernetes Engine | v1.31.1 |

---

---

## OCI AI Blueprints Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.1       |
|    Provider    |      oci       |      oracle/oci      | 4 <= version < 5  |
|    Provider    |   kubernetes   | hashicorp/kubernetes |        >=2        |
|    Provider    |      helm      |    hashicorp/helm    |        >=2        |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |        >=2        |
|    Provider    |     random     |   hashicorp/random   |        >=3        |

### Helm Chart Versions

|     Chart Name      | Version |                     Chart URL                      |
| :-----------------: | :-----: | :------------------------------------------------: |
|       Grafana       | 6.47.1  |       https://grafana.github.io/helm-charts        |
|     Prometheus      | 19.0.1  | https://prometheus-community.github.io/helm-charts |
|   Metrics Server    |  3.8.3  |  https://kubernetes-sigs.github.io/metrics-server  |
|    Ingress Nginx    |  4.4.0  |     https://kubernetes.github.io/ingress-nginx     |
|       MLFlow        | 0.16.5  |   https://community-charts.github.io/helm-charts   |
| NVIDIA GPU Operator | v25.3.0 |         https://helm.ngc.nvidia.com/nvidia         |
|        Keda         | 2.17.0  |         https://kedacore.github.io/charts          |
|   LeaderWorkerSet   |  0.1.0  |                       local                        |

### Container Versions

| Container                | Version |                     Repository                     |
| :----------------------- | :-----: | :------------------------------------------------: |
| oci-corrino-cp           | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |
| oci-ai-blueprints-portal | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |

### Oracle Services

|          Service           | Version |
| :------------------------: | :-----: |
| Oracle Autonomous Database |   19c   |

</details>

<details>
<summary><strong>release-2025-04-01</strong></summary>

## Cluster Creation Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.5       |
|    Provider    |      oci       |      oracle/oci      |        >=5        |
|    Provider    |   kubernetes   | hashicorp/kubernetes |      >=2.27       |
|    Provider    |      helm      |    hashicorp/helm    |      >=2.12       |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |       >=2.5       |
|    Provider    |     random     |   hashicorp/random   |       >=3.6       |

### Oracle Services

|         Service          | Version |
| :----------------------: | :-----: |
| Oracle Kubernetes Engine | v1.31.1 |

---

---

## OCI AI Blueprints Terraform

### Terraform / Provider Versions

| Component Type | Component Name |   Component Source   | Component Version |
| :------------: | :------------: | :------------------: | :---------------: |
|    Language    |   Terraform    |      hashicorp       |       >=1.1       |
|    Provider    |      oci       |      oracle/oci      | 4 <= version < 5  |
|    Provider    |   kubernetes   | hashicorp/kubernetes |        >=2        |
|    Provider    |      helm      |    hashicorp/helm    |        >=2        |
|    Provider    |      tls       |    hashicorp/tls     |        >=4        |
|    Provider    |     local      |   hashicorp/local    |        >=2        |
|    Provider    |     random     |   hashicorp/random   |        >=3        |

### Helm Chart Versions

|     Chart Name      | Version |                     Chart URL                      |
| :-----------------: | :-----: | :------------------------------------------------: |
|       Grafana       | 6.47.1  |       https://grafana.github.io/helm-charts        |
|     Prometheus      | 19.0.1  | https://prometheus-community.github.io/helm-charts |
|   Metrics Server    |  3.8.3  |  https://kubernetes-sigs.github.io/metrics-server  |
|    Ingress Nginx    |  4.4.0  |     https://kubernetes.github.io/ingress-nginx     |
|       MLFlow        | 0.16.5  |   https://community-charts.github.io/helm-charts   |
| NVIDIA GPU Operator | v25.3.0 |         https://helm.ngc.nvidia.com/nvidia         |
|        Keda         | 2.17.0  |         https://kedacore.github.io/charts          |

### Container Versions

| Container                | Version | Repository                                         |
| :----------------------- | :------ | :------------------------------------------------- |
| oci-corrino-cp           | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |
| oci-ai-blueprints-portal | latest  | iad.ocir.io/iduyx1qnmway/corrino-devops-repository |

### Oracle Services

|          Service           | Version |
| :------------------------: | :-----: |
| Oracle Autonomous Database |   19c   |

</details>
