# variables.tf

variable "aws_region" {
  description = "The AWS region things are created in"
  default     = "us-east-1"
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default = "myEcsTaskExecutionRole"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  type = string
}

variable "app_name"{
  description = "Application name"
  type = string
  default = "rates-app"
}

variable "app_port" {
  description = "Port exposed by the app"
  default     = 80
  type =string
}

variable "lb_port"{
  description = "Port exposed by the Load balancer"
  default     = 80
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}

variable "db_port" {
  description = "Port exposed by postgres db"
  default = 5432
}

variable "db_name" {
  description = "DB Name"
  type = string
  default = "rates-db"
}

variable "db_password" {
  description = "DB Password"
  default = "Password"  
}

variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}
variable "ami" {
  description = "ami id"
  type        = string
  default = "ami-08c40ec9ead489470"

}
variable "key_name" {
  description = "key for ssh to ec2"
  type = string
  default = "ec2_ssh_key"  
}
