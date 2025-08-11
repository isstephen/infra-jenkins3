packer {
  required_plugins {
    amazon = { version = ">= 1.2.0", source = "hashicorp/amazon" }
  }
}

variable "region"        { default = "us-east-1" }
variable "source_ami"    { default = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64" }
variable "instance_type" { default = "t3.micro" }
variable "ssh_username"  { default = "ec2-user" }

source "amazon-ebs" "jenkins" {
  region        = var.region
  source_ami    = var.source_ami
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  ami_name      = "jenkins-lts-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
}

build {
  name    = "jenkins-ami"
  sources = ["source.amazon-ebs.jenkins"]

  provisioner "shell" {
    inline = [
      "sudo dnf install -y java-17-amazon-corretto git curl unzip",
      "curl -fsSL -o /tmp/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo mv /tmp/jenkins.repo /etc/yum.repos.d/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo dnf install -y jenkins awscli",
      "sudo mkdir -p /var/lib/jenkins/casc-bundle /var/lib/jenkins/tmp /var/lib/jenkins/init.groovy.d",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins"
    ]
  }

  provisioner "file" { source = "files/casc/jenkins.yaml" destination = "/tmp/jenkins.yaml" }
  provisioner "file" { source = "files/init.groovy.d/01-seed-job.groovy" destination = "/tmp/01-seed-job.groovy" }
  provisioner "file" { source = "files/plugins.txt" destination = "/tmp/plugins.txt" }
  provisioner "file" { source = "files/systemd/override.conf" destination = "/tmp/override.conf" }

  provisioner "shell" {
    inline = [
      "sudo jenkins-plugin-cli --plugin-file /tmp/plugins.txt",
      "sudo mv /tmp/jenkins.yaml /var/lib/jenkins/casc-bundle/jenkins.yaml",
      "sudo mv /tmp/01-seed-job.groovy /var/lib/jenkins/init.groovy.d/01-seed-job.groovy",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/casc-bundle /var/lib/jenkins/init.groovy.d",
      "sudo mkdir -p /etc/systemd/system/jenkins.service.d",
      "sudo mv /tmp/override.conf /etc/systemd/system/jenkins.service.d/override.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sleep 20 || true",
      "sudo systemctl stop jenkins || true"
    ]
  }
}
