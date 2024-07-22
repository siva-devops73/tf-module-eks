### Eks cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${var.env}-eks"
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

### Node group
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.env}-ng"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = var.capacity_type
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.min_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
}

### This is used for to connect iam role in amazon and also it is used to access the outside like google
resource "aws_iam_openid_connect_provider" "cluster_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}



