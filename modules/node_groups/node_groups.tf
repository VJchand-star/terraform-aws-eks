resource "aws_eks_node_group" "workers" {
  for_each = local.node_groups_keys

  node_group_name = join("-", [var.cluster_name, each.key, random_pet.node_groups[each.key].id])

  cluster_name  = var.cluster_name
  node_role_arn = random_pet.node_groups[each.key].keepers.node_role_arn
  subnet_ids    = split("|", random_pet.node_groups[each.key].keepers.subnet_ids)

  scaling_config {
    desired_size = lookup(local.node_groups_expanded[each.key], "desired_capacity", var.workers_group_defaults["asg_desired_capacity"])
    max_size     = lookup(local.node_groups_expanded[each.key], "max_capacity", var.workers_group_defaults["asg_max_size"])
    min_size     = lookup(local.node_groups_expanded[each.key], "min_capacity", var.workers_group_defaults["asg_min_size"])
  }

  ami_type        = lookup(random_pet.node_groups[each.key].keepers, "ami_type", null)
  disk_size       = lookup(random_pet.node_groups[each.key].keepers, "disk_size", null)
  instance_types  = [random_pet.node_groups[each.key].keepers.instance_type]
  release_version = lookup(local.node_groups_expanded[each.key], "ami_release_version", null)

  dynamic "remote_access" {
    for_each = random_pet.node_groups[each.key].keepers.ec2_ssh_key != "" ? [{
      ec2_ssh_key               = random_pet.node_groups[each.key].keepers.ec2_ssh_key
      source_security_group_ids = compact(split("|", random_pet.node_groups[each.key].keepers.source_security_group_ids))
    }] : []

    content {
      ec2_ssh_key               = remote_access.value["ec2_ssh_key"]
      source_security_group_ids = remote_access.value["source_security_group_ids"]
    }
  }

  version = var.cluster_version

  labels = merge(
    lookup(var.node_groups_defaults, "k8s_labels", {}),
    lookup(var.node_groups[each.key], "k8s_labels", {})
  )

  tags = merge(
    var.tags,
    lookup(var.node_groups_defaults, "additional_tags", {}),
    lookup(var.node_groups[each.key], "additional_tags", {}),
  )

  lifecycle {
    create_before_destroy = true
  }
}
