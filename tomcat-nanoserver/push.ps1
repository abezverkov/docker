param (
    [Parameter(Mandatory=$false)]
    [string] $ImageName = (Get-Item .).Name,

    [Parameter(Mandatory=$false)]
    [string[]] $Tags =@('1.0'),

    [Parameter(Mandatory=$false)]
    [string] $LoginServer = 'abezverkov'
)

$image = $LoginServer + "/${ImageName}"

# Push Image
# -------------------------------------------------------------------------
Write-Host 'Pushing Image to ContainerRegistry'
docker push $image 
