
provider "aws" {
  region = "eu-west-3"  
}

resource "aws_vpc" "com_mediasoft_europe_vpc_finance" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
    Name = "europe.main"
  }
  
}

resource "aws_subnet" "private_subnet" {
    
    count = 2
    vpc_id = aws_vpc.com_mediasoft_europe_vpc_finance.id
    availability_zone_id = count.index == 0  ? element(var.azs, 0) :  element(var.azs, 1) 
    cidr_block= element(var.vpc_subnet_cidr_block,count.index)
tags = {
   Name = "finance_depertement_private_subnet ${count.index + 1}"
 }
}

resource "aws_subnet" "public_subnet" {
    count = 2
    vpc_id = aws_vpc.com_mediasoft_europe_vpc_finance.id
    availability_zone_id = count.index == 0 ? element(var.azs, 0) :  element(var.azs, 1) 
    cidr_block= element(var.vpc_subnet_cidr_block,count.index+2)
     map_public_ip_on_launch = true
tags = {
   Name = "finance_depertement_public_subnet ${count.index+3}"
 }
}
resource "aws_security_group" "allow_ssh_and_http" {
  name        = "allow_tls_and_http_security_group"
  description = "Allow TLS/http inbound traffic and outbound traffic"
  vpc_id      = aws_vpc.com_mediasoft_europe_vpc_finance.id

  tags = {
    Name = "allow_tls_and_http_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh_and_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_and_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_ssh_and_http.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  cidr_ipv4       = "0.0.0.0/0"
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_ssh_and_http.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4       = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_tomcat" {
  security_group_id = aws_security_group.allow_ssh_and_http.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  cidr_ipv4       = "0.0.0.0/0"
}
resource "aws_key_pair" "admin-key_name" {
  key_name   = "admin-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDA+M+b/4DeM4/ubS9VtJz9/UkBAsrx7/xiTgnEq4SMCv4aV5xfZC0G03ywiVlmym+vVvMuQTpaEQkmBjnohqdsINelMjxYbK4zuTGfAVjda4sL8FlUmsYGBBmx7VK6FDmEScfxkz5VM4PcaEzudY+vPSMM6Wj1dQRaioYEXqBm9SYLoj6lKx2ZWFdyg3yLd+JC12qsoG8cfMgwik9FR6rrn9uWQRYin86sn1ZcrsZvbsjAd/Ss6CtPOpIY5gkV83cDvIkjefTXDbWGjW971getrDPvNZA+ArpBgNa4OUxw5hEmWrflkaWoM6kLRlL7bCPmUOC3U1qH+cv+PFvGAcN8YKyGhM7eRH+sLzPG6+4bwuozbBmVfdYbMzAhUx8eYWXy8yzmBI3edC+nhb3yTz33wrcuG6+HbHOg1f0UxZ0KrdetVzf/RUGuLfFJIlDaQUS+kIxTeYw+hjEoCDdIkU4hoO3EOftTqEOa1Pp1PSiLx5B95L7AlS8LZG6mzwdYsuM= hpr@DESKTOP-3GNKSHF"
  tags = {
    name="front_instance_admin_key"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]  # Limite la recherche aux AMIs Amazon

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Filtre pour les AMIs Amazon Linux 2
  }
}

resource "aws_instance" "front_end_instance" {
  count = 2
  ami=data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_and_http.id}"]
  subnet_id= count.index==0 ? "${aws_subnet.public_subnet[0].id}" : "${aws_subnet.public_subnet[1].id}"
  associate_public_ip_address = true
   tags = {
    Name = "Front Instance+ ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.com_mediasoft_europe_vpc_finance.id
}
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.com_mediasoft_europe_vpc_finance.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.custom_route_table.id
}
resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.public_subnet[1].id
  route_table_id = aws_route_table.custom_route_table.id
}
resource "aws_instance" "back_end_instance" {
  count = 2
  ami=data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_and_http.id}"]
  subnet_id= count.index==0 ? "${aws_subnet.private_subnet[0].id}" : "${aws_subnet.private_subnet[1].id }"
  tags = {
    Name = "backend Instance+ ${count.index + 1}"
  }
}
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-gateway-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "custom_route_table1" {
  vpc_id = aws_vpc.com_mediasoft_europe_vpc_finance.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.custom_route_table1.id
}
resource "aws_route_table_association" "private_assoc2" {
  subnet_id      = aws_subnet.private_subnet[1].id
  route_table_id = aws_route_table.custom_route_table1.id
}


