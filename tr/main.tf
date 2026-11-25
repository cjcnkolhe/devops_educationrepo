
# =====================================================
# VPC
# =====================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  enable_nat_gateway = false
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = {
    Environment = "dev"
    Project     = "java-devops"
  }
}


# =====================================================
# JENKINS EC2 SECURITY GROUP
# =====================================================

resource "aws_security_group" "devops_sg" {
  name        = "devops-sg1"
  description = "Security group for DevOps EC2 server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube access"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort"
    from_port   = 30007
    to_port     = 30007
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg1"
  }
}


# =====================================================
# JENKINS IAM ROLE
# =====================================================

resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}


# =====================================================
# JENKINS EKS IAM PERMISSIONS
# =====================================================

resource "aws_iam_role_policy" "jenkins_eks_policy" {
  name = "jenkins-eks-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "eks:ListClusters",
        "eks:DescribeCluster",
        "eks:ListNodegroups",
        "eks:DescribeNodegroup"
      ]

      Resource = "*"
    }]
  })
}


# =====================================================
# JENKINS INSTANCE PROFILE
# =====================================================

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-eks-profile"
  role = aws_iam_role.jenkins_role.name
}


# =====================================================
# JENKINS EC2 INSTANCE
# =====================================================

resource "aws_instance" "devops_server" {
  ami                         = "ami-083cf4acad89c8905"
  instance_type               = "c7i-flex.large"
  key_name                    = "jenkinsKP"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.devops_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size           = 28
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "java-devops-server"
    Environment = "dev"
  }
}


# =====================================================
# EKS CLUSTER
# =====================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = "1.35"

  enable_cluster_creator_admin_permissions = true

  endpoint_public_access  = true
  endpoint_private_access = true

  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  authentication_mode = "API_AND_CONFIG_MAP"

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      desired_size = var.desired_size
      min_size     = 1
      max_size     = 3
    }
  }

  access_entries = {
    jenkins = {
      principal_arn = aws_iam_role.jenkins_role.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "java-devops"
  }
}


# =====================================================
# JENKINS TO EKS SECURITY GROUP ACCESS
# =====================================================

resource "aws_vpc_security_group_ingress_rule" "jenkins_to_eks" {
  security_group_id = module.eks.cluster_primary_security_group_id

  description = "Allow Jenkins EC2 to access EKS API"

  referenced_security_group_id = aws_security_group.devops_sg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}
