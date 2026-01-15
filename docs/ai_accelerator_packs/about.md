# About OCI AI Accelerator Packs

AI Accelerator packs are a full deployment OCI resource manager templates that deploy the necessary OCI services and Gen AI applications with optimizations to make Gen AI apps operational. AI Accelerator packs leverage OCI AI Blueprints as a platform to launch and manage the lifecycle of Gen AI applications. For more information please visit [product page.](https://www.oracle.com/artificial-intelligence/ai-accelerator-packs/?source=:eng:lw:ie::::AIAcceleratorPacksWebinar) 



## Available AI Accelerator Packs & Details

All AI Accelerator Packs will deploy the OCI AI Blueprints which includes open-source components like **Prometheus, Grafana, PosgreSQL, KEDA & MLFlow**. 
This list is updated frequently as we continue curating more. 

## Delivery Vehicle Route Optimizer

### Deployment Sizes & Services Required

Table with a list of sizes and supported packs.


| Deployment Size |  Component    |  Requirements           |       SKU      | Specs |  Quantity |
|--------------|--------------|-------------------------|---------------|-----------|--------|
| **SMALL**| OCI Core Compute | Nvidia A100 40 GB GPU | BM.GPU4.8  | 8 GPUs | 1
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=3, memory=64 | 2
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=4, memory=32 | 1
| |OCI Boot Volume | Boot Block Volume| NA  | 1 TB | 1
| |OCI Services | OCI Gen AI Services Shared EndPoint | Consumption based license
| |OCI Services | Oracle Kubernetes Engine (OKE) | NA |NA |1
| |NVIDIA AI Enterprise License & Software | cuOPT Libraries & NIM Containers | OCI Billed (attached to # of GPUs) | NA | 8 
| | OCI Software | OCI AI Blueprints | Free | 1 | NA
| **MEDIUM**| OCI Core Compute | Nvidia A100 80 GB GPU | BM.GPU.A100-v2.8  | 8 GPUs | 1
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=3, memory=64 | 2
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=4, memory=32 | 1
| |OCI Boot Volume | Boot Block Volume| NA  | 1 TB | 1
| |OCI Services | OCI Gen AI Services Shared EndPoint | Consumption based license
| |OCI Services | Oracle Kubernetes Engine (OKE) | NA |NA |1
| |NVIDIA AI Enterprise License & Software | cuOPT Libraries & NIM Containers | OCI Billed (attached to # of GPUs) | NA | 8 
| | OCI Software | OCI AI Blueprints | Free | 1 | NA

Other necessary VNET , public IP, load balancers and subnets are required. 

## Video Search & Summarization (VSS)

### Deployment Sizes & Services Required

Table with a list of sizes and supported packs.


| Deployment Size |  Component    |  Requirements           |       SKU      | Specs |  Quantity |
|--------------|--------------|-------------------------|---------------|-----------|--------|
| **SMALL**| OCI Core Compute | Nvidia A100 40 GB GPU | BM.GPU4.8  | 8 GPUs | 1
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=32, memory=128 | 1
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=3, memory=64 | 2
| |OCI Boot Volume | Boot Block Volume| NA  | 300 GB | 1
| |OCI Services | Oracle Kubernetes Engine (OKE) | NA |NA |1
| |NVIDIA AI Enterprise License & Software | NVIDIA Cosmos Reasoning, Parakeet, Related NIMs , Reranker Models| OCI Billed (attached to # of GPUs) |  NA | 8|
| OCI Software | OCI AI Blueprints | Free | 1 | NA | NA


Other necessary VNET , public IP, load balancers and subnets are required. 

## AI-Q: Enterprise Reasoning Chat Agent IaaS Self-Hosted

### Deployment Sizes & Services Required

Table with a list of sizes and supported packs.


| Deployment Size |  Component    |  Requirements           |       SKU      | Specs |  Quantity |
|--------------|--------------|-------------------------|---------------|-----------|--------|
| **SMALL**| OCI Core Compute | Nvidia A100 40 GB GPU | BM.GPU4.8  | 8 GPUs | 2
| | | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=4, memory=32 | 2
| |OCI Boot Volume | Boot Block Volume| NA  | 300 GB | 2
| |OCI Services | Oracle Kubernetes Engine (OKE) | NA |NA |1
| |NVIDIA AI Enterprise License & Software | NVIDIA NIMs | OCI Billed (attached to # of GPUs)| NA |16 
| | OCI Software | OCI AI Blueprints | Free | 1


Other necessary VNET , public IP, load balancers and subnets are required. 

## AI-Q: Enterprise Reasoning Chat Agent With Shared Services

### Deployment Sizes & Services Required

Table with a list of sizes and supported packs.


| Deployment Size |  Component    |  Requirements           |       SKU      | Specs |  Quantity |
|--------------|--------------|-------------------------|---------------|-----------|--------|
| **SMALL**| OCI Core Compute | CPU VM Flex | VM.Standard.E5.Flex  | ocpus=4, memory=32 | 2
| |OCI Boot Volume | Boot Block Volume| NA  | 300 GB | 2
| |OCI Services | Oracle Kubernetes Engine (OKE) | NA |NA |1
| |OCI Services | Oracle 26 AI | NA | ecpu=4 |1
| |Open Source Software | Meta LLama Stack | Free | NA | NA
| | OCI Software | OCI AI Blueprints | Free | NA | NA |


Other necessary VNET , public IP, load balancers and subnets are required. 
