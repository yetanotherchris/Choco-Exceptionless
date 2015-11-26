$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

$appPoolName = "Exceptionless"
$websiteName = "Exceptionless"

Remove-Website $appPoolName $websiteName

# The dependencies are left intact.