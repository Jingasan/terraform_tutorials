# 各種リソースのtfファイルがあるディレクトリのパス
module "cloudfront" {
  source = "./modules/cloudfront"

  aws_s3_bucket = module.s3.aws_s3_bucket
}

module "s3" {
  source = "./modules/s3"

  aws_cloudfront_distribution_arn = module.cloudfront.aws_cloudfront_distribution_arn
}

