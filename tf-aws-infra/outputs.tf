output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}
output "s3_bucket_name" {
  value = aws_s3_bucket.webapp_bucket.bucket
}
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}