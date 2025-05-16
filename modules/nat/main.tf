resource "aws_nat_gateway" "gw" {
  allocation_id = var.eip_id
  subnet_id     = var.subnet_id
  tags = {
    Name = "nat-gateway"
  }
  depends_on = [var.vpc_id]
}
