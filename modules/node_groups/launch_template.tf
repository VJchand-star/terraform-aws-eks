data "cloudinit_config" "workers_userdata" {
  for_each = { for k, v in local.node_groups_expanded : k => v if v["create_launch_template"] }

  gzip          = false
  base64_encode = true
  boundary      = "//"

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/userdata.sh.tpl",
      {
        pre_userdata       = each.value["pre_userdata"]
        kubelet_extra_args = each.value["kubelet_extra_args"]
      }
    )
  }
}

# This is based on the LT that EKS would create if no custom one is specified (aws ec2 describe-launch-template-versions --launch-template-id xxx)
# there are several more options one could set but you probably dont need to modify them
# you can take the default and add your custom AMI and/or custom tags
#
# Trivia: AWS transparently creates a copy of your LaunchTemplate and actually uses that copy then for the node group. If you DONT use a custom AMI,
# then the default user-data for bootstrapping a cluster is merged in the copy.
resource "aws_launch_template" "workers" {
  for_each = { for k, v in local.node_groups_expanded : k => v if v["create_launch_template"] }

  name_prefix            = local.node_groups_names[each.key]
  description            = format("EKS Managed Node Group custom LT for %s", local.node_groups_names[each.key])
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = lookup(each.value, "disk_size", null)
      volume_type           = lookup(each.value, "disk_type", null)
      encrypted = lookup(each.value, "root_encrypted", null)
      kms_key_id = lookup(each.value, "root_kms_key_id", null)
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = lookup(each.value, "enable_monitoring", null)
  }

  network_interfaces {
    associate_public_ip_address = lookup(each.value, "public_ip", null)
    delete_on_termination       = lookup(each.value, "eni_delete", null)
    security_groups = flatten([
      local.worker_security_group_id,
      var.worker_additional_security_group_ids,
      lookup(
        var.worker_groups_launch_template[count.index],
        "additional_security_group_ids",
        local.workers_group_defaults["additional_security_group_ids"],
      ),
    ])
  }

  # if you want to use a custom AMI
  # image_id      = var.ami_id

  # If you use a custom AMI, you need to supply via user-data, the bootstrap script as EKS DOESNT merge its managed user-data then
  # you can add more than the minimum code you see in the template, e.g. install SSM agent, see https://github.com/aws/containers-roadmap/issues/593#issuecomment-577181345
  #
  # (optionally you can use https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/cloudinit_config to render the script, example: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/997#issuecomment-705286151)

  user_data = data.cloudinit_config.workers_userdata[each.key].rendered

  key_name = lookup(each.value, "key_name", null)

  # Supplying custom tags to EKS instances is another use-case for LaunchTemplates
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      lookup(var.node_groups_defaults, "additional_tags", {}),
      lookup(var.node_groups[each.key], "additional_tags", {}),
      {
        Name = "eks-${local.node_groups_names[each.key]}"
      }
    )
  }

  # Supplying custom tags to EKS instances root volumes is another use-case for LaunchTemplates. (doesnt add tags to dynamically provisioned volumes via PVC tho)
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.tags,
      lookup(var.node_groups_defaults, "additional_tags", {}),
      lookup(var.node_groups[each.key], "additional_tags", {}),
      {
        Name = "eks-${local.node_groups_names[each.key]}"
      }
    )
  }

  # Tag the LT itself
  tags = merge(
    var.tags,
    lookup(var.node_groups_defaults, "additional_tags", {}),
    lookup(var.node_groups[each.key], "additional_tags", {}),
  )

  lifecycle {
    create_before_destroy = true
  }
}