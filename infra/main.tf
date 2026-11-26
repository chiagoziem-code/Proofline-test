# Database: allows max 197 connections
resource "aws_db_parameter_group" "app" {
  name   = "app-postgres"
  family = "postgres16"

  parameter {
    name  = "max_connections"
    value = "197"
  }
}

# API task: each copy opens 20 database connections
resource "aws_ecs_task_definition" "api" {
  family = "api"
  container_definitions = jsonencode([{
    name  = "api"
    image = "example/api:latest"
    environment = [
      { name = "DB_POOL_SIZE", value = "20" }
    ]
  }])
}

# API service: run 12 copies (12 x 20 = 240 connections)
resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = "main"
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 12
}
