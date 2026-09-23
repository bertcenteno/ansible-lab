output "instance_id" {
  description = "ID of the Terraform lab EC2 instance"
  value       = aws_instance.terraform_lab.id
}

output "instance_private_ip" {
  description = "Private IP address of the Terraform lab EC2 instance"
  value       = aws_instance.terraform_lab.private_ip
}

output "instance_private_dns" {
  description = "Private DNS name of the Terraform lab EC2 instance"
  value       = aws_instance.terraform_lab.private_dns
}

output "security_group_id" {
  description = "ID of the Terraform lab security group"
  value       = aws_security_group.terraform_lab.id
}

output "instance_ami" {
  description = "AMI used by the Terraform lab EC2 instance"
  value       = data.aws_ami.amazon_linux.id
}