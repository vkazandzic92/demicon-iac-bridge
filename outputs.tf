output "lb_arn" {
  description = "The ARN of the load balancer we created."
  value       = aws_alb.demicon.arn
}