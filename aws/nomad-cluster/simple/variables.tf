variable "aws_access_key" {
  description = "Access key for AWS account"
}

variable "aws_secret_key" {
  description = "Secret for AWS account"
}

variable "aws_region" {
  description = "The region name to deploy into"
  default     = "us-west-2"
}

variable "aws_key_name" {
  description = "SSH key name"
  default     = "Alireza"
}

variable "nomad_node_instance_size" {
  description = "EC2 instance type/size for Nomad nodes"
  default     = "t2.micro"
}

variable "nomad_node_ami_id" {
  description = "AMI ID to use for Nomad nodes"
  default     = "ami-0dc8f589abe99f538"
}

variable "nomad_node_count" {
  description = "The number of server nodes (should be 3 or 5)"
  type        = number
  default     = 5
}

variable "allowed_ip_network" {
  description = "Networks allowed in security group for ingress rules"
  default     = ["0.0.0.0/0"]
}

variable "az_map" {
  type = map(any)
  default = {
    0 = "a"
    1 = "b"
    2 = "c"
    3 = "a"
    4 = "b"
  }
}