output "username" {
  value = var.username
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}