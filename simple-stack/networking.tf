resource "aws_vpc" "custom_vpc" {
  cidr_block       = var.vpc_cidr
  tags = {
    Name = "stack-dedicated-vpc"
    costTag = var.cost_tag
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "stack-igw"
    costTag = var.cost_tag
  }
}

data "aws_route_tables" "rts" {
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = "10.8.4.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub-1-net"
    costTag = var.cost_tag
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = "10.8.5.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "pub-2-net"
    costTag = var.cost_tag
  }
}

resource "aws_route" "r" {
  route_table_id            = data.aws_route_tables.rts.ids[0]
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_subnet" "zone1net" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = "10.8.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "priv-1-net"
    costTag = var.cost_tag
  }
}

resource "aws_subnet" "zone2net" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = "10.8.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "priv-2-net"
    costTag = var.cost_tag
  }
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "SSH to bastion"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP to bastion"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
    costTag = var.cost_tag
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow-tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-tls"
    costTag = var.cost_tag
  }
}

resource "aws_security_group" "mysql-service" {
  name        = "mysql-service"
  description = "MYSQL VPC security group"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "MSQL traffic from Bastion only"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    description      = "All out"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-service"
    costTag = var.cost_tag
  }
}
