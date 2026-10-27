# Credentials are read from the environment, never from source control:
#   export UPCLOUD_TOKEN="..."                      # API token (recommended)
#   # or
#   export UPCLOUD_USERNAME="..." UPCLOUD_PASSWORD="..."
provider "upcloud" {}
