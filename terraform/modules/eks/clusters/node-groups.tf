data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

locals {
  managed_node_groups = merge([
    for cluster_key, cluster in var.eks_clusters : {
      for ng_key, ng in cluster.managed_node_groups :
      "${cluster_key}-${ng_key}" => merge(ng, {
        cluster_key = cluster_key
        node_key    = ng_key
      })
    }
  ]...)
}

resource "aws_iam_role" "node" {
  for_each = local.managed_node_groups

  name               = "${each.key}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = {
    Name = "${each.key}-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "worker" {
  for_each = local.managed_node_groups

  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  for_each = local.managed_node_groups

  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  for_each = local.managed_node_groups

  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "this" {
  for_each = local.managed_node_groups

  cluster_name    = aws_eks_cluster.this[each.value.cluster_key].name
  node_group_name = each.value.node_key
  node_role_arn   = aws_iam_role.node[each.key].arn

  subnet_ids = [
    for subnet_key in coalesce(
      try(each.value.subnet_keys, null),
      try(var.eks_clusters[each.value.cluster_key].subnet_keys, null),
      []
    ) : var.subnet_ids[subnet_key]
  ]

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  labels = merge(
    {
      "node-group" = each.value.node_key
      "cluster"    = each.value.cluster_key
    },
    try(each.value.labels, {})
  )

  dynamic "taint" {
    for_each = try(each.value.taints, [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    {
      Name                                                  = each.key
      "k8s.io/cluster-autoscaler/enabled"                   = "true"
      "k8s.io/cluster-autoscaler/${each.value.cluster_key}" = "owned"
    },
    try(each.value.tags, {})
  )

  depends_on = [
    aws_iam_role_policy_attachment.worker,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr
  ]
}
