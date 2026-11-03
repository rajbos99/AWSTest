
# Instances are partitioned by prevent_destroy because Terraform requires a literal
# boolean inside lifecycle blocks and doesn't permit dynamic expressions.

resource "aws_instance" "protected" {
  for_each = {
    for k, v in var.instances : k => v
    if try(v.prevent_destroy, false)
  }

  ami           = coalesce(each.value.ami_id, var.default_ami_id)
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  subnet_id     = try(each.value.subnet_id, null)

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = contains(["io1", "io2", "gp3"], each.value.root_volume_type) ? each.value.iops : null
    throughput            = each.value.root_volume_type == "gp3" ? each.value.throughput : null
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = each.key
    Environment = each.value.environment
    Owner       = each.value.owner
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "standard" {
  for_each = {
    for k, v in var.instances : k => v
    if !try(v.prevent_destroy, false)
  }

  ami           = coalesce(each.value.ami_id, var.default_ami_id)
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  subnet_id     = try(each.value.subnet_id, null)

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = contains(["io1", "io2", "gp3"], each.value.root_volume_type) ? each.value.iops : null
    throughput            = each.value.root_volume_type == "gp3" ? each.value.throughput : null
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = each.key
    Environment = each.value.environment
    Owner       = each.value.owner
  }
}
