param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Version ='3.6.5',

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@(),

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
Write-Host "Building dockerfile: $image"
docker build --build-arg MONGO_VERSION=$Version -t $image .

# Tag Steps
# -------------------------------------------------------------------------
Write-Host 'Tagging Image'
$Tags += $Version
$Tags | % { docker tag $image "${image}:$_" }
