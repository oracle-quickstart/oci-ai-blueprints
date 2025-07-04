```
# Your actual region
region = "us-ashburn-1"
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaa____za"
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa____5a"

# If you want to authenticate with instance principal
use_instance_principal = true

network_configuration_mode = "bring_your_own"
existing_vcn_id = "ocid1.vcn.oc1.iad.amaaaaaam____a"
existing_endpoint_subnet_id = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
existing_node_subnet_id = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
existing_lb_subnet_id = "ocid1.subnet.oc1.iad.aaaaaaaa____q"
k8s_version = "v1.31.1"
cluster_workers_visibility = "Private"
cluster_endpoint_visibility_existing_vcn = "Private"
num_pool_workers = 3
node_pool_name = "control-plane"
node_pool_instance_shape = {
  instanceShape = "VM.Standard.E3.Flex"
  ocpus         = 6
  memory        = 64
}
node_pool_boot_volume_size_in_gbs = 100
```