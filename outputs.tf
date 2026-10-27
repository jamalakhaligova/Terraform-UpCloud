output "server_id" {
  description = "UUID of the UpCloud server."
  value       = upcloud_server.web.id
}

output "public_ip" {
  description = "Public IPv4 address of the web server."
  value       = upcloud_server.web.network_interface[0].ip_address
}

output "website_url" {
  description = "URL of the demo website."
  value       = "http://${upcloud_server.web.network_interface[0].ip_address}"
}
