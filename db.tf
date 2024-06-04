module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.6.0"

  identifier = "${local.name_prefix}-postgres"

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100


  db_name  = "completePostgresql"
  username = "complete_postgresql"
  port     = 5432

  # Setting manage_master_user_password_rotation to false after it
  # has previously been set to true disables automatic rotation
  # however using an initial value of false (default) does not disable
  # automatic rotation and rotation will be handled by RDS.
  # manage_master_user_password_rotation allows users to configure
  # a non-default schedule and is not meant to disable rotation
  # when initially creating / enabling the password management feature
  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}

# module "db_default" {
#     source = "../../"

#     identifier                                         = "${local.name_prefix}-default"
#     instance_use_identifier_prefix = true

#     create_db_option_group        = false
#     create_db_parameter_group = false

#     # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
#     engine                             = "postgres"
#     engine_version             = "14"
#     family                             = "postgres14" # DB parameter group
#     major_engine_version = "14"                 # DB option group
#     instance_class             = "db.t4g.large"

#     allocated_storage = 20

#     # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
#     # "Error creating DB Instance: InvalidParameterValue: MasterUsername
#     # user cannot be used as it is a reserved word used by the engine"
#     db_name    = "completePostgresql"
#     username = "complete_postgresql"
#     port         = 5432

#     db_subnet_group_name     = module.vpc.database_subnet_group
#     vpc_security_group_ids = [module.security_group.security_group_id]

#     maintenance_window            = "Mon:00:00-Mon:03:00"
#     backup_window                     = "03:00-06:00"
#     backup_retention_period = 0

#     tags = local.tags
# }

# module "db_disabled" {
#     source = "../../"

#     identifier = "${local.name_prefix}-disabled"

#     create_db_instance                = false
#     create_db_parameter_group = false
#     create_db_option_group        = false
# }
