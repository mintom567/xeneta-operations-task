resource "tls_private_key" "pivot_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.pivot_private_key.public_key_openssh
}

resource "aws_security_group" "ec2_pivot_sg" {
  name        = "ec2-pivot-sg"
  description = "Security group for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}




resource "aws_instance" "pivot-server" {
  ami                         = var.ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name
  monitoring                  = true
  security_groups             = [aws_security_group.ec2_pivot_sg.id]


    provisioner "file" {
        source      = "../db/rates.sql"
        destination = "/home/ubuntu/rates.sql"
       
        connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${tls_private_key.pivot_private_key.private_key_pem}"
        host        = "${self.public_ip}"
        }
    }
  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }
  tags = {
    Name        = "pivot_server"
  }

  depends_on = [
    aws_db_instance.rds
  ]

  user_data = <<-EOF
  #!/bin/bash -xe
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  apt-get update -y
  apt-get install postgresql -y
  export PGPASSWORD='${random_password.rds.result}'
  psql -U ${aws_db_instance.rds.username} -h ${aws_db_instance.rds.address} -d 'rates' -f /home/ubuntu/rates.sql 
  EOF

}

