# Give short lived session access to ECR from ECS machines

resource "aws_iam_role" "foo_role" {
  name               = "foo_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Sid": "foo",
        "Principal": {
            "Service": ["ecs.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "foo_role" {
  name   = "foo_role"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages"
            ],
            "Resource": "arn:aws:ecr:${var.region}:${module.foo.aws_account_id}:repository/*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "foo_role" {
  name       = "foo_role"
  roles      = [aws_iam_role.foo_role.name]
  policy_arn = aws_iam_policy.foo_role.arn
}