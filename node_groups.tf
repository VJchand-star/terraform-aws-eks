# Hack to ensure ordering of resource creation. Do not create node_groups
# before other resources are ready. Removes race conditions
data "null_data_source" "node_groups" {
  count = var.create_eks ? 1 : 0

  inputs = {
    cluster_name = var.cluster_name

    # Ensure these resources are created before "unlocking" the data source.
    # `depends_on` causes a refresh on every run so is useless here.
    # [Re]creating or removing these resources will trigger recreation of Node Group resources
    aws_auth        = coalescelist(kubernetes_config_map.aws_auth[*].id, [""])[0]
    role_NodePolicy = coalescelist(aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy[*].id, [""])[0]
    role_CNI_Policy = coalescelist(aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy[*].id, [""])[0]
    role_Container  = coalescelist(aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly[*].id, [""])[0]
  }
}

module "node_groups" {
  source                 = "./modules/node_groups" # git::https://github.com/cloudposse/terraform-aws-eks-node-group.git?ref=tags/0.24.0
  create_eks             = var.create_eks
  cluster_name           = coalescelist(data.null_data_source.node_groups[*].outputs["cluster_name"], [""])[0]
  default_iam_role_arn   = coalescelist(aws_iam_role.workers[*].arn, [""])[0]
  workers_group_defaults = local.workers_group_defaults
  tags                   = var.tags
  node_groups_defaults   = local.nodes_groups_defaults
  node_groups            = var.node_groups
}

# EC2 instance profile for managed node groups
resource "aws_iam_instance_profile" "node_group_instance_profile" {
  count       = var.create_eks ? 1 : 0
  name_prefix = aws_eks_cluster.this[0].name
  role = local.default_iam_role_id
  path = var.iam_path
}
