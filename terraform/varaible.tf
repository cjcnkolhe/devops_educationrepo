

# --------------------------------
# EC2 Instance Type
# --------------------------------

variable "instance_type" {
  default = "c7i-flex.large"
}

# --------------------------------
# EC2 Key Pair
# --------------------------------

variable "key_name" {
  description = "AWS key pair name"
  default     = "jenkinsKP"
}

# --------------------------------
# EKS Cluster Name
# --------------------------------

variable "cluster_name" {
  default = "java-eks-cluster"
}

# --------------------------------
# EKS Node Instance Type
# --------------------------------

variable "node_instance_type" {
  default = "c7i-flex.large"
}

# --------------------------------
# EKS Desired Nodes
# --------------------------------

variable "desired_size" {
  default = 2
}
