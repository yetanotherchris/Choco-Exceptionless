$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

if ((Test-IisInstalled) -eq $False)
{
    throw "IIS is not installed, please install it before continuing."
}

$ErrorActionPreference = 'Stop';
$packageName = "Exceptionless";
$appPoolName = "Exceptionless";
$websiteName = "Exceptionless";

$version = "3.1.1822";
$url = "https://github.com/exceptionless/Exceptionless/releases/download/v3.1.0/Exceptionless.$version.zip"
$unzipDir = "$toolsDir\Exceptionless.$version"

# Parse command line arguments 
# (This function is required because of the context Chocolatey runs in)
$arguments = @{}
$arguments["mongoDataDir"] = "$env:ChocolateyInstall\lib\mongodb\tools";
$arguments["websitePort"] = 80;
$arguments["websiteDomain"] = "localhost";
Parse-Parameters($arguments);

$websitePort = $arguments["websitePort"];
$websiteDomain = $arguments["websiteDomain"];

# Install
Configure-ElasticSearch
Unzip-Exceptionless $url $unzipDir
Update-ExceptionlessConfigs $unzipDir $websiteDomain $websitePort
Remove-ExceptionlessWebsite $appPoolName $websiteName
Add-ExceptionlessAppPool $appPoolName 
Add-ExceptionlessWebsite $unzipDir $websiteName $websiteDomain $websitePort

$websiteUrl = "http://$websiteDomain" +":"+ $websitePort

Write-Host "-----------------------------------------------------------------------------------------"
Write-Host "Installation complete."
Write-Host "You should now open a browser and signup at $websiteUrl" -ForegroundColor Green
Write-Host "(You may need to restart first)."
Write-Host "-----------------------------------------------------------------------------------------"