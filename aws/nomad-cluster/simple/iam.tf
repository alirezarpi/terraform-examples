
data "aws_iam_policy_document" "instance-role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance-role" {
  name_prefix        = "nomad-iam-role"
  assume_role_policy = data.aws_iam_policy_document.instance-role.json
}

resource "aws_iam_instance_profile" "instance-profile" {
  name_prefix = "nomad-iam"
  role        = aws_iam_role.instance-role.name
}

resource "aws_iam_role_policy" "cluster-discovery" {
  name   = "nomad-cluster-discovery"
  role   = aws_iam_role.instance-role.id
  policy = data.aws_iam_policy_document.cluster-discovery.json
}

data "aws_iam_policy_document" "cluster-discovery" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}
