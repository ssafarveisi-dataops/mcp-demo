locals {
  resource_prefix = "metaflow"
  private_subnets = {
    eu-west-1a = "subnet-0df8fab73b28be1d6"
    eu-west-1b = "subnet-02ce1a66b1b1f912f"
  }
  private_subnet_list = [
    local.private_subnets.eu-west-1a,
    local.private_subnets.eu-west-1b,
  ]
  vpc_id = "vpc-06ee282aacf654b7c"
}
