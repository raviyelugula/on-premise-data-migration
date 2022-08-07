# Database Migration Service requires the below IAM Roles to be created before
# replication instances can be created. See the DMS Documentation for
# additional information: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole
#  * dms-vpc-role
#  * dms-cloudwatch-logs-role
#  * dms-access-for-endpoint

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}


resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-access-for-endpoint"
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms-access-for-endpoint.name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}



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
  availability_zone       = "us-east-1a"

  tags = {
    Name = "ravi-public-subnet"
  }
}

# create a subnet, so that EC2 is give the ip from this subnet, enable public ip so that can connect from internet
resource "aws_subnet" "ravi-public-subnet2" {
  vpc_id                  = aws_vpc.ravi-vpc.id
  cidr_block              = "10.123.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "ravi-public-subnet2"
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

resource "aws_route_table_association" "ravi-rt-association-subnet2" {
  subnet_id      = aws_subnet.ravi-public-subnet2.id
  route_table_id = aws_route_table.ravi-rt.id
}

# Create a new replication subnet group
resource "aws_dms_replication_subnet_group" "dms-subnetgroup-ry" {
  replication_subnet_group_description = "Test replication subnet group"
  replication_subnet_group_id          = "test-dms-replication-subnet-group-tf"

  subnet_ids = [
    aws_subnet.ravi-public-subnet2.id,aws_subnet.ravi-public-subnet.id
  ]

  tags = {
    Name = "ravi-test-sbg"
  }
    depends_on = [
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]

}



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

# Create a new replication instance
resource "aws_dms_replication_instance" "dms_instance_ry" {
  allocated_storage            = 10
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = "us-east-1a"
  engine_version               = "3.4.7"
  multi_az                     = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = true
  replication_instance_class   = "dms.t3.micro"
  replication_instance_id      = "dms-instance-test-ry"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms-subnetgroup-ry.id

  tags = {
    Name = "test"
  }

  vpc_security_group_ids = [
    aws_security_group.ravi-sg.id 
  ]

  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]

}

resource "aws_dms_endpoint" "src-endpoint" {
  database_name               = "mysql"
  endpoint_id                 = "sql-src"
  endpoint_type               = "source"
  engine_name                 = "mysql"
  password                    = "ravi123@PSWD"
  port                        = 3306
  server_name                 = "mysql"
  ssl_mode                    = "none"
  

  tags = {
    Name = "test"
  }

  username = "ravi"
}

resource "aws_dms_endpoint" "trg-endpoint" {
  endpoint_id                 = "trg-src"
  endpoint_type               = "target"
  engine_name                 = "s3"

  tags = {
    Name = "test"
  }

  s3_settings {
    
      bucket_folder = "DMSTesting/fullload/"
      bucket_name = "dms-mysql-landing"
      service_access_role_arn = "arn:aws:iam::307592787224:role/dms-access-for-endpoint"
  
  }
}


# Create a new replication task
resource "aws_dms_replication_task" "test" {
  migration_type            = "full-load"
  replication_instance_arn  = aws_dms_replication_instance.dms_instance_ry.replication_instance_arn
  replication_task_id       = "sql-ravi-test"
  source_endpoint_arn       = aws_dms_endpoint.src-endpoint.endpoint_arn
  table_mappings            = file("TableMapping.json")

  tags = {
    Name = "test"
  }

  target_endpoint_arn = aws_dms_endpoint.trg-endpoint.endpoint_arn
}


