# Enforce required tags at resource creation using an SCP pattern based on aws:RequestTag condition keys.
# This is broad; in production we may split by service or OU.

# Deny create if required tag keys are missing
resource "aws_organizations_policy" "require_tags" {
  name = "RequireTagsOnCreate"
  type = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Sid : "DenyCreateWithoutTags",
      Effect : "Deny",
      Action : [
        "ec2:RunInstances", "ec2:CreateVolume", "ec2:CreateSnapshot",
        "rds:CreateDBInstance", "rds:CreateDBCluster",
        "es:CreateDomain", "dynamodb:CreateTable",
        "s3:CreateBucket", "logs:CreateLogGroup",
        "sns:CreateTopic", "sqs:CreateQueue", "kms:CreateKey"
      ],
      Resource : "*",
      Condition : {
        "ForAllValues:StringEquals" : { "aws:TagKeys" : var.required_tag_keys }
      }
    }]
  })
}

resource "aws_organizations_policy_attachment" "attach" {
  policy_id = aws_organizations_policy.require_tags.id
  target_id = var.target_id
}
