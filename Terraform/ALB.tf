resource "aws_security_group" "alb_sg" {
  name        = "LoadBalancer-sg"
  description = "allow traffic to Fargate"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_lb" "load_balancer" {
  name               = "fargate-loadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public-subnet-01.id,
    aws_subnet.public-subnet-02.id
  ]
}

resource "aws_lb_target_group" "targetGroup" {
  name        = "targetGroup"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main-vpc.id
}

resource "aws_lb_listener" "listening" {      # byrbot mben el target group w el alb nfso (forward the trafic to tg)
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetGroup.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}  