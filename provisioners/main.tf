terraform { 
  /*cloud { 
    
    organization = "Fareedev" 

    workspaces { 
      name = "provisioners" 
    } 
  } */
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.64.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

/*data "aws_vpc" "terra_vpc" {
  id = "vpc-084b71d52d7e2e46c" 
}*/

resource  "aws_vpc"  "terra_vpc"  {
  cidr_block  = "10.0.0.0/16"

  tags  = {
    Name  = "aws_vpc.terra_vpc"
  }
}

resource "aws_subnet" "terra_pub_subnet" {
  vpc_id  = "vpc-0f8eaec87041b68d2"
  cidr_block  = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags  = {
    Name  = "terra_pub_subnet"
  }
}

resource  "aws_network_interface"  "terra_if"  {
  subnet_id = "subnet-06c1b57275cb79902"
  private_ips = ["10.0.1.10"]
}

resource "aws_security_group" "allow_web_ssh" {
  name        = "MyServer SG Group"
  description = "MyServer Security Group"
  vpc_id      = "vpc-0f8eaec87041b68d2"

  ingress =  [
  { description       = "SSH"
    from_port         = "22"
    to_port           = "22"
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = []
    prefix_list_ids   = []
    security_groups   = []
    self              = false
  },
  { description       = "HTTP"
    from_port         = "80"
    to_port           = "80"
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = []
    prefix_list_ids   = []
    security_groups   = []
    self              = false
  }
]
  egress  = [
  { description       = "Outbound Traffic"
    from_port         = 0
    to_port           = 0
    protocol           = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
    prefix_list_ids   = []
    security_groups   = []
    self              = false
  }
  ]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1j3mUUVOvDLyPC0kpC5grfNjjwRuZqIKfwIkr/aU730vjaiZlsB92PQRIPqWBbvQp9Q3tEgGK9m9BM7pmf7l1oYu4bsd/G1xuxdpQan8axKS/2MxnDFML3TE+bIyOkcjE4d3ESptZzUo448g15ACE4svQ44YzQdr99p5tLGFFDFKOhXhe6d7bFYy4R8Kqajbemf+htEQtoY908lU3HjEwcv8DRwMv/tmU2zqoJ7ck2ZvIcfXjKXPP9koxJJ9b4CqPLIAkvk78bzmnwAR6HjkII5VwIWcpQmUxJU3+JD1iFfKgkIpPzH3ER51MMJK5zxucXWUCePV56AhCIsi2TExCY32Wh3dKcYaWAO2xxFtOk5tOfJLUebN7DNJPCoYf5MHW+6Is/knNl4T6e2h3etGT7CSbXlAPqxLnvIHW63427Gro+Qx2bFTQ8GXCr2FFw6smYWXtPaaMYIHNzAjcW7qt/9iUQXO066OxpteyZm8B0E6OMtz5GlTlEC2pNrPQYPs= root@fareed-Devops"
}

data  "template_file"  "user_data"  {
    template = file("./userdata.yaml")
}
resource "aws_instance" "my_server" {
  ami = "ami-02c21308fed24a8ab"
  instance_type = "t2.micro"
  key_name  = "${aws_key_pair.deployer.key_name}"
  subnet_id = "subnet-06c1b57275cb79902"
  vpc_security_group_ids  = [aws_security_group.allow_web_ssh.id]
  user_data = data.template_file.user_data.rendered
  tags = {
    Name  = "MyServer"
  }
}

output  "public_ip"  {
  value = aws_instance.my_server.public_ip
}

output  "sg_id"  {
  value = aws_security_group.allow_web_ssh.id
}
