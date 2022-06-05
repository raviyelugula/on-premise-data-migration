# creating a VPC
resource "aws_vpc" "ravi-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ravi-vpc"
  }
}

# create a sg and allow inboud traffic from your pc to sg and outbound traffic from sg to any ip on the open internet
resource "aws_security_group" "ravi-sg" {
  name        = "ravi-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.ravi-vpc.id

  ingress {
    description = "connect from my PC"
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

}

# create EC2
resource "aws_instance" "ravi-my-sql" {
  instance_type          = "t2.micro"
  ami                    = "ami-079b5e5b3971bd10d"
  key_name               = "ravi-ec2"
  vpc_security_group_ids = [aws_security_group.ravi-sg.id]
  user_data              = file("user_data.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "ravi-mysql-server"
  }
  
}



