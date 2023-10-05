## Install Script for common organisation tooling

## Chocolatey Install
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


## Tooling List
$tools = @(
            "vscode", "gh", "git", "github-desktop", "azure-cli", "nodejs-lts"
        )

## Install Tools using Chocolatey from the list above
foreach ($tool in $tools) {
    choco install -y $tool
    Write-Host "Installed the tool: $tool"
}
