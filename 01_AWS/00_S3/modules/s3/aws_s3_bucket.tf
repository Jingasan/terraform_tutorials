resource "aws_s3_bucket" "this" {
  bucket = "terraform-tutorial-bucket"

  tags = {
    Name = "terraform-tutorial"
  }
}