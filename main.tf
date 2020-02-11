#vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  #EnableDnsSupport: true
  #EnableDnsHostnames: true


  tags = merge(
    {
      "Name" = var.vpc_name
    },
    var.tags,
  )
}

#public subnet
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = element(concat(var.public_subnets, [""]), count.index)

  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = "true"

  tags = merge(
    {
      "Name" = "${var.public_subnet_prefix}-${var.vpc_name}-${element(var.availability_zones, count.index)}"
    },
    var.tags,
  )
}

#Private subnets
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = element(concat(var.private_subnets, [""]), count.index)

  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = "false"

  tags = merge(
    {
      "Name" = "${var.private_subnet_prefix}-${var.vpc_name}-${element(var.availability_zones, count.index)}"
    },
    var.tags,
  )
}

#Data subnets
resource "aws_subnet" "data_subnets" {
  count = length(var.data_subnets) > 0 ? length(var.data_subnets) : 0

  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = element(concat(var.data_subnets, [""]), count.index)

  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = "false"

  tags = merge(
    {
      "Name" = "${var.data_subnet_prefix}-${var.vpc_name}-${element(var.availability_zones, count.index)}"
    },
    var.tags,
  )
}

#internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = "${aws_vpc.vpc.id}"

  tags = merge(
    {
      "Name" = "${var.vpc_name}"
    },
    var.tags,
  )
}

#natgateway
resource "aws_eip" "nat_eip" {
  count = var.enable_nat_gateway ? 1 : 0
  vpc   = true

  tags = {
    Name = "natgateway"
  }
}

resource "aws_nat_gateway" "natgateway" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = "${aws_eip.nat_eip[0].id}"
  subnet_id     = "${aws_subnet.public_subnets[0].id}"

  tags = merge(
    {
      "Name" = "natgateway- ${var.vpc_name}"
    },
    var.tags,
  )
}

#public routes
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = "${aws_vpc.vpc.id}"

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_prefix}", var.vpc_name)
    },
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}


#private routes
resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  vpc_id = "${aws_vpc.vpc.id}"

  tags = merge(
    {
      "Name" = format("%s-${var.private_subnet_prefix}", var.vpc_name)
    },
    var.tags,
  )
}

resource "aws_route" "private_nat" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgateway[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}


#data routes
resource "aws_route_table" "data" {
  count = length(var.data_subnets) > 0 ? 1 : 0

  vpc_id = "${aws_vpc.vpc.id}"

  tags = merge(
    {
      "Name" = format("%s-${var.data_subnet_prefix}", var.vpc_name)
    },
    var.tags,
  )
}

resource "aws_route" "data_nat" {
  count = length(var.data_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.data[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgateway[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "data" {
  count          = length(var.data_subnets) > 0 ? length(var.data_subnets) : 0
  subnet_id      = element(aws_subnet.data_subnets.*.id, count.index)
  route_table_id = aws_route_table.data[0].id
}



#flowlogs
resource "aws_flow_log" "vpc_flowlogs" {
  count           = var.enable_flow_log ? 1 : 0
  iam_role_arn    = "${aws_iam_role.flow_iam[0].arn}"
  log_destination = "${aws_cloudwatch_log_group.flow_group[0].arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.vpc.id}"
}

resource "aws_cloudwatch_log_group" "flow_group" {
  count             = var.enable_flow_log ? 1 : 0
  name              = "${var.vpc_name}-flowlogs"
  retention_in_days = var.log_retention_period
}

resource "aws_iam_role" "flow_iam" {
  count = var.enable_flow_log ? 1 : 0
  name  = "${var.vpc_name}-flowlogs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flow_iam_policy" {
  count = var.enable_flow_log ? 1 : 0
  name  = "${var.vpc_name}-flowlogs"
  role  = "${aws_iam_role.flow_iam[0].id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
