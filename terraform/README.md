<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | 8.7.0 |
| <a name="module_alb_sg"></a> [alb\_sg](#module\_alb\_sg) | terraform-aws-modules/security-group/aws | 5.1.0 |
| <a name="module_autoscaling"></a> [autoscaling](#module\_autoscaling) | terraform-aws-modules/autoscaling/aws | 6.10.0 |
| <a name="module_autoscaling_sg"></a> [autoscaling\_sg](#module\_autoscaling\_sg) | terraform-aws-modules/security-group/aws | 5.1.0 |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 5.2.2 |
| <a name="module_service"></a> [service](#module\_service) | terraform-aws-modules/ecs/aws//modules/service | 5.2.2 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ssm_parameter.ecs_optimized_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags | `map(string)` | <pre>{<br>  "CreatedBy": "Terraform",<br>  "Environment": "Dev"<br>}</pre> |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
