variable "region"                { default = "us-east-1" }
variable "vpc_id"                { type = string }
variable "subnet_id"             { type = string }
variable "instance_profile_name" { type = string } // ec2-jenkins-role instance profile name
variable "key_name"              { type = string }
variable "instance_type"         { default = "t3.micro" }
variable "my_ip_cidr"            { default = "0.0.0.0/0" } // tighten in prod
