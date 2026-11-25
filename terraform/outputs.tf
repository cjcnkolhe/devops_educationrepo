
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "jenkins_public_ip" {
  value = aws_instance.devops_server.public_ip
}

output "jenkins_instance_id" {
  value = aws_instance.devops_server.id
}

output "jenkins_iam_role_arn" {
  value = aws_iam_role.jenkins_role.arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
