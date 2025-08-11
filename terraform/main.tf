provider "aws" { region = var.region }

data "aws_ami" "jenkins" {
  owners      = ["self"]
  most_recent = true
  filter {
    name   = "name"
    values = ["jenkins-lts-*"]
  }
}

resource "aws_security_group" "jenkins" {
  name   = "sg-jenkins"
  vpc_id = var.vpc_id
  ingress { from_port = 22  to_port = 22  protocol = "tcp" cidr_blocks = [var.my_ip_cidr] }
  ingress { from_port = 8080 to_port = 8080 protocol = "tcp" cidr_blocks = [var.my_ip_cidr] }
  egress  { from_port = 0   to_port = 0   protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.jenkins.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = var.key_name
  user_data = <<-EOT
              #!/bin/bash
              hostnamectl set-hostname jenkins
              systemctl start jenkins
              EOT
  tags = { Name = "jenkins-server" }
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}
