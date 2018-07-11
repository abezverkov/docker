param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Version ='1.8.0',

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@(),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)
# Host Steps
# -------------------------------------------------------------------------
# For some reason, this wont download from inside the servercore:1803 container.
$env:JAVA_OJDKBUILD_VERSION = '1.8.0.171-1'
$env:JAVA_OJDKBUILD_ZIP = 'java-1.8.0-openjdk-1.8.0.171-1.b10.ojdkbuild.windows.x86_64.zip'
$env:JAVA_OJDKBUILD_SHA256 = '35104f658ed51d1b24cf6f0f6d1d21524d7640d3e3e7b64d8d7ac86cbfbc2ab9'

$localFileName = $env:JAVA_OJDKBUILD_ZIP
if (-not (Test-Path $localFileName)) {

  $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12';
  [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols;
  $url = ('https://github.com/ojdkbuild/ojdkbuild/releases/download/{0}/{1}' -f $env:JAVA_OJDKBUILD_VERSION, $env:JAVA_OJDKBUILD_ZIP);
  Write-Host ('Downloading {0} ...' -f $url);
  iwr -Uri $url -OutFile $localFileName;
}

Write-Host ('Verifying sha256 ({0}) ...' -f $env:JAVA_OJDKBUILD_SHA256); 
if ((Get-FileHash $localFileName -Algorithm sha256).Hash -ne $env:JAVA_OJDKBUILD_SHA256) { 
  Write-Host 'FAILED!'; 
  exit 1;
};

# Clean Images
# -------------------------------------------------------------------------
$image = $LoginServer + "/${ImageName}"
Write-Host 'Clear existing images'
docker images --format '{{.Repository}}:{{.Tag}}' | ? { $_ -match $image } | % { docker rmi $_  }

# Build Steps
# -------------------------------------------------------------------------
Write-Host "Building dockerfile: $image"
docker build --build-arg MONGO_VERSION=$Version -t $image .

# Tag Steps
# -------------------------------------------------------------------------
Write-Host 'Tagging Image'
$Tags += $Version
$Tags | % { docker tag $image "${image}:$_" }
