param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@('1.0'),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)
# Host Steps
# -------------------------------------------------------------------------$env:MONGO_VERSION = "3.6.5"
$env:MONGO_DOWNLOAD_URL  = "https://downloads.mongodb.org/win32/mongodb-win32-x86_64-2008plus-ssl-${env:MONGO_VERSION}-signed.msi"
$env:MONGO_DOWNLOAD_SHA256 = "f1e31e6ad01cd852d0a59dacf9b2ea34e64fb61977f9334338e9f16a468dec92"

$localFileName = 'mongo.msi'
if (-not (Test-Path $localFileName)) {
  Write-Host ('Downloading {0} ...' -f $env:MONGO_DOWNLOAD_URL);
  iwr -Uri $env:MONGO_DOWNLOAD_URL -OutFile $localFileName;
}

Write-Host ('Verifying sha256 ({0}) ...' -f $env:MONGO_DOWNLOAD_SHA256); 
if ((Get-FileHash mongo.msi -Algorithm sha256).Hash -ne $env:MONGO_DOWNLOAD_SHA256) { 
  Write-Host 'FAILED!'; 
  exit 1;
}; 

$installLocation = "$pwd\\mongodb"
if (-not(Test-Path $installLocation)) {
  Write-Host 'Installing ...';
  Start-Process msiexec -Wait -ArgumentList @('/i', $localFileName, '/quiet', '/qn', '/l ".\package.log"', "INSTALLLOCATION=$installLocation", 'ADDLOCAL=all', 'SHOULD_INSTALL_COMPASS=0' ); 
}

$prepareLocation = "$pwd\\prepare"
if (-not(Test-Path $prepareLocation)) {
  mkdir $prepareLocation;
}
copy C:\windows\system32\msvcp140.dll $prepareLocation -Force; 
copy C:\windows\system32\vccorlib140.dll $prepareLocation -Force; 
copy C:\windows\system32\vcruntime140.dll $prepareLocation -Force; 

# Clean Images
# -------------------------------------------------------------------------
$image = $LoginServer + "/${ImageName}"
Write-Host 'Clear existing images'
docker images --format '{{.Repository}}:{{.Tag}}' | ? { $_ -match $image } | % { docker rmi $_  }

# Build Steps
# -------------------------------------------------------------------------
Write-Host 'Building dockerfile'
docker build -t $image .

# Tag Steps
# -------------------------------------------------------------------------
Write-Host 'Tagging Image'
$Tags | % { docker tag $image "${image}:$_" }
