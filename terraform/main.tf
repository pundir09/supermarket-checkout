provider "aws" {
  region  = "ap-south-1"
}

# ECS Cluster
resource "aws_ecs_cluster" "testsupermarket_cluster" {
  name = "testsupermarket-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "testsupermarket_task" {
  family                   = "testsupermarket-checkout"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "testsupermarket-container"
    image = "xxxxxxxxxx.dkr.ecr.ap-south-1.amazonaws.com/testsupermarket-checkout"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com",
      },
    }],
  })
}

# Policy for ECR access (example)
resource "aws_iam_policy" "ecs_execution_policy" {
  name        = "ecs_execution_policy"
  description = "Policy for ECS task execution role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      Resource = "*",
    }],
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

# Load Balancer
resource "aws_lb" "testsupermarket_lb" {
  name               = "testsupermarket-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["sg-05768f075d8d0a08b"]
  subnets            = ["subnet-02fc81f435c1ae6e9", "subnet-07b1d4f6939decda8"]
  
}
output "lb_dns_name" {
  value = aws_lb.testsupermarket_lb.dns_name
}
# Target Group
resource "aws_lb_target_group" "testsupermarket_tg" {
  name        = "testsupermarket-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-055c3ccd73570944a"
}
# Create Listener
resource "aws_lb_listener" "testsupermarket_http_listener" {
  load_balancer_arn = aws_lb.testsupermarket_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, World!"
      status_code  = "200"
    }
  }
}
# Listener Rule
resource "aws_lb_listener_rule" "testsupermarket_listener_rule" {
  listener_arn = aws_lb_listener.testsupermarket_http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.testsupermarket_tg.arn
  }

  condition {
    host_header {
      values = ["testsupermarket.kredmint.com"]
    }
  }
}

# ECS Service with Load Balancer
resource "aws_ecs_service" "testsupermarket_service" {
  name            = "testsupermarket-service"
  cluster         = aws_ecs_cluster.testsupermarket_cluster.id
  task_definition = aws_ecs_task_definition.testsupermarket_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = aws_lb.testsupermarket_lb.subnets
    security_groups = ["sg-07decfe068cb552cf"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.testsupermarket_tg.arn
    container_name   = "testsupermarket-container"
    container_port   = 8080
  }
}
# CloudFront Distribution
resource "aws_cloudfront_distribution" "testsupermarket_cdn" {
  origin {
    domain_name = aws_lb.testsupermarket_lb.dns_name
    origin_id   = "testsupermarket-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Testkred Checkout CDN"

  # Restrictions Block
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id        = "testsupermarket-origin"
    compress               = "true"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    min_ttl          = 0
    default_ttl      = 3600
    max_ttl          = 86400
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:xxxxxxxxxx:certificate/88017700-c4cd-42b6-a04c-c92c520ce3a2"
    ssl_support_method  = "sni-only"
  }

  # Add alternate domain name
  aliases = ["testsupermarket.kredmint.com"]
}
