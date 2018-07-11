param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Version='8.5.32',

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@($Version),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)
# Host Steps
# -------------------------------------------------------------------------
#

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
