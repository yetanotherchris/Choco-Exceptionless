# Test for the pre-requisite of IIS
function Test-IisInstalled()
{
    $service = Get-WmiObject -Class Win32_Service -Filter "Name='w3svc'";
    if ($service)
    {
        write-host $service.Status
        if ($service.Status -eq "OK")
        {
            return $True;
        }
    }

    return $False;
}

if ((Test-IisInstalled) -eq $False)
{
    throw "IIS is not installed, please install it before continuing."
}

# Download urls and unzip locations
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

$ErrorActionPreference = 'Stop';
$packageName = "Exceptionless";
$appPoolName = "Exceptionless";
$websiteName = "Exceptionless";

$fullVersion = "3.2.2128";
$url = "https://github.com/exceptionless/Exceptionless/releases/download/v3.2.1/Exceptionless.$version.zip"
$unzipDir = "$toolsDir\Exceptionless.$version"

# Parse command line arguments - this function is required because of the context Chocolatey runs in
$arguments = @{}
$arguments["websitePort"] = 80;
$arguments["websiteDomain"] = "localhost";
Parse-Parameters($arguments);

$websitePort = $arguments["websitePort"];
$websiteDomain = $arguments["websiteDomain"];

# Install elasticsearch and the website
Configure-ElasticSearch
Unzip-Exceptionless $url $unzipDir
Update-ExceptionlessConfigs $unzipDir $websiteDomain $websitePort
Remove-ExceptionlessWebsite $appPoolName $websiteName
Add-ExceptionlessAppPool $appPoolName 
Add-ExceptionlessWebsite $unzipDir $websiteName $websiteDomain $websitePort

# Done
$websiteUrl = "http://$websiteDomain" +":"+ $websitePort

Write-Host "-----------------------------------------------------------------------------------------"
Write-Host "Installation complete."
Write-Host "You should now open a browser and signup at $websiteUrl" -ForegroundColor Green
Write-Host "(You may need to restart first)."
Write-Host "-----------------------------------------------------------------------------------------"