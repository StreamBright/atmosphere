provider "aws" {
  region                   = "eu-central-1"
  #does not seem to support ~
  shared_credentials_file  = "/Users/l1x/.aws/credentials"
  profile                  = "default"
}

resource "aws_cloudtrail" "audit" {
    name = "sb-audit"
    s3_bucket_name = "${aws_s3_bucket.sb-tf-test.id}"
    s3_key_prefix = "/audit"
    include_global_service_events = false
}

/*
    Website hosting
    https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
    bucket = "s3-website-test.test.com"
    acl = "public-read"
    policy = "${file("policy.json")}"

    website {
        index_document = "index.html"
        error_document = "error.html"
    }
*/
resource "aws_s3_bucket" "sb-tf-test" {
    bucket = "sb-tf-test"
    force_destroy = false
    acl = "private"
    tags {
      Name = "SB Terraform"
      Environment = "Dev"
    }
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::sb-tf-test"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::sb-tf-test/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

# groups

resource "aws_iam_group" "sb-adm" {
    name = "sb-adm"
    path = "/group/"
}

resource "aws_iam_group" "sb-api" {
    name = "sb-api"
    path = "/group/"
}

# users 

resource "aws_iam_user" "sb-api-app1" {
    name = "sb-api-app1"
    path = "/system/"
}

resource "aws_iam_user" "sb-api-app2" {
    name = "sb-api-app2"
    path = "/system/"
}

resource "aws_iam_user" "jane" {
    name = "jane"
    path = "/users/"
}

resource "aws_iam_user" "jack" {
    name = "jack"
    path = "/users/"
}

#membership

resource "aws_iam_group_membership" "sb-adm-team" {
  name = "sb-adm-team"
  users = [
    "${aws_iam_user.jane.name}",
    "${aws_iam_user.jack.name}",
  ]
  group = "${aws_iam_group.sb-adm.name}"
}

resource "aws_iam_group_membership" "sb-api-apps" {
  name = "sb-api-apps"
  users = [
    "${aws_iam_user.sb-api-app1.name}",
    "${aws_iam_user.sb-api-app2.name}"
  ]
  group = "${aws_iam_group.sb-api.name}"
}

/*
#access key

resource "aws_iam_access_key" "joe" {
  user = "${aws_iam_user.joe.name}"
}
*/

# policy

##  Giving admin access to admin group

resource "aws_iam_group_policy" "sb-adm-team_all" {
  name = "sb-adm-team_all"
  group = "${aws_iam_group.sb-adm.name}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:*", "ec2:*", "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
} 

##  Giving read-only access for sb-api group
##  "Action": [ "ec2:Describe*" ]
##  "Effect": "Allow"
##  "Resource": "*"

resource "aws_iam_group_policy" "sb-api_ro" {
  name = "read-test"
  group = "${aws_iam_group.sb-api.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
