
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.1"
    }
  }
}



provider "aws" {
  region     = "us-east-2" # Ohio region
  access_key = ""
  secret_key = ""
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "My-VPC"
  }
}

# Create Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "Public-Subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My-Internet-Gateway"
  }
}

# Create a Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group for EC2
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id

    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "My-Security-Group"
  }
}


locals {
  vm_size  = "t2.micro"
  tag_name = "my_firest_vm"
  vm_size_t3 = "t3.micro"
}




resource "aws_instance" "instance1" {
  ami           = "ami-0b4624933067d393a" # Amazon Linux 2 AMI (Ohio region)  
  #ami           = "ami-036841078a4b68e14" # Ubuntu 24.04  AMI (Ohio region)
  



  instance_type = local.vm_size
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "laptom" # Replace with your key pair name

  vpc_security_group_ids = [aws_security_group.my_sg.id] # Correct security group usage for VPC

  tags = {
    Name = "Instance-1"
  }

  
}

 # Output the public IP of the EC2 instance
output "ec2_public_ip" {
  value = aws_instance.instance1.public_ip
}


# Add a delay using a null_resource
resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "powershell -Command \"Start-Sleep -Seconds 120\""
  }

  depends_on = [aws_instance.instance1]
}

resource "aws_instance" "instance2" {
   ami           = "ami-0b4624933067d393a" # Amazon Linux 2 AMI (Ohio region)
   #ami           = "ami-036841078a4b68e14" # Ubuntu 24.04  AMI (Ohio region)
  instance_type = local.vm_size
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "laptom" # Replace with your key pair name

  vpc_security_group_ids = [aws_security_group.my_sg.id] # Correct security group usage for VPC

  tags = {
    Name = "Instance-2"
  }

  depends_on = [null_resource.wait]
}


output "ec2_public_ip_new" {
  value = aws_instance.instance2.public_ip
}


