locals {
  asg_tags = ["${null_resource.tags_as_list_of_maps.*.triggers}"]

  # Followed recommendation http://67bricks.com/blog/?p=85
  # to workaround terraform not supporting short circut evaluation
  cluster_security_group_id = "${coalesce(join("", aws_security_group.cluster.*.id), var.cluster_security_group_id)}"

  worker_security_group_id = "${coalesce(join("", aws_security_group.workers.*.id), var.worker_security_group_id)}"
  kubeconfig_name          = "${var.kubeconfig_name == "" ? "eks_${var.cluster_name}" : var.kubeconfig_name}"

  # Mapping from the node type that we selected and the max number of pods that it can run
  # Taken from https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
  max_pod_per_node = {
    c4.large    = 29
    c4.xlarge   = 58
    c4.2xlarge  = 58
    c4.4xlarge  = 234
    c4.8xlarge  = 234
    c5.large    = 29
    c5.xlarge   = 58
    c5.2xlarge  = 58
    c5.4xlarge  = 234
    c5.9xlarge  = 234
    c5.18xlarge = 737
    i3.large    = 29
    i3.xlarge   = 58
    i3.2xlarge  = 58
    i3.4xlarge  = 234
    i3.8xlarge  = 234
    i3.16xlarge = 737
    m3.medium   = 12
    m3.large    = 29
    m3.xlarge   = 58
    m3.2xlarge  = 118
    m4.large    = 20
    m4.xlarge   = 58
    m4.2xlarge  = 58
    m4.4xlarge  = 234
    m4.10xlarge = 234
    m5.large    = 29
    m5.xlarge   = 58
    m5.2xlarge  = 58
    m5.4xlarge  = 234
    m5.12xlarge = 234
    m5.24xlarge = 737
    p2.xlarge   = 58
    p2.8xlarge  = 234
    p2.16xlarge = 234
    p3.2xlarge  = 58
    p3.8xlarge  = 234
    p3.16xlarge = 234
    r3.xlarge   = 58
    r3.2xlarge  = 58
    r3.4xlarge  = 234
    r3.8xlarge  = 234
    r4.large    = 29
    r4.xlarge   = 58
    r4.2xlarge  = 58
    r4.4xlarge  = 234
    r4.8xlarge  = 234
    r4.16xlarge = 737
    t2.small    = 8
    t2.medium   = 17
    t2.large    = 35
    t2.xlarge   = 44
    t2.2xlarge  = 44
    x1.16xlarge = 234
    x1.32xlarge = 234
  }

  ebs_optimized = {
    "c1.medium"    = false
    "c1.xlarge"    = true
    "c3.2xlarge"   = true
    "c3.4xlarge"   = true
    "c3.8xlarge"   = false
    "c3.large"     = false
    "c3.xlarge"    = false
    "c4.2xlarge"   = true
    "c4.4xlarge"   = true
    "c4.8xlarge"   = true
    "c4.large"     = true
    "c4.xlarge"    = true
    "c5.18xlarge"  = true
    "c5.2xlarge"   = true
    "c5.4xlarge"   = true
    "c5.9xlarge"   = true
    "c5.large"     = true
    "c5.xlarge"    = true
    "c5d.18xlarge" = true
    "c5d.2xlarge"  = true
    "c5d.4xlarge"  = true
    "c5d.9xlarge"  = true
    "c5d.large"    = true
    "c5d.xlarge"   = true
    "cc2.8xlarge"  = false
    "cr1.8xlarge"  = false
    "d2.2xlarge"   = true
    "d2.4xlarge"   = true
    "d2.8xlarge"   = true
    "d2.xlarge"    = true
    "f1.16xlarge"  = true
    "f1.2xlarge"   = true
    "g2.2xlarge"   = true
    "g2.8xlarge"   = false
    "g3.16xlarge"  = true
    "g3.4xlarge"   = true
    "g3.8xlarge"   = true
    "h1.16xlarge"  = true
    "h1.2xlarge"   = true
    "h1.4xlarge"   = true
    "h1.8xlarge"   = true
    "hs1.8xlarge"  = false
    "i2.2xlarge"   = true
    "i2.4xlarge"   = true
    "i2.8xlarge"   = false
    "i2.xlarge"    = true
    "i3.16xlarge"  = true
    "i3.2xlarge"   = true
    "i3.4xlarge"   = true
    "i3.8xlarge"   = true
    "i3.large"     = true
    "i3.metal"     = true
    "i3.xlarge"    = true
    "m1.large"     = true
    "m1.medium"    = false
    "m1.small"     = false
    "m1.xlarge"    = true
    "m2.2large"    = false
    "m2.2xlarge"   = true
    "m2.4xlarge"   = true
    "m2.xlarge"    = false
    "m3.2xlarge"   = true
    "m3.large"     = false
    "m3.medium"    = false
    "m3.xlarge"    = true
    "m4.10xlarge"  = true
    "m4.16xlarge"  = true
    "m4.2xlarge"   = true
    "m4.4xlarge"   = true
    "m4.large"     = true
    "m4.xlarge"    = true
    "m5.12xlarge"  = true
    "m5.24xlarge"  = true
    "m5.2xlarge"   = true
    "m5.4xlarge"   = true
    "m5.large"     = true
    "m5.xlarge"    = true
    "m5d.12xlarge" = true
    "m5d.24xlarge" = true
    "m5d.2xlarge"  = true
    "m5d.4xlarge"  = true
    "m5d.large"    = true
    "m5d.xlarge"   = true
    "p2.16xlarge"  = true
    "p2.8xlarge"   = true
    "p2.xlarge"    = true
    "p3.16xlarge"  = true
    "p3.2xlarge"   = true
    "p3.8xlarge"   = true
    "r3.2xlarge"   = false
    "r3.2xlarge"   = true
    "r3.4xlarge"   = true
    "r3.8xlarge"   = false
    "r3.large"     = false
    "r3.xlarge"    = true
    "r4.16xlarge"  = true
    "r4.2xlarge"   = true
    "r4.4xlarge"   = true
    "r4.8xlarge"   = true
    "r4.large"     = true
    "r4.xlarge"    = true
    "t1.micro"     = false
    "t2.2xlarge"   = false
    "t2.large"     = false
    "t2.medium"    = false
    "t2.micro"     = false
    "t2.nano"      = false
    "t2.small"     = false
    "t2.xlarge"    = false
    "x1.16xlarge"  = true
    "x1.32xlarge"  = true
    "x1e.16xlarge" = true
    "x1e.2xlarge"  = true
    "x1e.32xlarge" = true
    "x1e.4xlarge"  = true
    "x1e.8xlarge"  = true
    "x1e.xlarge"   = true
  }
}
