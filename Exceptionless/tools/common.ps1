# This module requires Powershell 4+ which is picked up by the choco Powershell dependency
Import-Module WebAdministration

function Parse-Parameters($arguments)
{
    $packageParameters = $env:chocolateyPackageParameters
    Write-Host "Package parameters: $packageParameters"

    if ($packageParameters)
    {
          $match_pattern = "(?:\s*)(?<=[-|/])(?<name>\w*)[:|=]('((?<value>.*?)(?<!\\)')|(?<value>[\w]*))"

          if ($packageParameters -match $match_pattern )
          {
              $results = $packageParameters | Select-String $match_pattern -AllMatches
              $results.matches | % {

                $key = $_.Groups["name"].Value.Trim();
                $value = $_.Groups["value"].Value.Trim();

                write-host "$key : $value";

                if ($arguments.ContainsKey($key))
                {
                    $arguments[$key] = $value;
                }
            }
          }
    }
}

function Configure-ElasticSearch()
{
    # Setup elasticsearch's config from exceptionless
    Write-Host "Configuring elasticsearch config file" -ForegroundColor Cyan
    $elasticSearchConfigPath = "$env:ChocolateyInstall\lib\exceptionless-elasticsearch\tools\elasticsearch-1.7.5\config\elasticsearch.yml";
    wget "https://raw.githubusercontent.com/exceptionless/Exceptionless/master/Libraries/elasticsearch.yml" -OutFile "$elasticSearchConfigPath";

    # Reload JAVA_HOME variable
    Write-Host "Configuring elasticsearch as a service" -ForegroundColor Cyan
    $env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine");

    # Install elasticsearch as a service
    $elasticSearchPath = "$env:ChocolateyInstall\lib\exceptionless-elasticsearch\tools\elasticsearch-1.7.5\bin";
    cmd /c "set JAVA_HOME=$env:JAVA_HOME& $elasticSearchPath\service.bat install"
    cmd /c "$elasticSearchPath\service.bat start"

    # Set it to auto-start
    sc.exe config elasticsearch-service-x64 start=auto
    sc.exe start elasticsearch-service-x64
}

function Delete-ElasticSearchService()
{
    sc.exe stop elasticsearch-service-x64
    sc.exe delete elasticsearch-service-x64    
}

function Unzip-Exceptionless([string] $url, [string] $unzipDir)
{
    # Download and unzip the Exceptionless.zip file
    $url64 = $url

    Install-ChocolateyZipPackage $packageName $url $unzipDir
}

function Update-ExceptionlessConfigs([string] $unzipDir, [string] $websiteDomain, [int] $websitePort)
{
    $domainAndPort = $websiteDomain +":"+ $websitePort;

    # Update Exceptionless web.config
    Write-Host "Updating exceptionless web.config" -ForegroundColor Cyan
    $webConfig = "$unzipDir\wwwroot\web.config"
    $doc = (gc $webConfig) -as [xml]
    $doc.SelectSingleNode('//appSettings/add[@key="BaseURL"]/@value')."#text" = "http://$domainAndPort/#"
    $doc.SelectSingleNode('//appSettings/add[@key="WebsiteMode"]/@value')."#text" = "Production"
    $doc.Save($webConfig)

    # Update app.config.*.js
    Write-Host "Updating exceptionless $jsConfigFilePath" -ForegroundColor Cyan
    $jsConfigFile = (dir "$unzipDir\wwwroot\app.config.*.js")[0]
    $jsConfigFilePath = $jsConfigFile.FullName

    $content = [System.IO.File]::ReadAllText($jsConfigFilePath)
    $content = $content.Replace(".constant('BASE_URL', 'http://localhost:50000')",".constant('BASE_URL', 'http://$domainAndPort')")
    [System.IO.File]::WriteAllText($jsConfigFilePath, $content)
}

function Remove-ExceptionlessWebsite([string] $appPoolName, [string] $websiteName)
{
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
}

function Test-WebAppPool($Name) {
    return Test-Path "IIS:\AppPools\$Name"
}

function Test-Website($Name) {
    return Test-Path "IIS:\Sites\$Name"
}

function Add-ExceptionlessAppPool([string] $appPoolName)
{
    Write-Host "  Adding app pool $appPoolName (v4, localservice)"

    New-WebAppPool -Name $appPoolName -Force | Out-Null
    Set-ItemProperty "IIS:\AppPools\$appPoolName" managedRuntimeVersion v4.0
    Set-ItemProperty "IIS:\AppPools\$appPoolName" managedPipelineMode Integrated
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel -value @{userName="";password="";identitytype=1}
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel.idleTimeout -value ([TimeSpan]::FromMinutes(0))
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel.pingingEnabled -value true #disable for debuging
}

function Add-ExceptionlessWebsite([string] $unzipDir, [string] $websiteName, [string] $websiteDomain, [int] $websitePort)
{
    $websitePath = "$unzipDir\wwwroot"

    Write-Host "  Adding website $websiteName (id:$websitePort, port: $websitePort, path: $websitePath)"
    New-Website -Name $websiteName -Id $websitePort -Port $websitePort -PhysicalPath $websitePath -ApplicationPool $appPoolName -Force  | Out-Null   
}