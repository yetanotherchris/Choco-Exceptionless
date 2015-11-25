Write-Host "Removing Exceptionless IIS site" -ForegroundColor Cyan

$appPoolName = "Exceptionless"
$websiteName = "Exceptionless"
$websitePort = 80

Import-Module WebAdministration

function Test-WebAppPool($Name) {
    return Test-Path "IIS:\AppPools\$Name"
}

function Test-Website($Name) {
    return Test-Path "IIS:\Sites\$Name"
}

#=================================================================
# Remove existing app pool and site
#=================================================================
if (Test-WebAppPool $appPoolName)
{
    Write-Host "  Removing app pool $appPoolName"
    Remove-WebAppPool -Name $appPoolName -WarningAction Ignore
}

if (Test-Website $websiteName)
{
    Write-Host "  Removing website $websiteName"
    Remove-Website -Name $websiteName -WarningAction Ignore
}

# The dependencies are left intact.