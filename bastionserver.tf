resource "aws_instance" "name" {
    ami = "ami-0157af9aea2eef346"
    instance_type = "t3.micro"
    key_name = var.key-name
    subnet_id = aws_subnet.pub1.id
    vpc_security_group_ids = [aws_security_group.bastion-host.id ]
    tags = {
      Name= "bastion-server"
    }
}