# Demo

## Features

- Build golden container image based on Amazon Linux 2
- Provision ECS cluster with EC2 autoscaling that uses golden container image

![logo](./images/demo.svg)

## Getting Started

### Pre-requisites

- `terraform`
- `pre-commit`

### Pre-commit hooks

Install pre-commit hooks:

```console
pre-commit install
```

Run pre-commit hooks:

```console
pre-commit run --all-files
```

## Checkov

<!-- BEGIN_CHECKOV_DOCS -->

| File                                                                                                 | Check ID    | Resource ID                                                        | Reason                                                |
|------------------------------------------------------------------------------------------------------|-------------|--------------------------------------------------------------------|-------------------------------------------------------|
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-alb/v8.7.0/main.tf                 | CKV_AWS_150 | module.alb.aws_lb.this[0]                                          |  disabled so terraform can delete alb on destroy plan |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-alb/v8.7.0/main.tf                 | CKV_AWS_91  | module.alb.aws_lb.this[0]                                          |  access logging disabled for demo purposes            |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/cluster/main.tf | CKV_AWS_338 | module.cluster.aws_cloudwatch_log_group.this[0]                    |  cluster logging not enabled                          |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/cluster/main.tf | CKV_AWS_111 | module.cluster.aws_iam_policy_document.task_exec_assume            |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/cluster/main.tf | CKV_AWS_356 | module.cluster.aws_iam_policy_document.task_exec_assume            |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/cluster/main.tf | CKV_AWS_111 | module.cluster.aws_iam_policy_document.task_exec                   |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/cluster/main.tf | CKV_AWS_356 | module.cluster.aws_iam_policy_document.task_exec                   |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_97  | module.service.aws_ecs_task_definition.this[0]                     |  efs volumes not used                                 |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.service_assume              |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.service_assume              |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.service                     |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.service                     |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.task_exec_assume            |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.task_exec_assume            |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.task_exec                   |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.task_exec                   |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.tasks_assume                |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.tasks_assume                |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_111 | module.service.aws_iam_policy_document.tasks                       |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_AWS_356 | module.service.aws_iam_policy_document.tasks                       |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-ecs/v5.2.2/modules/service/main.tf | CKV_TF_1    | module.service.container_definition                                |  using module from public registry                    |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-vpc/v5.1.2/vpc-flow-logs.tf        | CKV_AWS_111 | module.vpc.aws_iam_policy_document.flow_log_cloudwatch_assume_role |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-vpc/v5.1.2/vpc-flow-logs.tf        | CKV_AWS_356 | module.vpc.aws_iam_policy_document.flow_log_cloudwatch_assume_role |  allow default wildcard iam policies                  |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-vpc/v5.1.2/vpc-flow-logs.tf        | CKV_AWS_111 | module.vpc.aws_iam_policy_document.vpc_flow_log_cloudwatch         |  allow default iam policies without constraints       |
| /.external_modules/github.com/terraform-aws-modules/terraform-aws-vpc/v5.1.2/vpc-flow-logs.tf        | CKV_AWS_356 | module.vpc.aws_iam_policy_document.vpc_flow_log_cloudwatch         |  allow default wildcard iam policies                  |
| /main.tf                                                                                             | CKV_TF_1    | vpc                                                                |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | cluster                                                            |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | service                                                            |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | alb                                                                |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | alb_sg                                                             |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | autoscaling                                                        |  using module from public registry                    |
| /main.tf                                                                                             | CKV_TF_1    | autoscaling_sg                                                     |  using module from public registry                    |

<!-- END_CHECKOV_DOCS -->
