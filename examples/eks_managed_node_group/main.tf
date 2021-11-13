provider "aws" {
  region = local.region
}

locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
  cluster_version = "1.20"
  region          = "eu-west-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# EKS Module
################################################################################

# data "cloudinit_config" "custom" {
#   gzip          = false
#   base64_encode = true
#   boundary      = "//"

#   part {
#     content_type = "text/x-shellscript"
#     content      = "echo 'hello world!'"
#   }
# }

module "eks" {
  source = "../.."

  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    default_node_group = {}
    # create_launch_template = {
    #   create_launch_template  = true
    #   launch_template_name    = "create-launch-template"
    #   pre_bootstrap_user_data = "echo 'hello world!'"
    # }
    # custom_ami = {
    #   create_launch_template = true
    #   launch_template_name   = "custom-ami"

    #   # Current default AMI used by managed node groups - pseudo "custom"
    #   ami_id = "ami-0caf35bc73450c396"
    # }
    # use arleady defined launch template
    # example1 = {
    #   name_prefix      = "example1"
    #   desired_capacity = 1
    #   max_capacity     = 15
    #   min_capacity     = 1

    #   launch_template_id      = aws_launch_template.default.id
    #   launch_template_version = aws_launch_template.default.default_version

    #   instance_types = ["t3.small"]

    #   tags = merge(local.tags, {
    #     ExtraTag = "example1"
    #   })
    # }


    # create launch template
    # example2 = {
    #   create_launch_template = true
    #   desired_capacity       = 1
    #   max_capacity           = 10
    #   min_capacity           = 1

    #   disk_size       = 50
    #   disk_type       = "gp3"
    #   disk_throughput = 150
    #   disk_iops       = 3000

    #   instance_types = ["t3.large"]
    #   capacity_type  = "SPOT"

    #   bootstrap_env = {
    #     CONTAINER_RUNTIME = "containerd"
    #     USE_MAX_PODS      = false
    #   }
    #   bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"
    #   k8s_labels = {
    #     GithubRepo = "terraform-aws-eks"
    #     GithubOrg  = "terraform-aws-modules"
    #   }
    #   additional_tags = {
    #     ExtraTag = "example2"
    #   }
    #   taints = [
    #     {
    #       key    = "dedicated"
    #       value  = "gpuGroup"
    #       effect = "NO_SCHEDULE"
    #     }
    #   ]
    #   update_config = {
    #     max_unavailable_percentage = 50 # or set `max_unavailable`
    #   }
    # }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name                 = local.name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = local.tags
}