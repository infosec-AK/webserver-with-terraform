# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIA3ZDSTG5NQAO5KOBE"
  secret_key = "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"
}

resource "aws_instance" "testserver" {
  ami           = ami-053b0d53c279acc90
  instance_type = "t2.micro"
}
