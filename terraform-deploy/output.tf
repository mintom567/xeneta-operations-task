#outputs the application load balancer hostname
output "alb_hostname" {
  value = aws_alb.main.dns_name
}
output "private_key" {
  value     = tls_private_key.pivot_private_key.private_key_pem
  sensitive = true
}