resource "aws_vpc" "main-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# ---------------- SUBNETS ----------------

resource "aws_subnet" "private-subnet-01" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "private-subnet-01"
  }
}

resource "aws_subnet" "private-subnet-02" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "private-subnet-02"
  }
}

resource "aws_subnet" "public-subnet-01" {
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-01"
  }
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-02"
  }
}

# ---------------- IGW ----------------

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "IGW"
  }
}

# ---------------- EIP ----------------

resource "aws_eip" "nat-ip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.IGW]
}

# ---------------- NAT ----------------

resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.nat-ip.id
  subnet_id     = aws_subnet.public-subnet-01.id

  tags = {
    Name = "NAT"
  }
}

# ---------------- PUBLIC RT ----------------

resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "public-RT"
  }
}

resource "aws_route_table_association" "public-rt-assoc-01" {
  subnet_id      = aws_subnet.public-subnet-01.id
  route_table_id = aws_route_table.public-RT.id
}

resource "aws_route_table_association" "public-rt-assoc-02" {
  subnet_id      = aws_subnet.public-subnet-02.id
  route_table_id = aws_route_table.public-RT.id
}

# ---------------- PRIVATE RT ----------------

resource "aws_route_table" "private-RT" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT.id
  }

  tags = {
    Name = "private-RT"
  }
}

resource "aws_route_table_association" "private-rt-assoc-01" {
  subnet_id      = aws_subnet.private-subnet-01.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private-rt-assoc-02" {
  subnet_id      = aws_subnet.private-subnet-02.id
  route_table_id = aws_route_table.private-RT.id
}