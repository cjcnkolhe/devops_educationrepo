
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "java-eks-cluster"
}

variable "node_instance_type" {
  description = "EKS Worker Node Instance Type"
  type        = string
  default     = "c7i-flex.large"
}

variable "desired_size" {
  description = "Desired Worker Node Count"
  type        = number
  default     = 2
}
