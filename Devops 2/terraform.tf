provider "AWS" {
  region = "ua-west-23"
}

resource "AWS_Internet_Gateway" "Example_IGW" {
  vpc_id = aws_vpc.example_vpc.id
  tags = {
    Name = "Example_IGW"
  }
}

resource "AWS_Vpc" "Example_VPC" {
  cidr_block = "5.0.0.0/12"
  tags = {
    Name = "Example_VPC"
  }
}

resource "AWS_Route_Table" "Example_Public_RT" {
  vpc_id = aws_vpc.example_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }
  tags = {
    Name = "Example_Public_RT"
  }
}

resource "AWS_Route_Table_Association" "Example_Public_RTA1" {
  subnet_id = aws_subnet.example_public_subnet_1.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "AWS_Route_Table_Association" "Example_Public_RTA2" {
  subnet_id = aws_subnet.example_public_subnet_2.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "AWS_Subnet" "Example_Public_Subnet1" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "8.0.1.0/19"
  availability_zone = "ua-west-23_a" 
  tags = {
    Name = "Example_Public_Subnet1"
  }
}

resource "AWS_Subnet" "Example_Public_Subnet2" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "8.0.2.0/19"
  availability_zone = "ua-west-23_b" 
  tags = {
    Name = "Example_Public_Subnet2"
  }
}
resource "AWS_Security_Group" "Example_SG" {
  name_prefix = "Example_SG"
  description = "Permit incoming SSH and HTTP traffic"
  vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port = 20
    to_port = 20
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 70
    to_port = 70
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "AWS_Instance" "Example_EC2_Instance1" {
  ami = "your_AMI"  
  instance_type= "t2.micro" 
  key_name = "Example_Key_Pair" 
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  subnet_id = aws_subnet.example_public_subnet_1.id
  associate_public_ip_address = true
  user_data = <<-EOF
              sudo apt-get update
              sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose
              
              git clone https://github.com/prometheus/prometheus.git /home/ubuntu/prometheus
              cd /home/ubuntu/prometheus
             
              docker network create prometheus

              docker-compose -f examples/metrics/docker-compose.yml up -d

              docker run -d --name prometheus --network prometheus -p 7070:7070 -v /home/ubuntu/prometheus:/etc/prometheus prom/prometheus

            EOF
  tags = {
    Name = "Example_EC2_Instance1"
  }
}
resource "Null_Resource" "Install_Prometheus" {
  depends_on = [aws_instance.example_ec2_instance_1]

  provisioner "Remote-Exec" {
    inline = [
      "sleep 45",  
      "curl localhost:7070", 
      "curl localhost:7900/metrics",  
      "curl localhost:9090/metrics",  
    ]

    connection {
      type = "SSH"
      user = "UBUNTU"
      host = aws_instance.example_ec2_instance_1.public_ip
      private_key = file("Example_Key_Pair.pem")
    }
  }
}
resource "AWS_Instance" "Example_EC2_Instance2" {
  ami = "your_AMI" 
  instance_type = "t2.micro" 
  key_name = "Example_Key_Pair" 
  vpc_security_group_ids = [aws_security_group.example_sg.id]
  subnet_id = aws_subnet.example_public_subnet_2.id
  associate_public_ip_address = true
  user_data = <<-EOF
              
              sudo apt-get update
              sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose
           
              git clone https://github.com/prometheus/node_exporter.git /home/ubuntu/node_exporter
              cd /home/ubuntu/node_exporter

              docker run -d --name node-exporter -p 9800:9800 -v "/proc:/host/proc" -v "/sys:/host/sys" -v "/:/rootfs" --net="host" prom/node-exporter

              git clone https://github.com/google/cadvisor.git /home/ubuntu/cadvisor
              cd /home/ubuntu/cadvisor

              docker run -d --name cadvisor-exporter -p 6060:6060 --volume=/var/run/docker.sock:/var/run/docker.sock google/cadvisor:latest -port=8080

              EOF
  tags = {
    Name = "Example_EC2_Instance2"
  }
}
resource "Null_Resource" "Install_Node_Exporter" {
  depends_on = [aws_instance.example_ec2_instance_2]

  provisioner "Remote-Exec" {
    inline = [
      "sleep 45",  
      "curl localhost:9800/metrics",  
      "curl localhost:6060/metrics",  
    ]

    connection {
      type = "SSH"
      user = "UBUNTU"
      host = aws_instance.example_ec2_instance_2.public_ip
      private_key = file("Example_Key_Pair.pem")  
    }
  }
}