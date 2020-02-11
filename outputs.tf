output "vpc_id" {
  description = "The ID of the VPC"
  value       = concat(aws_vpc.vpc.*.id, [""])[0]
}


output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.private_subnets.*.id
}

output "data_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.data_subnets.*.id
}
