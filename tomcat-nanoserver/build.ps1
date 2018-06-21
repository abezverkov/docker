param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Version='8.5.31',

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@($Version),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)
# Host Steps
# -------------------------------------------------------------------------
$env:TOMCAT_VERSION = $Version
$env:TOMCAT_DOWNLOAD_URL  = "http://supergsego.com/apache/tomcat/tomcat-8/v${env:TOMCAT_VERSION}/bin/apache-tomcat-${env:TOMCAT_VERSION}-windows-x64.zip"
$env:TOMCAT_SHA512 = "6dc31ae8d60cb87c8e4519d4676a0ff7dfdaf2b0aa88d8110d4725a7bbb6b94dd8da3502c574941958603921bfb2f124d5a580b890eb96ace0767f895e3d23f9"

$localFileName = "apache-tomcat-${env:TOMCAT_VERSION}.zip"
if (-not (Test-Path $localFileName)) {
  Write-Host ('Downloading {0} ...' -f $env:TOMCAT_DOWNLOAD_URL);
  iwr -Uri $env:TOMCAT_DOWNLOAD_URL -OutFile $localFileName;
}

Write-Host ('Verifying sha512 ({0}) ...' -f $env:TOMCAT_SHA512); 
if ((Get-FileHash $localFileName -Algorithm sha512).Hash -ne $env:TOMCAT_SHA512) { 
  Write-Host 'FAILED!'; 
  exit 1;
}; 

$installLocation = "$pwd\\apache-tomcat-${env:TOMCAT_VERSION}"
if (-not(Test-Path $installLocation)) {
  Write-Host 'Expanding ...';
  Expand-Archive -Path $localFileName -DestinationPath $installLocation
}

# Clean Images
# -------------------------------------------------------------------------
$image = $LoginServer + "/${ImageName}"
Write-Host 'Clear existing images'
docker images --format '{{.Repository}}:{{.Tag}}' | ? { $_ -match $image } | % { docker rmi $_  }

# Build Steps
# -------------------------------------------------------------------------
Write-Host 'Building dockerfile'
docker build --build-arg TOMCAT_VERSION=$Version -t $image .

# Tag Steps
# -------------------------------------------------------------------------
Write-Host 'Tagging Image'
$Tags | % { docker tag $image "${image}:$_" }
