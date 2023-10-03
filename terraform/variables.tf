variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default = {
    "CreatedBy"   = "Terraform"
    "Environment" = "Dev"
  }
}
