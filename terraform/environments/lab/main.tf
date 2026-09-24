data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_security_group" "terraform_lab" {
  name        = "${var.instance_name}-sg"
  description = "Security group for the v3.1 Terraform lab instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_private_ip}/32"]
  }

  egress {
    description = "Allow outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "aws_key_pair" "terraform_lab" {
  key_name   = "v3.1-terraform-lab"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_instance" "terraform_lab" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = false

  key_name = aws_key_pair.terraform_lab.key_name

  vpc_security_group_ids = [
    aws_security_group.terraform_lab.id
  ]

  tags = {
    Name = var.instance_name
  }
}
