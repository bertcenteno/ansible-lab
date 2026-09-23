variable "aws_region" {
  description = "AWS region for the Terraform lab environment"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_id" {
  description = "Existing VPC for the Terraform lab instance"
  type        = string
  default     = "vpc-0b20dd8acbe3545b6"
}

variable "subnet_id" {
  description = "Existing internal subnet for the Terraform lab instance"
  type        = string
  default     = "subnet-0a2cf80f8540deb52"
}

variable "instance_type" {
  description = "EC2 instance type for the Terraform lab"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the Terraform lab instance"
  type        = string
  default     = "v3.1-terraform-lab"
}

variable "bastion_private_ip" {
  description = "Private IP address of the bastion host allowed to SSH to the Terraform lab instance"
  type        = string
  default     = "10.77.2.172"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for the Terraform lab EC2 instance"
  type        = string
}
