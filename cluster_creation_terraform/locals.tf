# Copyright (c) 2020-2024 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

locals {
  # Authentication configuration
  auth_config = {
    use_instance_principal = var.use_instance_principal
    auth_method           = var.use_instance_principal ? "InstancePrincipal" : "UserCredentials"
  }
} 