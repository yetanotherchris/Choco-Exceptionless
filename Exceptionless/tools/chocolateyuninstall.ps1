$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. "$toolsDir\common.ps1"

Delete-ElasticSearchService

$appPoolName = "Exceptionless"
$websiteName = "Exceptionless"
Remove-ExceptionlessWebsite $appPoolName $websiteName