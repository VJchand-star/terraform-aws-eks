locals {

  # EKS Cluster
  cluster_id                        = try(aws_eks_cluster.this[0].id, "")
  cluster_arn                       = try(aws_eks_cluster.this[0].arn, "")
  cluster_endpoint                  = try(aws_eks_cluster.this[0].endpoint, "")
  cluster_auth_base64               = try(aws_eks_cluster.this[0].certificate_authority[0].data, "")
  cluster_primary_security_group_id = try(aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id, "")

  cluster_security_group_id = var.create_cluster_security_group ? join("", aws_security_group.cluster.*.id) : var.cluster_security_group_id

  # Worker groups
  worker_security_group_id = var.create_worker_security_group ? join("", aws_security_group.worker.*.id) : var.worker_security_group_id
  policy_arn_prefix        = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  # launch_template_userdata_rendered = var.create ? [
  #   for key, group in var.worker_groups : templatefile(
  #     try(
  #       group.userdata_template_file,
  #       lookup(group, "platform", var.default_platform) == "windows"
  #       ? "${path.module}/templates/userdata_windows.tpl"
  #       : "${path.module}/templates/userdata.sh.tpl"
  #     ),
  #     merge({
  #       platform             = lookup(group, "platform", var.default_platform)
  #       cluster_name         = var.cluster_name
  #       endpoint             = local.cluster_endpoint
  #       cluster_auth_base64  = local.cluster_auth_base64
  #       pre_userdata         = lookup(group, "pre_userdata", "")
  #       additional_userdata  = lookup(group, "additional_userdata", "")
  #       bootstrap_extra_args = lookup(group, "bootstrap_extra_args", "")
  #       kubelet_extra_args   = lookup(group, "kubelet_extra_args", "")
  #       },
  #       lookup(group, "userdata_template_extra_args", "")
  #     )
  #   )
  # ] : []
}
