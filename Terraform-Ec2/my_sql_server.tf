################################################### VPC ###############################################
# Virtual Private Cloud, enables you to launch AWS resources into a virtual network that you've defined.
# Here we want to give 65,536 (256*256) ip range n/w, hence choosing n/w of 16 bit and host od 16 bits
# 16 n/w bits ==> 10.123
# 16 host bits ==> [0-255].[0-255]

resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "default-vpc"
  }
}

############################################## SubNet ###############################################
# Divide VPC into small groups, can give different rules on each subnet thus improving security. 
# It is a range of IP addresses in your VPC. You can launch AWS resources, such as EC2 instances, into a specific subnet. 
# When you create a subnet, you specify the IPv4 CIDR block for the subnet, which is a subset of the VPC CIDR block.
# Subnets can be created in differnt availability_zones 
# create a subnet with 256 ip range for application-server
# 24 n/w bits ==> 10.123.1
# 8 host bits ==> [0-255]

resource "aws_subnet" "app-server-subnet" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "app-public-subnet"
  }
}

############################################ Internet Gateway ##############################################
# Internet Gateway, allows resources within your VPC to access the internet, and vice versa. 
# In order for this to happen, there needs to be a routing table entry allowing a subnet to access the IGW.
# create IG, to connect VPC
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "default-igw"
  }
}

# create route table
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "default-rt"
  }
}

# create default internet open route
resource "aws_route" "default-internet-route" {
  route_table_id         = aws_route_table.my-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-igw.id
}

# create an association btw rt and subnet and as rt is already having igw and default route with cidr as 0.0.0.0/0. 
# so that subnet will access to internet
resource "aws_route_table_association" "default-rt-association-subnet" {
  subnet_id      = aws_subnet.app-server-subnet.id
  route_table_id = aws_route_table.my-rt.id
}

####################################### Security Group ##############################################################
# SG acts as a virtual firewall for your EC2 instances to control incoming and outgoing traffic. 
# These are stateless, meaning any change applied to an incoming rule isn't automatically applied to an outgoing rule.
# Egress in the world of networking implies traffic that exits an entity or a network boundary, 
# while Ingress is traffic that enters the boundary of a network.

# create a sg and allow inboud traffic from your pc to sg and outbound traffic from sg to any ip on the open internet
resource "aws_security_group" "app-sg" {
  name        = "app-server-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "connect from my PC"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "connect to the internet form EC2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "aws_ami" "free-linux-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  owners = ["137112412989"] # Canonical
}

# create EC2
resource "aws_instance" "application-server" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.free-linux-ami.id
  key_name               = "ravi_pc"
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  subnet_id              = aws_subnet.app-server-subnet.id
  user_data              = file("user_data.tpl")
  iam_instance_profile   = "ec2-read-s3"

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "app-server-mysql"
  }
  
}
