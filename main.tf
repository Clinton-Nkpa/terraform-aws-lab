

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "terraform-security-lab"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}


resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "terraform-security-lab_subnet"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-security-lab-rt"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}


resource "aws_subnet" "private_app" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "terraform-security-lab-private-app"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "private-application"
  }
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-security-lab-private-app-rt"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "private-application"
  }
}

resource "aws_route_table_association" "private_app" {
  subnet_id      = aws_subnet.private_app.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name        = "terraform-security-lab-igw"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route" "client_internet" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_security_group" "client" {
  name        = "terraform-security-lab-client"
  description = "Security group for the temporary lab client"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name        = "terraform-security-lab-client"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "client"
  }
}

resource "aws_vpc_security_group_egress_rule" "client_to_ssm" {
  security_group_id = aws_security_group.client.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS egress for Systems Manager"
}

resource "aws_security_group" "app" {
  name        = "terraform-security-lab-app"
  description = "Security group for the private lab application"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name        = "terraform-security-lab-app"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "private-application"

  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_client" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.client.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "Allow TCP 8080 from the lab client"
}

resource "aws_vpc_security_group_egress_rule" "client_to_app" {
  security_group_id            = aws_security_group.client.id
  referenced_security_group_id = aws_security_group.app.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  description = "Allow client to connect to app on TCP 8080"
}

resource "aws_iam_role" "client_ssm" {
  name        = "terraform-security-lab-client-ssm"
  description = "Instance role for the temporary lab client managed by Systems Manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "terraform-security-lab-client-ssm"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "client-instance"
  }
}

resource "aws_iam_role_policy_attachment" "client_ssm_core" {
  role       = aws_iam_role.client_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "client_ssm" {
  name = "terraform-security-lab-client-ssm"
  role = aws_iam_role.client_ssm.name

  tags = {
    Name        = "terraform-security-lab-client-ssm"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "client" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.lab.id
  vpc_security_group_ids = [aws_security_group.client.id]
  iam_instance_profile   = aws_iam_instance_profile.client_ssm.name

  depends_on = [aws_iam_role_policy_attachment.client_ssm_core]

  # Intentionally rely on the subnet's auto-assign-public-IP setting.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name        = "terraform-security-lab-client"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "client"
  }
}

# Security group attached to the SSM interface endpoints.
resource "aws_security_group" "ssm_endpoint" {
  name        = "terraform-security-lab-ssm-endpoint"
  description = "HTTPS access to private Systems Manager endpoints"
  vpc_id      = aws_vpc.lab.id
  egress      = []

  tags = {
    Name        = "terraform-security-lab-ssm-endpoint"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "ssm-endpoint"
  }
}

# Permit HTTPS from the private app instance to the endpoint ENIs.
resource "aws_vpc_security_group_ingress_rule" "ssm_endpoint_from_app" {
  security_group_id            = aws_security_group.ssm_endpoint.id
  referenced_security_group_id = aws_security_group.app.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS from the private app to SSM endpoints"
}

# Permit the lab client to reach the SSM interface endpoints.
resource "aws_vpc_security_group_ingress_rule" "ssm_endpoint_from_client" {
  security_group_id            = aws_security_group.ssm_endpoint.id
  referenced_security_group_id = aws_security_group.client.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS from the lab client to SSM endpoints"
}

# Permit the app to initiate HTTPS connections to the endpoint SG only.
resource "aws_vpc_security_group_egress_rule" "app_to_ssm_endpoint" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.ssm_endpoint.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow HTTPS from app to SSM interface endpoints"
}

# Systems Manager API endpoint.
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.lab.id
  service_name        = "com.amazonaws.eu-north-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app.id]
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "terraform-security-lab-ssm"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}

# Session Manager messaging/data-channel endpoint.
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.lab.id
  service_name        = "com.amazonaws.eu-north-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app.id]
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "terraform-security-lab-ssmmessages"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}


# Dedicated IAM role for the private app instance.
resource "aws_iam_role" "app_ssm" {
  name        = "terraform-security-lab-app-ssm"
  description = "Instance role for the private lab app managed by Systems Manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "terraform-security-lab-app-ssm"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "app-instance"
  }
}

resource "aws_iam_role_policy_attachment" "app_ssm_core" {
  role       = aws_iam_role.app_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_ssm" {
  name = "terraform-security-lab-app-ssm"
  role = aws_iam_role.app_ssm.name

  tags = {
    Name        = "terraform-security-lab-app-ssm"
    Environment = "learning"
    ManagedBy   = "Terraform"
  }
}


# Private application instance managed through Systems Manager.
resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_app.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app_ssm.name

  depends_on = [
    aws_iam_role_policy_attachment.app_ssm_core,
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages
  ]

  # Require IMDSv2 for instance metadata access.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name        = "terraform-security-lab-app"
    Environment = "learning"
    ManagedBy   = "Terraform"
    Role        = "app"
  }
}

