
resource "aws_vpc" "nomad-cluster-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_classiclink   = "false"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name      = "nomad-cluster"
    Terraform = "true"
  }
}
