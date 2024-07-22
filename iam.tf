## Iam policy for cluster
resource "aws_iam_role" "eks-role" {
  name               = "${var.env}-eks-role"
  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [
                         {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-role.name
}

## Iam policy for Node group
resource "aws_iam_role" "node-role" {
  name = "${var.env}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-role.name
}


### This policy is used for service account and also it is used to connect oidc
## Policy
resource "aws_iam_policy" "sa-policy" {
  name        = "eks-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "eks-${var.env}-ssm-pm-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ],
        "Resource":[
          "arn:aws:ssm:us-east-1:904827379241:parameter/roboshop.*",
          var.kms_arn
        ]
      }
    ]
  })
}


## Iam Role
resource "aws_iam_role" "sa-role" {
  name = "eks-${var.env}-ssm-pm-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": aws_iam_openid_connect_provider.cluster_oidc.arn
        },
        "Condition": {
          "StringEquals": {
            "oidc.eks.us-east-1.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.cluster_oidc.arn), 3)}:aud": [
              "sts.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

## IAM Policy role attachment
resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.sa-role.name
  policy_arn = aws_iam_policy.sa-policy.arn
}
