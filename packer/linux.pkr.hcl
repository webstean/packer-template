source "azure-arm" "autogenerated_1" {
  azure_tags = merge (
    local.tags_default,
    {
      ## Monitoring
      ## 24-7         : 24x7 monitoring
      ## 8-5          : business hours
      ## not-monitored: not monitored
      monitoring = "not-monitored"

      ## Data Goverance
      ## Public Data
      data_public = "no"
      ## Personal Identifiable Data
      data_PII = "no"
      ## Personal Health Information
      data_PHI = "no"
    },
  )
  lifecycle {
    ignore_changes = [tags]
  }

  client_id                         = "f5b6a5cf-fbdf-4a9f-b3b8-3c2cd00225a4"
  client_secret                     = "0e760437-bf34-4aad-9f8d-870be799c55d"
  image_offer                       = "UbuntuServer"
  image_publisher                   = "Canonical"
  image_sku                         = "16.04-LTS"
  location                          = "East US"
  managed_image_name                = "myPackerImage"
  managed_image_resource_group_name = "myResourceGroup"
  os_type                           = "Linux"
  subscription_id                   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
  tenant_id                         = "72f988bf-86f1-41af-91ab-2d7cd011db47"
  vm_size                           = "Standard_DS2_v2"
}

build {
  sources = ["source.azure-arm.autogenerated_1"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = ["apt-get update", "apt-get upgrade -y", "apt-get -y install nginx", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
    inline_shebang  = "/bin/sh -x"
  }
}