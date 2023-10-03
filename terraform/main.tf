provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = var.tags
  }
}

data "aws_availability_zones" "available" {}

locals {
  name = "ecs-demo"

  vpc_cidr = "10.3.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  container_name = "frontend"
  container_port = 80
}

################################################################################
# VPC
################################################################################

#tfsec:ignore:aws-ec2-no-excessive-port-access: allow all public ingress/egress
#tfsec:ignore:aws-ec2-no-public-ingress-acl: allow all ports in network acls
#tfsec:ignore:aws-ec2-no-public-ingress-sgr: allow all public ingress
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs: vpc flow logs disabled
module "vpc" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV2_AWS_11: vpc flow logs not enabled
  #checkov:skip=CKV2_AWS_12: allow all ingress/egress in default sg
  #checkov:skip=CKV2_AWS_19: eip are only allocated to nat gateway
  #checkov:skip=CKV_AWS_111: allow default iam policies without constraints
  #checkov:skip=CKV_AWS_356: allow default wildcard iam policies
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = local.name
  cidr = local.vpc_cidr

  azs                        = local.azs
  private_subnets            = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets             = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 2)]
  manage_default_route_table = false

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  igw_tags               = { "Name" = "${local.name}-igw" }
  nat_gateway_tags       = { "Name" = "${local.name}-ngw" }

  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false

  tags = var.tags
}

################################################################################
# ECS Cluster
################################################################################

module "cluster" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV_AWS_111: allow default iam policies without constraints
  #checkov:skip=CKV_AWS_338: cluster logging not enabled
  #checkov:skip=CKV_AWS_356: allow default wildcard iam policies

  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.2"

  cluster_name = local.name

  # Capacity provider
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    on_demand = {
      auto_scaling_group_arn         = module.autoscaling["on_demand"].autoscaling_group_arn
      managed_termination_protection = "DISABLED" # Ignore running tasks in EC2 instance during scale-in

      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED" # Otherwise, tasks fail immediately if insufficient resources
        target_capacity           = 90        # Use 90% of all available capacity in EC2 instance
      }

      default_capacity_provider_strategy = {
        weight = 90
        base   = 1
      }
    }
  }

  tags = var.tags
}

################################################################################
# ECS Service
################################################################################

#tfsec:ignore:aws-ec2-no-public-egress-sgr: allow all public egress
module "service" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV2_AWS_5: sg is attached to ecs service
  #checkov:skip=CKV_AWS_97: efs volumes not used
  #checkov:skip=CKV_AWS_111: allow default iam policies without constraints
  #checkov:skip=CKV_AWS_356: allow default wildcard iam policies
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.2"

  name        = "${local.name}-service"
  cluster_arn = module.cluster.arn

  # Task Role - ECS Exec permissions
  tasks_iam_role_statements = {
    ECSExec = {
      sid    = "AllowECSExec"
      effect = "Allow"
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      resources = ["*"]
    }
  }

  # Enable ECS exec access
  enable_execute_command = true

  # Propagate tags from service to tasks
  propagate_tags = "SERVICE"

  # Task definition
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 512
  capacity_provider_strategy = {
    # On-demand instances
    on_demand = {
      capacity_provider = module.cluster.autoscaling_capacity_providers["on_demand"].name
      weight            = 1
      base              = 1
    }
  }

  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      image  = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample:latest"
      cpu    = 256
      memory = 512
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.alb.target_group_arns, 0)
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb_sg.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

################################################################################
# ALB
################################################################################

#tfsec:ignore:aws-elb-http-not-used: allow non-encrypted http traffic
#tfsec:ignore:aws-elb-alb-not-public: allow public alb
module "alb" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV_AWS_150: disabled so terraform can delete alb on destroy plan
  #checkov:skip=CKV_AWS_91: access logging disabled for demo purposes
  #checkov:skip=CKV2_AWS_28: waf not enabled
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name                       = local.name
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.alb_sg.security_group_id]
  drop_invalid_header_fields = true

  http_tcp_listeners = [
    {
      port               = local.container_port
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-${local.container_name}-0"
      backend_protocol = "HTTP"
      backend_port     = local.container_port
      target_type      = "ip"
    },
  ]

  tags = var.tags
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr: allow all public egress
#tfsec:ignore:aws-ec2-no-public-ingress-sgr: allow all public ingress
module "alb_sg" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV2_AWS_5: sg is attached to alb
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  tags = var.tags
}

################################################################################
# Autoscaling
################################################################################

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "autoscaling" {
  #checkov:skip=CKV_TF_1: using module from public registry
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.10.0"

  for_each = {
    # On-demand instances
    on_demand = {
      instance_type              = "t2.micro"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(var.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
  }

  name = "${local.name}-${each.key}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = false
  protect_from_scale_in           = false
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  create_iam_instance_profile = true
  iam_role_name               = local.name
  iam_role_description        = "ECS role for ${local.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  tags = var.tags
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr: allow all public egress
module "autoscaling_sg" {
  #checkov:skip=CKV_TF_1: using module from public registry
  #checkov:skip=CKV2_AWS_5: sg is attached to asg
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = local.name
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = var.tags
}
