variable "policy" {
  description = "Complete tailnet policy in JSON or HuJSON."
  type        = string
}

variable "magic_dns" {
  type    = bool
  default = true
}

variable "device_tags" {
  description = "Device node IDs mapped to their complete tag sets."
  type        = map(set(string))
  default     = {}

  validation {
    condition = alltrue([
      for id, tags in var.device_tags : trimspace(id) != "" && length(tags) > 0 && alltrue([
        for tag in tags : can(regex("^tag:[a-zA-Z][a-zA-Z0-9-]*$", tag))
      ])
    ])
    error_message = "Device IDs must be nonempty and tags must use tag:<name>."
  }
}
