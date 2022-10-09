
variable "DEVICE_TYPE" { default="ebs" }
variable "VIRTUAL" { default= "hvm" }
variable "NAME_BASE" { default= "debian-11-arm64_enhanced" }

variable "PUBLIC_IP" { default="true" }

variable "AWS_ACCOUNT" { default="" }
variable "AWS_VPC" { default="vpc-enr" }
variable "AWS_SUBNET" { default="sub_public" }
variable "AWS_SG" { default="sg_packer" }

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ami_base" {

  ami_name      = "debian-11-arm64_docker_${local.timestamp}"
  
  instance_type = "t4g.micro"

  source_ami_filter {
    filters = {
      name                = "${var.NAME_BASE}*"
      root-device-type    = "${var.DEVICE_TYPE}"
      virtualization-type = "${var.VIRTUAL}"
    }
    most_recent = true
    owners      = ["${var.AWS_ACCOUNT}"]
  }

  vpc_filter { 
    filters =  {
      "tag:Name": "${var.AWS_VPC}"   
    }
  }
  
  subnet_filter {
    filters = {
      "tag:Name": "${var.AWS_SUBNET}"
    }
  }

  security_group_filter {
    filters = {
      "tag:Name": "${var.AWS_SG}"
    }
  }
  
  # We need to get to the internet in order to download packages etc..
  associate_public_ip_address = "${var.PUBLIC_IP}"
#  ssh_interface = "${var.SSH_INTERFACE}"
#  session_manager_port = "${var.SSM_PORT}"
  communicator = "ssh"
  iam_instance_profile = ""
  ssh_username = "admin"
  tags = {
    "enr:ami-id" = "{{ .SourceAMIName }}",
    "Name" = "Debian 11 ARM64 docker",
  }
  run_tags = {
    "Name" = "Packer Builder for bullseye docker",
  }

  run_volume_tags = {
    "Name" = "Packer Builder for bullseye docker",
  }

  ami_description= "Debian 11 ARM64 docker"
}

build {
  name = "enr.lucaliclau"
  sources = ["source.amazon-ebs.ami_base"]

# Cloud-init to end
  provisioner "shell" {
    inline = [
      "echo 'logged as :' && id ",
      "echo logged at: '${build.User}@${build.Host}:${build.Port}'",
      "echo Wait end of cloud-init:",
      "/usr/bin/cloud-init status --wait"
    ]
  }

# Call Ansible role
  provisioner "ansible" {
    playbook_file = "./ansible/main.yml"
  }

  # Clean keypairs pushed by packer
  provisioner "shell" {
    inline = ["sed -i 's/ssh-rsa\\ .*\\ packer.*$//g' ~admin/.ssh/authorized_keys"]
  }
}
