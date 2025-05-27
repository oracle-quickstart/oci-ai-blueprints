# Known Issues & Solutions

Place to record issues that arise and there corresponding workarounds.

## 500 Errors When Connecting to API

1. Check your permissions and verify that they match exactly as shown here: [IAM Policies](../iam_policies)
2. Did you choose `*.nip.io` as your domain name when setting up OCI AI Blueprints? If so, this is an untrusted domain and will be blocked when behind VPN. Either choose to deploy OCI AI Blueprints via custom domain or access your `*.nip.io` OCI AI Blueprints domain outside of VPN

## Shape BM.GPU4.8 Cannot Schedule Blueprints

Currently, there is an Oracle Kubernetes Engine (OKE) bug with the `BM.GPU4.8` shape. Since the toolkit runs on top of an OKE cluster, this shape cannot be used with the toolkit until the issue is resolved by OKE. We have diagnosed and reported the issue, and are following up with the OKE team for resolution. The error for this issue presents like:

The following `kubectl` commands can be used to diagnose pods in this state:

```bash
kubectl get pods # to find the name of the pod
kubectl describe pod <pod-name>
```

This will output all information about the pod. In the `Events:` section (at the very bottom) you will see information like this:

```
Pod info: nvidia-dcgm-node-feature-discovery-worker always gets stuck in container creating with warning / error like:
Warning  FailedCreatePodSandBox  12s   kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_gpu-operator-1738967226-node-feature-discovery-worker-dzwht_gpu-operator_06605d81-8dc8-48db-a9a9-b393e8bcd068_0
```

Where the nvidia-dcgm-node-feature-discovery-worker pod infinitely gets stuck in a "ContainerCreating" / "CrashLoopBackoff" cycle.

## Issues Connecting to APIs via Postman or Curl

Make sure to append a slash ('/') to the end of the URL such as `https://api.<domain_endpoint>/deployment/` instead of `https://api.<domain_endpoint>/deployment`.
This is especially important for all POST requests.
