## Kueue 

- To install Kueue : `helm install kueue oci://registry.k8s.io/kueue/charts/kueue --version="0.11.4" --create-namespace --namespace=kueue-system for kueue helm installation `
- Namespace - Name of the teams , each team has a namespace file
- Resoruce Falvor- How you label your shapes, For example here we have a100 bc I labelled the nodes as a100, you can use the shape that comes with OCI 
- Cluster kueue - quotas for each team., gpu number , cpu number, memory etc
- Local kueue - Mapping your jobs ot the cluster queue
- Prioirity class - definition of what is high priority and low priority
- Job - whatever job you want to run, example vllm inference on 1 gpu / 8 gpus

- Cohort : To define which team is important and how team "a" can use team "b"


