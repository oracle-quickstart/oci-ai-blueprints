# Get compartment name for policy
data "oci_identity_compartment" "oci_compartment" {
  id = var.compartment_ocid
}

# Define the dynamic group
resource "oci_identity_dynamic_group" "dyn_group" {
  provider       = oci.home_region
  name           = "${local.app_name}-instance-dg"
  description    = "Dynamic group for OKE instances across the tenancy"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
  freeform_tags  = local.corrino_tags
  count          = var.policy_creation_enabled ? 1 : 0
}

# Define the IAM policy
resource "oci_identity_policy" "oke_instances_tenancy_policy" {
  provider       = oci.home_region
  name           = "${local.app_name}-dg-inst-policy"
  description    = "Tenancy-level policy to grant needed permissions to the dynamic group"
  compartment_id = var.tenancy_ocid

  statements = [
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.dyn_group[0].name}' to manage all-resources in compartment ${data.oci_identity_compartment.oci_compartment.name}",
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.dyn_group[0].name}' to use all-resources in tenancy",
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.dyn_group[0].name}' to {CLUSTER_JOIN} in compartment ${data.oci_identity_compartment.oci_compartment.name}",
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.dyn_group[0].name}' to manage volumes in TENANCY where request.principal.type = 'cluster'",
    "Allow dynamic-group 'Default'/'${oci_identity_dynamic_group.dyn_group[0].name}' to manage volume-attachments in TENANCY where request.principal.type = 'cluster'"
  ]
  freeform_tags = local.corrino_tags
  count         = var.policy_creation_enabled ? 1 : 0
  depends_on    = [oci_identity_dynamic_group.dyn_group]
}
