# Database settings: max 197 connections
resource "aws_db_parameter_group" "app" {
  name   = "app-postgres"
  family = "postgres16"

  parameter {
    name         = "max_connections"
    value        = "197"
    apply_method = "pending-reboot" # Fix 1: static setting, applies after restart
  }
}

# Fix 2: an actual database that uses those settings
resource "aws_db_instance" "app" {
  identifier                  = "app-db"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  username                    = "appadmin"
  manage_master_user_password = true
  parameter_group_name        = aws_db_parameter_group.app.name
  skip_final_snapshot         = true
}

# API task: each copy opens 20 database connections
resource "aws_ecs_task_definition" "api" {
  family = "api"
  cpu    = "256"
  memory = "512" # Fix 3: task memory set

  container_definitions = jsonencode([{
    name   = "api"
    image  = "example/api:latest"
    memory = 512 # Fix 3: container memory set
    environment = [
      { name = "DB_POOL_SIZE", value = "20" }
    ]
  }])
}

# API service: 12 copies (12 x 20 = 240 connections)
resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = "main"
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 12
}
