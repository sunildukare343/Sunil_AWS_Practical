data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  for_each = var.eks_clusters

  name               = "${each.key}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(
    {
      Name = "${each.key}-cluster-role"
    },
    each.value.tags
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  for_each = var.eks_clusters

  role       = aws_iam_role.cluster[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_kms" {
  for_each = var.eks_clusters

  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.region}.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${each.key}/cluster"
      ]
    }
  }
}

resource "aws_kms_key" "cluster" {
  for_each = var.eks_clusters

  description             = "EKS KMS key for ${each.key}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.eks_kms[each.key].json

  tags = merge(
    {
      Name = "${each.key}-kms-key"
    },
    each.value.tags
  )
}

resource "aws_kms_alias" "cluster" {
  for_each = var.eks_clusters

  name          = "alias/${each.key}-eks-key"
  target_key_id = aws_kms_key.cluster[each.key].key_id
}

resource "aws_cloudwatch_log_group" "cluster" {
  for_each = var.eks_clusters

  name              = "/aws/eks/${each.key}/cluster"
  retention_in_days = each.value.log_retention_days

  kms_key_id = aws_kms_key.cluster[each.key].arn

  tags = merge(
    {
      Name = "${each.key}-logs"
    },
    each.value.tags
  )

  depends_on = [aws_kms_key.cluster]
}


resource "aws_eks_cluster" "this" {
  for_each = var.eks_clusters

  name                          = each.key
  role_arn                      = aws_iam_role.cluster[each.key].arn
  version                       = each.value.version
  bootstrap_self_managed_addons = each.value.bootstrap_self_managed_addons
  enabled_cluster_log_types     = each.value.cluster_log_types

  access_config {
    authentication_mode                         = each.value.authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {

    endpoint_private_access = each.value.endpoint_private_access
    endpoint_public_access  = each.value.endpoint_public_access
    public_access_cidrs     = each.value.endpoint_public_access ? each.value.public_access_cidrs : null

    subnet_ids = [
      for subnet_key in each.value.subnet_keys :
      var.subnet_ids[subnet_key]
    ]

    security_group_ids = [
      for sg_key in each.value.security_group_keys :
      var.security_group_ids[sg_key]
    ]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster[each.key].arn
    }

    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(
    {
      Name = each.key
    },
    each.value.tags
  )
}

data "tls_certificate" "oidc" {
  for_each = var.eks_clusters

  url = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.eks_clusters

  url = aws_eks_cluster.this[each.key].identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.oidc[each.key].certificates[0].sha1_fingerprint
  ]

  tags = merge(
    {
      Name = "${each.key}-oidc"
    },
    each.value.tags
  )
}
