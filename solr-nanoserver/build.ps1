param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Version = '7.3.1',

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@($Version),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)
# Host Steps
# -------------------------------------------------------------------------
$env:SOLR_VERSION = $Version
$env:SOLR_DOWNLOAD_URL  = "https://www.apache.org/dist/lucene/solr/${env:SOLR_VERSION}/solr-${env:SOLR_VERSION}.zip"
$env:SOLR_SHA1 = "551fa068b2ae464bafd47f668408f392eb8dec9c"

$localFileName = "solr-${env:SOLR_VERSION}.zip"
if (-not (Test-Path $localFileName)) {
  Write-Host ('Downloading {0} ...' -f $env:SOLR_DOWNLOAD_URL);
  iwr -Uri $env:SOLR_DOWNLOAD_URL -OutFile $localFileName;
}

Write-Host ('Verifying sha256 ({0}) ...' -f $env:SOLR_SHA1); 
if ((Get-FileHash $localFileName -Algorithm sha1).Hash -ne $env:SOLR_SHA1) { 
  Write-Host 'FAILED!'; 
  exit 1;
}; 

$installLocation = "$pwd\\solr-${env:SOLR_VERSION}"
if (-not(Test-Path $installLocation)) {
  Write-Host 'Expanding ...';
  Expand-Archive -Path $localFileName -OutputPath $pwd
}

# Clean Images
# -------------------------------------------------------------------------
$image = $LoginServer + "/${ImageName}"
Write-Host 'Clear existing images'
docker images --format '{{.Repository}}:{{.Tag}}' | ? { $_ -match $image } | % { docker rmi $_  }

# Build Steps
# -------------------------------------------------------------------------
Write-Host 'Building dockerfile'
docker build --build-arg SOLR_VERSION=$env:SOLR_VERSION -t $image .

# Tag Steps
# -------------------------------------------------------------------------
Write-Host 'Tagging Image'
$Tags | % { docker tag $image "${image}:$_" }
