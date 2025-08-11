resource "aws_s3_bucket" "tf_bucket" {
  bucket        = "tf-s3-bucket-super-unique-name"
  force_destroy = true

  tags = {
    Name = "tf-bucket"
  }
}


resource "aws_s3_object" "tf_obj" {
  bucket  = aws_s3_bucket.tf_bucket.id
  key     = "tf-obj"
  content = "Hello from S3"
}
