locals {
  name = "ex-${replace(basename(path.cwd), "_", "-")}"

  cluster_endpoint          = "https://012345678903AB2BAE5D1E0BFE0E2B50.gr7.us-east-1.eks.amazonaws.com"
  cluster_auth_base64       = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKbXFqQ1VqNGdGR2w3ZW5PeWthWnZ2RjROOTVOUEZCM2o0cGhVZUsrWGFtN2ZSQnZya0d6OGxKZmZEZWF2b2plTwpQK2xOZFlqdHZncmxCUEpYdHZIZmFzTzYxVzdIZmdWQ2EvamdRM2w3RmkvL1dpQmxFOG9oWUZkdWpjc0s1SXM2CnNkbk5KTTNYUWN2TysrSitkV09NT2ZlNzlsSWdncmdQLzgvRU9CYkw3eUY1aU1hS3lsb1RHL1V3TlhPUWt3ZUcKblBNcjdiUmdkQ1NCZTlXYXowOGdGRmlxV2FOditsTDhsODBTdFZLcWVNVlUxbjQyejVwOVpQRTd4T2l6L0xTNQpYV2lXWkVkT3pMN0xBWGVCS2gzdkhnczFxMkI2d1BKZnZnS1NzWllQRGFpZTloT1NNOUJkNFNPY3JrZTRYSVBOCkVvcXVhMlYrUDRlTWJEQzhMUkVWRDdCdVZDdWdMTldWOTBoL3VJUy9WU2VOcEdUOGVScE5DakszSjc2aFlsWm8KWjNGRG5QWUY0MWpWTHhiOXF0U1ROdEp6amYwWXBEYnFWci9xZzNmQWlxbVorMzd3YWM1eHlqMDZ4cmlaRUgzZgpUM002d2lCUEVHYVlGeWN5TmNYTk5aYW9DWDJVL0N1d2JsUHAKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ=="
  cluster_service_ipv4_cidr = "172.16.0.0/16"
  ami_id                    = "ami-12345678"
}

################################################################################
# User Data Module
################################################################################

# EKS managed node group - linux
module "eks_mng_linux_no_op" {
  source = "../../modules/_user_data"

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64
}

module "eks_mng_linux_additional" {
  source = "../../modules/_user_data"

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  user_data_env = {
    "CONTAINER_RUNTIME" = "containerd"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT
}

module "eks_mng_linux_additional_custom_template" {
  source = "../../modules/_user_data"

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  user_data_template_path = "${path.module}/templates/linux_mng_merge_custom.tpl"

  user_data_env = {
    "CONTAINER_RUNTIME" = "containerd"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT
}

module "eks_mng_linux_custom_ami" {
  source = "../../modules/_user_data"

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  ami_id = local.ami_id

  enable_bootstrap_user_data = true

  user_data_env = {
    "CONTAINER_RUNTIME"  = "containerd"
    "USE_MAX_PODS"       = "false"
    "KUBELET_EXTRA_ARGS" = "--max-pods=20 --instance-type t3a.large"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

module "eks_mng_linux_custom_ami_custom_join" {
  source = "../../modules/_user_data"

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  ami_id = local.ami_id

  enable_bootstrap_user_data = false

  user_data_env = {
    "CONTAINER_RUNTIME"  = "containerd"
    "USE_MAX_PODS"       = "false"
    "KUBELET_EXTRA_ARGS" = "--max-pods=20"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
    join-cluster.sh "$${CLUSTER_NAME}" --b64-cluster-ca "$${B64_CLUSTER_CA}" --apiserver-endpoint "$${API_SERVER_URL}"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

module "eks_mng_linux_custom_ami_custom_template" {
  source = "../../modules/_user_data"

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  ami_id = local.ami_id

  user_data_template_path = "${path.module}/templates/linux_custom.tpl"

  user_data_env = {
    "KUBELET_EXTRA_ARGS" = "--node-labels=node.kubernetes.io/lifecycle=spot"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

# EKS managed node group - bottlerocket
module "eks_mng_bottlerocket_no_op" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"
}

module "eks_mng_bottlerocket_additional" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

module "eks_mng_bottlerocket_custom_ami" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  enable_bootstrap_user_data = true

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

module "eks_mng_bottlerocket_custom_template" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  user_data_template_path = "${path.module}/templates/bottlerocket_custom.tpl"

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

# Self managed node group - linux
module "self_mng_linux_no_op" {
  source = "../../modules/_user_data"

  is_eks_managed_node_group = false
}

module "self_mng_linux_bootstrap" {
  source = "../../modules/_user_data"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  user_data_env = {
    "KUBELET_EXTRA_ARGS" = "--node-labels=node.kubernetes.io/lifecycle=spot"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

module "self_mng_linux_custom_join" {
  source = "../../modules/_user_data"

  enable_bootstrap_user_data = false
  is_eks_managed_node_group  = false

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  user_data_env = {
    "KUBELET_EXTRA_ARGS" = "--node-labels=node.kubernetes.io/lifecycle=spot"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
    join-cluster.sh "$${CLUSTER_NAME}" --b64-cluster-ca "$${B64_CLUSTER_CA}" --apiserver-endpoint "$${API_SERVER_URL}"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

module "self_mng_linux_custom_template" {
  source = "../../modules/_user_data"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name              = local.name
  cluster_endpoint          = local.cluster_endpoint
  cluster_auth_base64       = local.cluster_auth_base64
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  user_data_template_path = "${path.module}/templates/linux_custom.tpl"

  user_data_env = {
    "KUBELET_EXTRA_ARGS" = "--node-labels=node.kubernetes.io/lifecycle=spot"
  }

  pre_bootstrap_user_data = <<-EOT
    echo "Starting bootstrap"
  EOT

  post_bootstrap_user_data = <<-EOT
    echo "All done"
  EOT
}

# Self managed node group - bottlerocket
module "self_mng_bottlerocket_no_op" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  is_eks_managed_node_group = false
}

module "self_mng_bottlerocket_bootstrap" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

module "self_mng_bottlerocket_custom_template" {
  source = "../../modules/_user_data"

  platform = "bottlerocket"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  user_data_template_path = "${path.module}/templates/bottlerocket_custom.tpl"

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

# Self managed node group - windows
module "self_mng_windows_no_op" {
  source = "../../modules/_user_data"

  platform = "windows"

  is_eks_managed_node_group = false
}

module "self_mng_windows_bootstrap" {
  source = "../../modules/_user_data"

  platform = "windows"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  pre_bootstrap_user_data = <<-EOT
    [string]$Something = 'IDoNotKnowAnyPowerShell ¯\_(ツ)_/¯'
  EOT

  # I don't know if this is the right way on WindowsOS, but its just a string check here anyways
  bootstrap_extra_args = "-KubeletExtraArgs --node-labels=node.kubernetes.io/lifecycle=spot"

  post_bootstrap_user_data = <<-EOT
    [string]$Something = 'IStillDoNotKnowAnyPowerShell ¯\_(ツ)_/¯'
  EOT
}

module "self_mng_windows_custom_template" {
  source = "../../modules/_user_data"

  platform = "windows"

  enable_bootstrap_user_data = true
  is_eks_managed_node_group  = false

  cluster_name        = local.name
  cluster_endpoint    = local.cluster_endpoint
  cluster_auth_base64 = local.cluster_auth_base64

  user_data_template_path = "${path.module}/templates/windows_custom.tpl"

  pre_bootstrap_user_data = <<-EOT
    [string]$Something = 'IDoNotKnowAnyPowerShell ¯\_(ツ)_/¯'
  EOT

  # I don't know if this is the right way on WindowsOS, but its just a string check here anyways
  bootstrap_extra_args = "-KubeletExtraArgs --node-labels=node.kubernetes.io/lifecycle=spot"

  post_bootstrap_user_data = <<-EOT
    [string]$Something = 'IStillDoNotKnowAnyPowerShell ¯\_(ツ)_/¯'
  EOT
}
