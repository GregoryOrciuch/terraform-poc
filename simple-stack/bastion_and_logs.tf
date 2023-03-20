resource "aws_iam_policy" "write-logs-policy" {
  name = "write-logs-from-ec2"
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })

  tags = {
    costTag = var.cost_tag
  }
}


resource "aws_iam_role" "ec2-role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2-attach" {
  name       = "ec2-attachment"
  roles      = [aws_iam_role.ec2-role.name]
  policy_arn = aws_iam_policy.write-logs-policy.arn
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-role.name
}

resource "aws_instance" "bastion" {
  ami           = "ami-01a2825a801771f57" # Canonical, Ubuntu, 18.04 LTS, amd64 bionic image build on 2023-01-31
  instance_type = var.ec2_instance_type
  #key_name = "go_keypair"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.public1.id

  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name

  tags = {
    costTag = var.cost_tag
  }
}


resource "aws_cloudwatch_log_group" "ec2" {
  name = "/ec2/bastion"

  retention_in_days = 14

  tags = {
    costTag = var.cost_tag
  }
}