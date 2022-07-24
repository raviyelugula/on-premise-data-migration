# creating a VPC
resource "aws_vpc" "ravi-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ravi-vpc"
  }
}

# create a subnet, so that EC2 is give the ip from this subnet, enable public ip so that can connect from internet
resource "aws_subnet" "ravi-public-subnet" {
  vpc_id                  = aws_vpc.ravi-vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "ravi-public-subnet"
  }
}

# create IG, to connect VPC
resource "aws_internet_gateway" "ravi-igw" {
  vpc_id = aws_vpc.ravi-vpc.id

  tags = {
    Name = "ravi-igw"
  }
}

# create route table
resource "aws_route_table" "ravi-rt" {
  vpc_id = aws_vpc.ravi-vpc.id

  tags = {
    Name = "ravi-public-rt"
  }
}

# create default internet open route
resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.ravi-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ravi-igw.id
}

# create an association btw rt and subnet and as rt is already having igw and default route with cidr as 0.0.0.0/0. so that subnet will access to internet
resource "aws_route_table_association" "ravi-rt-association-subnet" {
  subnet_id      = aws_subnet.ravi-public-subnet.id
  route_table_id = aws_route_table.ravi-rt.id
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
resource "aws_instance" "ravi-ec2node_5" {
  instance_type          = "t2.micro"
  ami                    = "ami-079b5e5b3971bd10d"
  key_name               = "ravi-ec2"
  vpc_security_group_ids = [aws_security_group.ravi-sg.id]
  subnet_id              = aws_subnet.ravi-public-subnet.id
  user_data              = file("user_data.tpl")
  iam_instance_profile   = "ec2-read-s3"

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "ravi-mysql-server"
  }
  
}
