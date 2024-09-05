variable "ami" {
  description = "AMI to be used for EC2 instances"
  default = "ami-0e04bcbe83a83792e"
}

variable "key_name" {
  description = "EC2 Key Pair"
  default = "test"
}