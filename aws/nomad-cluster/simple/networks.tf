
resource "aws_internet_gateway" "nomad-cluster-igw" {
  vpc_id = aws_vpc.nomad-cluster-vpc.id

  tags = {
    Name      = "nomad-cluster"
    Terraform = "true"
  }
}


resource "aws_route_table" "nomad-cluster-public-crt" {
  vpc_id = aws_vpc.nomad-cluster-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad-cluster-igw.id
  }

  tags = {
    Name      = "nomad-cluster"
    Terraform = "true"
  }
}

resource "aws_route_table_association" "subnet_association" {
  count = var.nomad_node_count

  subnet_id      = aws_subnet.nomad-cluster-subnet-pub[count.index].id
  route_table_id = aws_route_table.nomad-cluster-public-crt.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_subnet.nomad-cluster-subnet-pub,
    aws_route_table.nomad-cluster-public-crt,
  ]
}
