resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

output "eip_id" {
  value = aws_eip.nat.id
}