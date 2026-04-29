output "asg_web_name" {
  value = aws_autoscaling_group.asg_web.name
}

output "launch_template_web_id" {
  value = aws_launch_template.web_server_lt.id
}

output "asg_app_name" {
  value = aws_autoscaling_group.asg_app.name
}

output "launch_template_app_id" {
  value = aws_launch_template.app_server_lt.id
}