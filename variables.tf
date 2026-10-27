variable "hostname" {
  description = "Hostname of the web server."
  type        = string
  default     = "web-01"
}

variable "zone" {
  description = "UpCloud zone to deploy into (e.g. fi-hel1, de-fra1, uk-lon1, us-nyc1)."
  type        = string
  default     = "fi-hel1"
}

variable "plan" {
  description = "UpCloud server plan."
  type        = string
  default     = "1xCPU-1GB"
}

variable "os_template" {
  description = "Name or UUID of the OS template. Must be a cloud-init capable template."
  type        = string
  default     = "Ubuntu Server 24.04 LTS (Noble Numbat)"
}

variable "storage_size" {
  description = "Size of the system disk in GB."
  type        = number
  default     = 25
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key that is allowed to log in as root."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_ips" {
  description = "IPv4 addresses allowed to connect over SSH. Set this to your own public IP."
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_ips) > 0 && alltrue([for ip in var.ssh_allowed_ips : can(cidrhost("${ip}/32", 0))])
    error_message = "ssh_allowed_ips must contain at least one valid IPv4 address (e.g. \"203.0.113.10\")."
  }
}

variable "enable_upcloud_firewall" {
  description = "Manage the UpCloud firewall rules. Set to false on trial accounts, which cannot modify them (the firewall stays on with UpCloud's trial rules); ufw on the server is configured either way."
  type        = bool
  default     = false
}

variable "site_title" {
  description = "Title shown on the demo web page."
  type        = string
  default     = "Hello from UpCloud"
}
