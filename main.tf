resource "upcloud_server" "web" {
  hostname = var.hostname
  zone     = var.zone
  plan     = var.plan
  firewall = true

  # Metadata service is required for cloud-init to pick up user_data.
  metadata = true
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    hostname        = var.hostname
    site_title      = var.site_title
    ssh_allowed_ips = var.ssh_allowed_ips
  })

  template {
    storage = var.os_template
    size    = var.storage_size
  }

  network_interface {
    type = "public"
  }

  network_interface {
    type = "utility"
  }

  login {
    user            = "root"
    keys            = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
    create_password = false
  }

  labels = {
    managed-by = "terraform"
    role       = "web"
  }
}

# The UpCloud firewall is evaluated top to bottom and is not stateful, so
# return traffic for outbound connections (DNS, apt, NTP) is allowed explicitly.
resource "upcloud_firewall_rules" "web" {
  count     = var.enable_upcloud_firewall ? 1 : 0
  server_id = upcloud_server.web.id

  dynamic "firewall_rule" {
    for_each = var.ssh_allowed_ips
    content {
      comment                = "SSH from ${firewall_rule.value}"
      direction              = "in"
      action                 = "accept"
      family                 = "IPv4"
      protocol               = "tcp"
      source_address_start   = firewall_rule.value
      source_address_end     = firewall_rule.value
      destination_port_start = "22"
      destination_port_end   = "22"
    }
  }

  firewall_rule {
    comment                = "HTTP"
    direction              = "in"
    action                 = "accept"
    family                 = "IPv4"
    protocol               = "tcp"
    destination_port_start = "80"
    destination_port_end   = "80"
  }

  firewall_rule {
    comment                = "HTTPS"
    direction              = "in"
    action                 = "accept"
    family                 = "IPv4"
    protocol               = "tcp"
    destination_port_start = "443"
    destination_port_end   = "443"
  }

  firewall_rule {
    comment   = "ICMP echo (ping)"
    direction = "in"
    action    = "accept"
    family    = "IPv4"
    protocol  = "icmp"
    icmp_type = "8"
  }

  dynamic "firewall_rule" {
    for_each = ["94.237.127.9", "94.237.40.9"]
    content {
      comment              = "UpCloud DNS replies"
      direction            = "in"
      action               = "accept"
      family               = "IPv4"
      protocol             = "udp"
      source_address_start = firewall_rule.value
      source_address_end   = firewall_rule.value
      source_port_start    = "53"
      source_port_end      = "53"
    }
  }

  dynamic "firewall_rule" {
    for_each = ["80", "443"]
    content {
      comment           = "Replies from outbound TCP ${firewall_rule.value} (package updates)"
      direction         = "in"
      action            = "accept"
      family            = "IPv4"
      protocol          = "tcp"
      source_port_start = firewall_rule.value
      source_port_end   = firewall_rule.value
    }
  }

  firewall_rule {
    comment           = "NTP replies"
    direction         = "in"
    action            = "accept"
    family            = "IPv4"
    protocol          = "udp"
    source_port_start = "123"
    source_port_end   = "123"
  }

  firewall_rule {
    comment   = "Drop all other inbound IPv4"
    direction = "in"
    action    = "drop"
    family    = "IPv4"
  }

  firewall_rule {
    comment   = "Drop all inbound IPv6"
    direction = "in"
    action    = "drop"
    family    = "IPv6"
  }

  firewall_rule {
    comment   = "Allow all outbound"
    direction = "out"
    action    = "accept"
  }
}
