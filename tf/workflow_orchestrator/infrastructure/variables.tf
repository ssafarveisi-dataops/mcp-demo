variable "batch_instance_types" {
  type        = list(string)
  description = "EC2 instance types to use for AWS batch jobs"
  default     = ["c4.large", "c4.xlarge", "g4dn.xlarge", "g4dn.2xlarge"]
}

variable "batch_max_vcpu" {
  type        = string
  description = "maximum number of vCPUs to use on a batch job; defaults to 32"
  default     = 32
}

variable "batch_min_vcpu" {
  type        = string
  description = "minimum number of vCPUs to use on a batch job; defaults to 2"
  default     = 2
}

variable "bid_percentage" {
  type        = string
  description = "Spot bid percentage for AWS Batch compute"
  default     = "100"
}
