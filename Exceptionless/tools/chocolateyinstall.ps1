$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

$ErrorActionPreference = 'Stop';
$packageName = "Exceptionless";
$appPoolName = "Exceptionless";
$websiteName = "Exceptionless";

$version = "3.1.1822";
$url = "https://github.com/exceptionless/Exceptionless/releases/download/v3.1.0/Exceptionless.$version.zip"
$unzipDir = "$toolsDir\Exceptionless.$version"

# Parse command line arguments
$arguments = @{}
$arguments["mongoDataDir"] = "$env:ChocolateyInstall\lib\mongodb\tools";
$arguments["websitePort"] = 80;
$arguments["websiteDomain"] = "localhost";
Parse-Parameters($arguments);

# Install
Install-Dependencies
Configure-ElasticSearch
Unzip-Exceptionless $url $unzipDir
Update-ExceptionlessConfigs $unzipDir $websiteDomain $websitePort
Remove-Website $appPoolName $websiteName
Add-AppPool $appPoolName 
Add-Website $unzipDir $websiteName $websiteDomain $websitePort

Write-Host "Done. You will probably need to restart now." -ForegroundColor Green