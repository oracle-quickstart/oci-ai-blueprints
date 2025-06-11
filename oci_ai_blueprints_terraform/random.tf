resource "random_string" "generated_workspace_name" {
  length    = 6
  special   = false
  min_upper = 3
  min_lower = 3
}

resource "random_string" "generated_deployment_name" {
  length    = 6
  special   = false
  min_upper = 3
  min_lower = 3
}

resource "random_string" "corrino_django_secret" {
  length           = 32
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

# resource "random_string" "autonomous_database_wallet_password" {
#   length           = 16
#   special          = true
#   min_upper        = 3
#   min_lower        = 3
#   min_numeric      = 3
#   min_special      = 3
#   override_special = "{}#^*<>[]%~"
# }

resource "random_string" "postgres_db_password" {
  length           = 16
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

resource "random_string" "postgres_db_username" {
  length           = 8
  special          = false
  min_upper        = 2
  min_lower        = 2
}

resource "random_string" "postgres_db_name" {
  length           = 4
  special          = false
  min_upper        = 2
  min_lower        = 2
}

# resource "random_string" "autonomous_database_admin_password" {
#   length           = 16
#   special          = true
#   min_upper        = 3
#   min_lower        = 3
#   min_numeric      = 3
#   min_special      = 3
#   override_special = "{}#^*<>[]%~"
# }

resource "random_string" "subdomain" {
  length  = 6
  special = false
  upper   = false
}

resource "random_uuid" "registration_id" {
}

#resource "random_string" "registration_id" {
#  length  = 8
#  special = false
#  upper   = false
#}