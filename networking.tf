resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-vpc"
  }
}


resource "aws_subnet" "tf_public_subnet_1" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "tf-public-subnet-1"
  }
}


resource "aws_subnet" "tf_public_subnet_2" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "tf-public-subnet-2"
  }
}


resource "aws_subnet" "tf_private_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "tf-private-subnet"
  }
}


resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf-igw"
  }
}


resource "aws_route_table" "tf_public_rt" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }

  tags = {
    Name = "tf-rt"
  }
}


resource "aws_route_table_association" "tf_public_rt_associations" {
  for_each = {
    subnet_1 = aws_subnet.tf_public_subnet_1.id
    subnet_2 = aws_subnet.tf_public_subnet_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.tf_public_rt.id
}


resource "aws_security_group" "tf_lb_sg" {
  name        = "tf-lb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-lb-sg"
  }
}


resource "aws_security_group" "tf_public_instance_sg" {
  name        = "tf-public-instance-sg"
  description = "Allow HTTP from ALB and SSH from anywhere"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description     = "HTTP from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.tf_lb_sg.id]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-public-instance-sg"
  }
}


resource "aws_security_group" "tf_private_instance_sg" {
  name        = "tf-private-instance-sg"
  description = "Allow HTTP from public instances and SSH from public instances"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description     = "HTTP from public instances"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.tf_public_instance_sg.id]
  }

  ingress {
    description     = "SSH from public instances"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.tf_public_instance_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-private-instance-sg"
  }
}

resource "aws_eip" "tf_nat_eip" {
  domain = "vpc"
}


resource "aws_nat_gateway" "tf_nat" {
  allocation_id = aws_eip.tf_nat_eip.id
  subnet_id     = aws_subnet.tf_public_subnet_1.id
  depends_on    = [aws_internet_gateway.tf_igw]
  tags = {
    Name = "tf-nat"
  }
}


resource "aws_route_table" "tf_private_rt" {
  vpc_id = aws_vpc.tf_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tf_nat.id
  }
  tags = {
    Name = "tf-private-rt"
  }
}


resource "aws_route_table_association" "tf_private_rt_association" {
  subnet_id      = aws_subnet.tf_private_subnet.id
  route_table_id = aws_route_table.tf_private_rt.id
}


resource "aws_lb_target_group" "tf_tg" {
  name     = "tf-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf-tg"
  }
}


resource "aws_lb_target_group_attachment" "tf_tg_attachments" {
  for_each = {
    instance_1 = aws_instance.tf_public_instance_1.id
    instance_2 = aws_instance.tf_public_instance_2.id
  }

  target_group_arn = aws_lb_target_group.tf_tg.arn
  target_id        = each.value
  port             = 80
}


resource "aws_lb" "tf_alb" {
  name               = "tf-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_lb_sg.id]
  subnets            = [aws_subnet.tf_public_subnet_1.id, aws_subnet.tf_public_subnet_2.id]

  tags = {
    Name = "tf-alb"
  }
}


resource "aws_lb_listener" "tf_alb_listener" {
  load_balancer_arn = aws_lb.tf_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg.arn
  }
}
