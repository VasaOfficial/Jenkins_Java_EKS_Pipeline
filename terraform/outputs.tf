output "vpc_id" {
  value = module.vpc.vpc_id
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
