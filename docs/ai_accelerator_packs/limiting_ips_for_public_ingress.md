# Limiting IP Addresses for Public Ingress

## Why?
It can be beneficial to allow users to access your applications over public internet, especially if you can scope access to specific IP addresses. This simplifies access while still providing the security of only allowing access from select IP addresses or ranges.

## How to scope access for services deployed by the accelerator pack:

1. Go to the completed stack. On the left-hand side, click "Stack resources".
2. Find "AI-Accel-LB-SECURITY-LIST-*" and click on it which opens it in a new tab.
3. Go to Security Rules.
4. Click "Add Ingress Rule".
5. In the box labeled "Source CIDR", put your desired CIDR range. This will be "white listed"
  - For example, if you wanted to wanted to add one ip: 83.84.85.86,
    the CIDR range is 83.84.85.86/32.
  - To add all IPs with prefix 83.84.85.*, you would do 83.84.85.0/24 which would allow all the IP addresses from 83.84.85.1-83.84.85.255
6. In the box labeled "Destination Port Range", put 443. In the description, put HTTPs.
7. Click "+ Another Ingress Rule", and add your CIDR again, but this time in the "Destination Port Range" box, put 80, and in the description put HTTP.
8. Repeat steps 5-7 for all CIDRs you want to white list.
9. Click "Add Ingress Rules".
10. Click on the "check box" beside the two rules with 0.0.0.0/0 (allowing all IPs). Then click "Actions" -> "Remove".

## How to scope access for the kubernetes API endpoint deployed by the accelerator pack:

1. Go to the completed stack. On the left-hand side, click "Stack resources".
2. Find "AI-Accel-ENDPOINT-SECURITY-LIST-*" and click on it which opens it in a new tab.
3. Repeat steps 3-6 above, except for **"Destination Port Range"**, put 6443, and for description put "External access to Kubernetes API endpoint".
4. Repeat for all CIDRs you want to white list.
5. Click "Add Ingress Rules".
6. Click the rule with "Source" 0.0.0.0/0, then "Actions" -> "Remove"

The above steps will limit access to deployed resources to white-listed CIDR ranges.

## FAQ

1. Why don't we do this in the stack?

We are working on it, but it is fairly complicated and has taken a bit longer than anticipated. The OCI Resource Manager checks on both the ingress and the k8s API endpoint to validate that they deployed successfully. It does not use a set IP range, so we cannot white-list the Resource Manager IPs. If we set this filter as a variable during deployment, the Resource Manager cannot check on the deployment progress and fails.

2. Can I deploy in a private subnet?

Yes, however you must deploy with terraform using an existing VCN which is accessible from another VCN in the same or separate network through network peering.