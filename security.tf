resource "aws_iam_role" "tf_private_instance_role" {
  name = "tf-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_policy_attachment" "tf_s3_access_attachment" {
  name       = "s3-access-attachment"
  roles      = [aws_iam_role.tf_private_instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


resource "aws_iam_instance_profile" "tf_private_instance_profile" {
  name = "tf-instance-profile"
  role = aws_iam_role.tf_private_instance_role.name
}
