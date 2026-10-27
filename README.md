# Terraform UpCloud Web Server

Provisions an UpCloud VM with Terraform, installs Nginx with cloud-init, serves a static
HTML page, and configures the server with the UpCloud firewall.

## Prerequisites

- Terraform >= 1.5
- An UpCloud account with API access enabled
- An SSH key pair (`ssh-keygen -t rsa`)
- Copy the public half of the key pair to your cloud server (`ssh-copy-id -i ~/.ssh/id_rsa.pub user@server`)

## Usage

1. Export credentials. They are only read from the environment and never written to files:

   ```bash
   export UPCLOUD_TOKEN="your-api-token"
   # or: export UPCLOUD_USERNAME="api-user" UPCLOUD_PASSWORD="api-password"
   ```

2. Create your variables file and set `ssh_allowed_ips` to your own public IP
   (`curl -4 ifconfig.me`):

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Deploy:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Open the `website_url` output in a browser. cloud-init needs a minute or two after boot
   to install Nginx, so retry if the page doesn't load right away.

5. Tear down when done:

   ```bash
   terraform destroy
   ```

## Variables

| Name                  | Default                                  | Description                         |
|-----------------------|------------------------------------------|-------------------------------------|
| `hostname`            | `web-01`                                 | Server hostname                     |
| `zone`                | `fi-hel1`                                | UpCloud zone                        |
| `plan`                | `1xCPU-1GB`                              | Server plan                         |
| `os_template`         | `Ubuntu Server 24.04 LTS (Noble Numbat)` | Cloud-init capable OS template      |
| `storage_size`        | `25`                                     | Disk size in GB                     |
| `ssh_public_key_path` | `~/.ssh/id_ed25519.pub`                  | Public key installed for `root`     |
| `ssh_allowed_ips`     | *(required)*                             | IPv4 addresses allowed to SSH       |
| `enable_upcloud_firewall` | `true`                               | Manage UpCloud firewall rules (`false` on trial accounts) |
| `site_title`          | `Hello from UpCloud`                     | Title of the demo page              |

## Outputs

`server_id`, `public_ip`, `website_url`

## Security

- **Firewall:** inbound traffic is limited to SSH (only from `ssh_allowed_ips`), HTTP, HTTPS,
  and ping. Everything else is dropped. The UpCloud firewall is stateless, so the rules also
  let in replies to the server's own DNS, package-update (TCP 80/443) and NTP traffic.
- **Host firewall:** cloud-init also enables `ufw` with the same policy. UpCloud trial
  accounts cannot modify or disable the network firewall (`TRIAL_FIREWALL` 403 error). On a
  trial account, set `enable_upcloud_firewall = false`: the firewall stays on with UpCloud's
  trial rules, Terraform leaves the rules alone, and `ufw` enforces this project's policy.
- **SSH:** key-only login. The server is created without a root password, and cloud-init turns
  off password and keyboard-interactive authentication.
- **Credentials:** the provider reads API credentials from environment variables. `*.tfvars`,
  state files and `.terraform/` are git-ignored, because state can contain sensitive data.
  For team use, store state in a remote backend such as UpCloud Managed Object Storage
  (S3-compatible).
- **Updates:** cloud-init upgrades all packages on first boot and installs `unattended-upgrades`.

## CI

[.github/workflows/terraform.yml](.github/workflows/terraform.yml) runs `terraform fmt -check`,
`terraform init -backend=false` and `terraform validate` on every push to `main` and on every
pull request. It needs no credentials.
