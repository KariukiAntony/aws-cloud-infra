
# Random subnet id for bastion host
resource "random_shuffle" "bastion" {
  result_count = 1
  input        = var.public_subnet_ids
  keepers = {
    ami_id = var.bastion_instance_type
  }
}

# Bastion host
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = random_shuffle.bastion.result[0]
  vpc_security_group_ids      = [var.bastion_security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_pair

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags = merge(var.tags, {
      Name = "${var.base_name}-bastion-volume"
    })
  }

  user_data = var.bastion_user_data_script != "" ? templatefile(var.bastion_user_data_script, {
    hostname = "${var.base_name}-bastion"
  }) : null

  tags = merge(var.tags, {
    Name = "${var.base_name}-bastion"
  })

}
