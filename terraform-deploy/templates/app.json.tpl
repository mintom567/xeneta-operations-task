[
  {
    "name": "${app_name}",
    "image": "${app_image}",
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${app_name}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${app_port},
        "hostPort": ${app_port}
      }
    ],
    "environment": [
        {
          "name": "DB_USERNAME",
          "value": "postgres"
        },
        {
          "name": "DB_PASSWORD",
          "value": "${db_password}"
        },
        {
          "name": "DB_HOST",
          "value": "${db_host}"
        },
        {
          "name": "DB_NAME",
          "value": "rates"
        }
      ]
  }
]