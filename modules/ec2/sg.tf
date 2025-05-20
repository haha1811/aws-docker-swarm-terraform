resource "aws_security_group" "swarm_sg" {
  name   = "swarm-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
#    cidr_blocks = ["210.64.53.104/32"] # PTC IP
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["3.112.126.231/32"] # AWS Cloud9
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # ✅ 允許 all traffic
    cidr_blocks = ["10.0.0.0/16"]  # ✅ 僅限內部私有網段
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"             # ✅ 允許 all traffic
#    cidr_blocks = ["210.64.53.104/32"]  # PTC IP
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"             # ✅ 允許 all traffic
#    cidr_blocks = ["210.64.53.104/32"]  # PTC IP
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "swarm_sg"  # ✅ 加入標籤
  }
}