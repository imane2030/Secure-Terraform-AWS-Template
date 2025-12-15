# VPC with DNS support enabled (NIST 800-53: SC-7)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${var.project_name}-vpc"
    NISTControls = "SC-7, AC-4"
    Description  = "Network boundary protection"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${var.project_name}-igw"
    NISTControls = "SC-7"
  }
}

# Public Subnets (NIST 800-53: SC-7)
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  map_public_ip_on_launch = false  # Explicit IP assignment for security

  availability_zone = data.aws_availability_zones.available.names[
    index(var.public_subnets, each.key) % length(data.aws_availability_zones.available.names)
  ]

  tags = {
    Name         = "${var.project_name}-public-${replace(each.key, "/", "-")}"
    Tier         = "public"
    NISTControls = "SC-7"
  }
}

# Private Subnets (NIST 800-53: SC-7, SC-32)
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.key
  map_public_ip_on_launch = false

  availability_zone = data.aws_availability_zones.available.names[
    index(var.private_subnets, each.key) % length(data.aws_availability_zones.available.names)
  ]

  tags = {
    Name         = "${var.project_name}-private-${replace(each.key, "/", "-")}"
    Tier         = "private"
    NISTControls = "SC-7, SC-32"
    Description  = "Network segmentation and isolation"
  }
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# VPC Flow Logs (NIST 800-53: AU-2, SI-4)
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name         = "${var.project_name}-flow-logs"
    NISTControls = "AU-2, SI-4"
    Description  = "Network traffic monitoring"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudtrail.arn

  tags = {
    Name         = "${var.project_name}-flow-logs"
    NISTControls = "AU-11"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
