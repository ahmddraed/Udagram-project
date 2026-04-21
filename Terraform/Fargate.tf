resource "aws_security_group" "fargate_sg" {
  name   = "fargate-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 3shan agrb mn el browser
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "udagram-cluster"
}


resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "app" {
  family                   = "my-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.fargate_role.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "ahmddraed/udagram-api"

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
         logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/udagram"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "POSTGRES_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "POSTGRES_USER"
          value = var.POSTGRES_USER
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.POSTGRES_PASSWORD
        },
        {
          name  = "POSTGRES_DB"
          value = var.POSTGRES_DB
        },
        {
          name  = "DB_PORT"
          value = var.DB_PORT
        },
        {
           name = "PORT"
           value = var.PORT
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "AWS_BUCKET"
          value = aws_s3_bucket.app_bucket.bucket
        },
        {
          name  = "JWT_SECRET"
          value = var.JWT_SECRET
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "my-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = true
  }
}
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/udagram"
  retention_in_days = 7
}