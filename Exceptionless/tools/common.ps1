Import-Module WebAdministration

function Parse-Parameters($arguments)
{
    $packageParameters = $env:chocolateyPackageParameters

    if ($packageParameters)
    {
          $match_pattern = '(?:\s*)(?<=[-|/])(?<name>\w*)[:|=]("((?<value>.*?)(?<!\\)")|(?<value>[\w]*))'

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

function Install-Dependencies()
{
    # Dependencies that can't be done via the nuspec file (or, I don't know how to)
    choco install dotnet4.6 -y #4.6.00081.20150925
    choco install jdk8 -y -params "both=true"
    choco install elasticsearch -version 1.7.2 -y

    # Install MongoDB - this is workaround for a bug in the mongodb package
    $oldSysDrive = $env:systemdrive
    $env:systemdrive = $mongoDataDir
    choco install mongodb -y
    $env:systemdrive = $oldSysDrive
}

function Configure-ElasticSearch()
{
    # Setup elasticsearch's config from exceptionless
    Write-Host "Configuring elasticsearch config file" -ForegroundColor Cyan
    $elasticSearchConfigPath = "$env:ChocolateyInstall\lib\elasticsearch\tools\elasticsearch-1.7.2\config\elasticsearch.yml"
    wget "https://raw.githubusercontent.com/exceptionless/Exceptionless/master/Libraries/elasticsearch.yml" -OutFile "$elasticSearchConfigPath"

    # Reload JAVA_HOME variable
    Write-Host "Configuring elasticsearch as a service" -ForegroundColor Cyan
    $env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")

    # Install elasticsearch as a service
    $elasticSearchPath = "$env:ChocolateyInstall\lib\elasticsearch\tools\elasticsearch-1.7.2\bin"
    cmd /c "set JAVA_HOME=$env:JAVA_HOME& $elasticSearchPath\service.bat install"
    cmd /c "$elasticSearchPath\service.bat start"

    # Set it to auto-start
    sc.exe config elasticsearch-service-x64 start=auto
}

function Unzip-Exceptionless([string] $url, [string] $unzipDir)
{
    # Download and unzip the Exceptionless.zip file
    $url64 = $url

    $packageArgs = @{
      packageName   = $packageName
      unzipLocation = $unzipDir
      fileType      = 'EXE' #only one of these: exe, msi, msu
      url           = $url
      url64bit      = $url64
    }

    Install-ChocolateyZipPackage $packageName $url $unzipDir
}

function Update-ExceptionlessConfigs([string] $unzipDir, [string] $websiteDomain, [int] $websitePort)
{
    # Update Exceptionless web.config
    Write-Host "Updating exceptionless web.config" -ForegroundColor Cyan
    $webConfig = "$unzipDir\wwwroot\web.config"
    $doc = (gc $webConfig) -as [xml]
    $doc.SelectSingleNode('//appSettings/add[@key="BaseURL"]/@value').'#text' = 'http://$websiteDomain/#'
    $doc.SelectSingleNode('//appSettings/add[@key="WebsiteMode"]/@value').'#text' = 'Production'
    $doc.Save($webConfig)

    # Update app.config.*.js
    $jsConfigFile = (dir "$unzipDir\wwwroot\app.config.*.js")[0]
    $jsConfigFilePath = $jsConfigFile.FullName

    Write-Host "Updating exceptionless $jsConfigFilePath" -ForegroundColor Cyan

    $content = [System.IO.File]::ReadAllText($jsConfigFilePath)
    $content = $content.Replace(".constant('BASE_URL', 'http://localhost:50000')",".constant('BASE_URL', 'http://$websiteDomain' +':'+ '$websitePort')")
    [System.IO.File]::WriteAllText($jsConfigFilePath, $content)
}

function Remove-Website([string] $appPoolName, [string] $websiteName)
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

function Add-AppPool([string] $appPoolName)
{
    Write-Host "  Adding app pool $appPoolName (v4, localservice)"

    New-WebAppPool -Name $appPoolName -Force | Out-Null
    Set-ItemProperty "IIS:\AppPools\$appPoolName" managedRuntimeVersion v4.0
    Set-ItemProperty "IIS:\AppPools\$appPoolName" managedPipelineMode Integrated
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel -value @{userName="";password="";identitytype=1}
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel.idleTimeout -value ([TimeSpan]::FromMinutes(0))
    Set-ItemProperty "IIS:\AppPools\$appPoolName" processModel.pingingEnabled -value true #disable for debuging
}

function Add-Website([string] $unzipDir, [string] $websiteName, [string] $websiteDomain, [int] $websitePort)
{
    Write-Host "  Adding website $websiteName (id:$websitePort, port: $websitePort, path: $websitePath)"

    $websitePath = "$unzipDir\wwwroot"
    New-Website -Name $websiteName -Id $websitePort -Port $websitePort -PhysicalPath $websitePath -ApplicationPool $appPoolName -Force  | Out-Null   
}