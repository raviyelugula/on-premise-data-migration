terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configuring aws provider using shared creds file
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "ravi_pc"
  region                   = "us-east-1"
}

# 10.0.0.0/16
# 8_.8_./8_.8_ ==> 10.0.[0-255].[0-255]
resource "aws_vpc" "tf-vpc" {
  cidr_block = "10.0.0.0/16"
}

# 10.0.1.0/24
# 8_.8_.8_./8_ ==> 10.0.1.[0-255]
resource "aws_subnet" "tf-subnet-1" {
  vpc_id     = aws_vpc.tf-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "aws-subnet"
  }
}

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "aws-igw"
  }
}


resource "aws_route_table" "tf-rt" {
  vpc_id = aws_vpc.tf-vpc.id
}

resource "aws_route" "tf-r" {
  route_table_id            = aws_route_table.tf-rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.tf-igw.id
  depends_on                = [aws_route_table.tf-rt]
}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf-subnet-1.id
  route_table_id = aws_route_table.tf-rt.id
}

resource "aws_security_group" "tf-sg" {
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.tf-vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


resource "aws_instance" "web" {
  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  key_name               = "ravi_pc"
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  subnet_id              = aws_subnet.tf-subnet-1.id
  tags = {
    Name = "session3"
  }
}