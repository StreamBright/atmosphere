
resource "aws_cloudtrail" "audit" {
    name = "sb-audit"
    s3_bucket_name = "${aws_s3_bucket.sb-tf-test.id}"
    s3_key_prefix = "/audit"
    include_global_service_events = false
}

resource "aws_s3_bucket" "sb-tf-test" {
    bucket = "sb-tf-test"
    force_destroy = true
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

# users 

resource "aws_iam_user" "api-user-1" {
    name = "API 1"
    path = "/system/"
}

resource "aws_iam_user" "joe" {
    name = "Joe Doe"
    path = "/users/"
}

resource "aws_iam_user" "jack" {
    name = "Joe Doe"
    path = "/users/"
}

#membership

resource "aws_iam_group_membership" "sb-adm-team" {
    name = "sb-adm-team"
    users = [
        "${aws_iam_user.joe.name}",
        "${aws_iam_user.jack.name}",
    ]
    group = "${aws_iam_group.sb-adm.name}"
}

#access key

resource "aws_iam_access_key" "joe" {
    user = "${aws_iam_user.joe.name}"
}

# policy

resource "aws_iam_user_policy" "api-user-1_ro" {
    name = "read-test"
    user = "${aws_iam_user.api-user-1.name}"
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




/* 
  resource "aws_instance" "example" {
      ami = "ami-bc5b48d0"
      instance_type = "t2.micro"
  }
*/
