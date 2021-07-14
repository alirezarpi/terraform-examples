
resource "aws_subnet" "nomad-cluster-subnet-pub" {
  count                   = var.nomad_node_count
  vpc_id                  = aws_vpc.nomad-cluster-vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}${var.az_map[count.index]}"

  tags = {
    Name      = "nomad-cluster"
    Terraform = "true"
  }
}