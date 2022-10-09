# ami-debian-docker
ami from enhanced version with docker

## docker

setup docker on the AMI with tools:

* docker-ce
* docker-compose

## Build

Before building this image you must build enhanced one

Run the following commands to build enhanced debian image:

* export PKR_VAR_AWS_ACCOUNT="<account number>"
* packer init ami.pkr.hcl
* packer build ami.pkr.hcl