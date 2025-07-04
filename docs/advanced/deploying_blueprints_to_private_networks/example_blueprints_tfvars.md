```
# Your actual region
region = "us-ashburn-1"

tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaa____za"
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa____5a"

corrino_admin_username = "admin" # use something else
corrino_admin_nonce = "password" # use something else
corrino_admin_email = "me@oracle.com"

# If you want to authenticate with instance principal
use_instance_principal = true

# Leave these
ingress_nginx_enabled = true
cert_manager_enabled = false

# Can be true if you'd like us to create policies.
policy_creation_enabled = false

# the cluster you wish to install onto
existent_oke_cluster_id = "ocid1.cluster.oc1.iad.aaaaaaaa___ca" #

# The vcn information
existent_vcn_compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa____a"
existent_vcn_ocid = "ocid1.vcn.oc1.iad.amaaaaaa____a"
existent_oke_nodes_subnet_ocid = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
existent_oke_load_balancer_subnet_ocid = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
existent_oke_k8s_endpoint_subnet_ocid = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
share_data_with_corrino_team_enabled = true

# This should be set to Private
cluster_load_balancer_visibility = "Private"

# This version or later
stack_version = "v1.0.4"
```