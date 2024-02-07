source "azure-arm" "avd" {
  # WinRM Communicator

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"

  # Service Principal Authentication

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Source Image

  os_type         = "Windows"
  image_publisher = var.source_image_publisher
  image_offer     = var.source_image_offer
  image_sku       = var.source_image_sku
  image_version   = var.source_image_version

  # Destination Image

  managed_image_resource_group_name = var.artifacts_resource_group
  managed_image_name                = "${var.source_image_sku}-${var.source_image_version}"

  # Packer Computing Resources

  build_resource_group_name = var.build_resource_group
  vm_size                   = "Standard_D4ds_v4"
}


build {
  source "azure-arm.avd" {}

  # Install Chocolatey: https://chocolatey.org/install#individual
  provisioner "powershell" {
    inline = ["Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"]
  }

  # Install Chocolatey: base
  provisioner "powershell" {
        "inlineCommand": [
          "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
          "choco install -y git",
          "choco install -y azure-cli",
          "choco install -y vscode",
          "$vscode_extension_dir=\"C:/temp/extensions\"; New-Item $vscode_extension_dir -ItemType Directory -Force; [Environment]::SetEnvironmentVariable(\"VSCODE_EXTENSIONS\", $vscode_extension_dir, \"Machine\"); $env:VSCODE_EXTENSIONS=$vscode_extension_dir; Start-Process -FilePath \"C:/Program Files/Microsoft VS Code/bin/code.cmd\"  -ArgumentList \" --install-extension github.copilot\"  -Wait -NoNewWindow"
      ]  
  }

  # Install Chocolatey: java
  provisioner "powershell" {
        "inlineCommand": [
           "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
            "choco install -y git",
            "choco install -y azure-cli",
            "choco install -y vscode",
            "choco install -y openjdk11",
            "choco install -y maven",
            "$vscode_extension_dir=\"C:/temp/extensions\"; New-Item $vscode_extension_dir -ItemType Directory -Force; [Environment]::SetEnvironmentVariable(\"VSCODE_EXTENSIONS\", $vscode_extension_dir, \"Machine\"); $env:VSCODE_EXTENSIONS=$vscode_extension_dir; Start-Process -FilePath \"C:/Program Files/Microsoft VS Code/bin/code.cmd\"  -ArgumentList \" --install-extension vscjava.vscode-java-pack\"  -Wait -NoNewWindow"
      ]

  # Install Chocolatey: dotnet
  provisioner "powershell" {
        "inlineCommand": [
          "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
          "choco install -y git",
          "choco install -y azure-cli",
          "choco install -y vscode",
          "choco install -y dotnet-7.0-sdk",
          "$ProgressPreference = 'SilentlyContinue';$vsInstallerName = 'vs_enterprise.exe';$vsInstallerPath = Join-Path -Path $env:TEMP -ChildPath $vsInstallerName;(new-object net.webclient).DownloadFile('https://aka.ms/vs/17/release/vs_enterprise.exe', $vsInstallerPath); Start-Process -FilePath $vsInstallerPath -ArgumentList '--add', 'Microsoft.VisualStudio.Workload.CoreEditor', '--add', 'Microsoft.VisualStudio.Workload.Azure', '--add', 'Microsoft.VisualStudio.Workload.NetWeb', '--add', 'Microsoft.VisualStudio.Workload.Node', '--add', 'Microsoft.VisualStudio.Workload.Python', '--add', 'Microsoft.VisualStudio.Workload.ManagedDesktop', '--includeRecommended', '--installWhileDownloading', '--quiet', '--norestart', '--force', '--wait', '--nocache' -NoNewWindow -Wait"
        ]
  }

  # Install Chocolatey: data
  provisioner "powershell" {
        "inlineCommand": [
          "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
          "choco install -y git",
          "choco install -y azure-cli",
          "choco install -y vscode",
          "choco install -y python3",
          "$vscode_extension_dir=\"C:/temp/extensions\"; New-Item $vscode_extension_dir -ItemType Directory -Force; [Environment]::SetEnvironmentVariable(\"VSCODE_EXTENSIONS\", $vscode_extension_dir, \"Machine\"); $env:VSCODE_EXTENSIONS=$vscode_extension_dir; Start-Process -FilePath \"C:/Program Files/Microsoft VS Code/bin/code.cmd\"  -ArgumentList \" --install-extension ms-python.python\"  -Wait -NoNewWindow; Start-Process -FilePath \"C:/Program Files/Microsoft VS Code/bin/code.cmd\"  -ArgumentList \" --install-extension ms-toolsai.jupyter\"  -Wait -NoNewWindow"
        ]
  }

  # Install Chocolatey packages config file
  provisioner "file" {
    source      = "./choco-packages.config.json"
    destination = "D:/choco-packages.config"
  }

  # Install Winget packages config file
  provisioner "file" {
    source      = "./winget-packages.config.yml"
    destination = "D:/packages.yml"
  }

  provisioner "powershell" {
    inline = ["choco install --confirm D:/choco-packages.config"]
    # See https://docs.chocolatey.org/en-us/choco/commands/install#exit-codes
    valid_exit_codes = [0, 3010]
  }

  provisioner "windows-restart" {}

  # Azure PowerShell Modules
  provisioner "powershell" {
    script = "./install-azure-powershell.ps1"
  }

  # Generalize image using Sysprep
  # See https://www.packer.io/docs/builders/azure/arm#windows
  # See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/build-image-with-packer#define-packer-template
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
