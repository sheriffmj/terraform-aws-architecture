resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "test-main"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "test-private-subnet"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-igw"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-public-rt"
  }
}

resource "aws_route" "public_rt" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-private-rt"
  }
}

resource "aws_route" "private_rt" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}


resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "my-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_instance" "public" {
  subnet_id              = aws_subnet.public.id
  ami                    = "ami-0b6d9d3d33ba97d99"
  key_name               = "jjtech24"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "public-instance"
  }
}

resource "aws_instance" "private" {
  subnet_id              = aws_subnet.private.id
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t3.micro"
  key_name               = "jjtech24"
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  tags = {
    Name = "private-instance"
  }
}


resource "aws_security_group" "web_sg" {
  name        = "test-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "web_allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.255.1/32"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "web_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "inbound_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group" "private_sg" {
  name        = "test-private-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "private_allow_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
  security_group_id        = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "private_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "private_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}
