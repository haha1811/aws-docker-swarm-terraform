resource "aws_instance" "manager" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  key_name      = var.manager_key_pair
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("${path.module}/scripts/manager.sh")

  tags = {
    Name = "swarm-manager"
  }
}

resource "aws_instance" "workers" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.private_subnet_ids[count.index]
  key_name      = var.manager_key_pair
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  user_data = file("${path.module}/scripts/worker.sh")

  tags = {
    Name = "swarm-worker-${count.index}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

output "manager_public_ip" {
  value = aws_instance.manager.public_ip
}
