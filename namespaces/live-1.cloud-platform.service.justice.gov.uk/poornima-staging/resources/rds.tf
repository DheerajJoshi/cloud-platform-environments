

module "poornima_test_mysql_rds" {
  source               = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=read-replica"
  cluster_name         = var.cluster_name
  cluster_state_bucket = var.cluster_state_bucket
  team_name            = "Cloud Platform"
  business-unit        = "MOJ Digital"
  application          = "testapp"
  is-production        = "false"

  # If the rds_name is not specified a random name will be generated ( cp-* )
  # Changing the RDS name requires the RDS to be re-created (destroy + create)
  rds_name = "poornima-mysql-rds"

  # enable performance insights
  performance_insights_enabled = true

  db_engine                  = "mysql"
  db_engine_version          = "5.7.19"

  environment-name       = "development"
  infrastructure-support = "platforms@digital.justice.gov.uk"

  # rds_family should be one of: postgres9.4, postgres9.5, postgres9.6, postgres10, postgres11
  # Pick the one that defines the postgres version the best
  rds_family = "mysql5.7"

  # Some engines can't apply some parameters without a reboot(ex postgres9.x cant apply force_ssl immediate). 
  # You will need to specify "pending-reboot" here, as default is set to "immediate".
  db_parameter = [
    {
      name = "character_set_client"
      value = "utf8"
      apply_method = "immediate"
    },
    {
      name = "character_set_server"
      value = "utf8"
      apply_method = "immediate"
    }
  ]

  # use "allow_major_version_upgrade" when upgrading the major version of an engine
  allow_major_version_upgrade = "true"

  providers = {
    # Can be either "aws.london" or "aws.ireland"
    aws = aws.london
  }
}

resource "kubernetes_secret" "poornima_test_mysql_rds" {
  metadata {
    name      = "poornima-test-mysql-rds-instance-output"
    namespace = "poornima-dev"
  }

  data = {
    rds_instance_endpoint = module.poornima_test_mysql_rds.rds_instance_endpoint
    database_name         = module.poornima_test_mysql_rds.database_name
    database_username     = module.poornima_test_mysql_rds.database_username
    database_password     = module.poornima_test_mysql_rds.database_password
    rds_instance_address  = module.poornima_test_mysql_rds.rds_instance_address
    access_key_id         = module.poornima_test_mysql_rds.access_key_id
    secret_access_key     = module.poornima_test_mysql_rds.secret_access_key
  }
  /* You can replace all of the above with the following, if you prefer to
     * use a single database URL value in your application code:
     *
     * url = "postgres://${module.example_team_rds.database_username}:${module.example_team_rds.database_password}@${module.example_team_rds.rds_instance_endpoint}/${module.example_team_rds.database_name}"
     *
     */
}
