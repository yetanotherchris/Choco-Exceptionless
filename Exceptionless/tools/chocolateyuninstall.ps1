$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

$appPoolName = "Exceptionless"
$websiteName = "Exceptionless"

Remove-ExceptionlessWebsite $appPoolName $websiteName

# The dependencies are left intact.