resource "aws_s3_bucket" "this" {
  bucket = "ifx-terraterm-bucket"

  tags = {
    Name = "terraform-tutorial"
  }
}