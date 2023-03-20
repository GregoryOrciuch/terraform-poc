variable "db_username" { type = string }
variable "db_password" { type = string }
variable "ec2_instance_type" { type = string }
variable "vpc_cidr" { type = string }

variable "acm_ssl_arn" { type = string }
variable "cost_tag" { type = string }
variable "elb-account-id" { type = string }