# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "$accesskey"
  secret_key = "$secretKey"
}

#1 Create a VPC
resource "aws_vpc" "testvpc" {
  cidr_block = "10.0.0.0/16"
}
#2 Create internet gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.testvpc.id
}

#3 Create custom route table
resource "aws_route_table" "test-route-table" {
   vpc_id = aws_vpc.testvpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
   }

   route {
     ipv6_cidr_block = "::/0"
     gateway_id      = aws_internet_gateway.gw.id
   }

 }

#4 create a subnet
resource "aws_subnet" "testsubnet" {
  vpc_id     = aws_vpc.testvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

#5 Associate subnet with Route Table
resource "aws_route_table_association" "a" {
   subnet_id      = aws_subnet.testsubnet.id
   route_table_id = aws_route_table.test-route-table.id
 }

#6 Create security group
resource "aws_security_group" "testsg" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.testvpc.id

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
#7 Create network interface
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.testsubnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.testsg.id]
  }
#8 Assign Elastic IP
 resource "aws_eip" "one" {
   vpc                       = true
   network_interface         = aws_network_interface.test.id
   associate_with_private_ip = "10.0.1.50"
   depends_on                = [aws_internet_gateway.gw]
 }

#9 Create ec2 instance & install httpd
resource "aws_instance" "webserver" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"
    
    network_interface {
     device_index         = 0
     network_interface_id = aws_network_interface.test.id
   }

   user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo Webserver with Terraform > /var/www/html/index.html'
                 EOF
 }

