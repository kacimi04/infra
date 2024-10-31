variable "vpc_cird_block" {
    description = "cidr block for vpc"
    type = string
    default= "10.0.0.0/16"
  
}
variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["euw3-az1","euw3-az2"]
}
variable "vpc_subnet_cidr_block" {
  type =list(string)
  description = "values of subnet cidr block"
  default = [ "10.0.0.0/18","10.0.64.0/18","10.0.128.0/18","10.0.192.0/18" ]
  
}

