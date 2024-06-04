module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.name_prefix}-ecs"

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
  services = {
    ecsdemo-frontend = {
      cpu    = 1024
      memory = 4096
      container_definitions = {

        fluent-bit = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
          firelens_configuration = {
            type = "fluentbit"
          }
          memory_reservation = 50
        }

        (local.container_name) = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/r0g4s2l2/wigor-tech-task:1.0.7"

          environment = [
            {
              name  = "DB_HOST"
              value = module.db.db_instance_address
            },
            {
              name  = "DB_NAME"
              value = module.db.db_instance_name
            },
            {
              name  = "DB_PORT"
              value = module.db.db_instance_port
            },
          ]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/health || exit 1"]
          }

          port_mappings = [
            {
              name          = local.container_name
              containerPort = local.container_port
              hostPort      = local.container_port
              protocol      = "tcp"
            }
          ]

          readonly_root_filesystem = false

          dependencies = [{
            containerName = "fluent-bit"
            condition     = "START"
          }]

          enable_cloudwatch_logging = false
          log_configuration = {
            logDriver = "awsfirelens"
            options = {
              Name                    = "firehose"
              region                  = local.region
              delivery_stream         = "my-stream"
              log-driver-buffer-limit = "2097152"
            }
          }
          memory_reservation = 100
        }
      }

      service_connect_configuration = {
        namespace = aws_service_discovery_http_namespace.this.arn
        service = {
          client_alias = {
            port     = local.container_port
            dns_name = local.container_name
          }
          port_name      = local.container_name
          discovery_name = local.container_name
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ex_ecs"].arn
          container_name   = local.container_name
          container_port   = local.container_port
        }
      }

      tasks_iam_role_name        = "${local.name_prefix}-tasks"
      tasks_iam_role_description = "Example tasks IAM role for ${local.name_prefix}"
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
      create_task_exec_policy = true
      tasks_iam_role_statements = [
        {
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        },
        {
          actions   = ["secretsmanager:GetSecretValue"]
          resources = ["arn:aws:secretsmanager:::*"]
        },
      ]

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = local.container_port
          to_port                  = local.container_port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = local.tags
}


################################################################################
# Supporting Resources
################################################################################

data "aws_ssm_parameter" "fluentbit" {
  name = "/aws/service/aws-for-fluent-bit/stable"
}

resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name_prefix
  description = "CloudMap namespace for ${local.name_prefix}"
  tags        = local.tags
}
