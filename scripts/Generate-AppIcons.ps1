param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [string]$AssetsDirectory = (Join-Path $PSScriptRoot '..\ThreeFingerDragOnWindows\Assets')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "Icon source not found: $Source"
}

if (-not (Test-Path -LiteralPath $AssetsDirectory -PathType Container)) {
    throw "Assets directory not found: $AssetsDirectory"
}

$magick = (Get-Command magick -ErrorAction Stop).Source
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$assetsPath = (Resolve-Path -LiteralPath $AssetsDirectory).Path
$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("DragLock-icons-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

function Invoke-Magick {
    param([string[]]$Arguments)

    & $magick @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ImageMagick failed with exit code $LASTEXITCODE."
    }
}

function New-IconCanvas {
    param(
        [string]$OutputName,
        [int]$CanvasWidth,
        [int]$CanvasHeight,
        [int]$IconBox
    )

    $outputPath = Join-Path $assetsPath $OutputName
    Invoke-Magick @(
        $sourcePath,
        '-trim', '+repage',
        '-resize', "${IconBox}x${IconBox}",
        '-gravity', 'center',
        '-background', 'none',
        '-extent', "${CanvasWidth}x${CanvasHeight}",
        '-strip',
        $outputPath
    )
}

function New-MonochromeBadge {
    param(
        [string]$OutputName,
        [int]$CanvasSize
    )

    $iconBox = [Math]::Max(1, [Math]::Round($CanvasSize * 0.9))
    $maskPath = Join-Path $temporaryDirectory ("mask-$CanvasSize.png")
    $outputPath = Join-Path $assetsPath $OutputName

    Invoke-Magick @(
        $sourcePath,
        '-trim', '+repage',
        '-alpha', 'extract',
        '-resize', "${iconBox}x${iconBox}",
        '-gravity', 'center',
        '-background', 'black',
        '-extent', "${CanvasSize}x${CanvasSize}",
        $maskPath
    )

    Invoke-Magick @(
        '-size', "${CanvasSize}x${CanvasSize}",
        'xc:white',
        $maskPath,
        '-alpha', 'off',
        '-compose', 'CopyOpacity',
        '-composite',
        '-strip',
        $outputPath
    )
}

try {
    $scales = @(
        @{ Suffix = '100'; Factor = 1.00 },
        @{ Suffix = '125'; Factor = 1.25 },
        @{ Suffix = '150'; Factor = 1.50 },
        @{ Suffix = '200'; Factor = 2.00 },
        @{ Suffix = '400'; Factor = 4.00 }
    )

    foreach ($scale in $scales) {
        $factor = [double]$scale.Factor
        $suffix = $scale.Suffix

        $badgeSize = [Math]::Round(24 * $factor)
        New-MonochromeBadge "BadgeLogo.scale-$suffix.png" $badgeSize

        $logo44Size = [Math]::Round(44 * $factor)
        New-IconCanvas "logo-44.scale-$suffix.png" $logo44Size $logo44Size ([Math]::Round($logo44Size * 0.9))

        $logo150Size = [Math]::Round(150 * $factor)
        New-IconCanvas "logo-150.scale-$suffix.png" $logo150Size $logo150Size ([Math]::Round($logo150Size / 3))

        $logo512Size = [Math]::Round(50 * $factor)
        New-IconCanvas "logo-512.scale-$suffix.png" $logo512Size $logo512Size ([Math]::Round($logo512Size * 0.9))

        $smallTileSize = [Math]::Round(71 * $factor)
        New-IconCanvas "SmallTile.scale-$suffix.png" $smallTileSize $smallTileSize ([Math]::Round($smallTileSize / 2))

        $largeTileSize = [Math]::Round(310 * $factor)
        New-IconCanvas "LargeTile.scale-$suffix.png" $largeTileSize $largeTileSize ([Math]::Round($largeTileSize / 3))

        $wideWidth = [Math]::Round(310 * $factor)
        $wideHeight = [Math]::Round(150 * $factor)
        New-IconCanvas "WideTile.scale-$suffix.png" $wideWidth $wideHeight ([Math]::Round($wideHeight / 3))

        $splashWidth = [Math]::Round(620 * $factor)
        $splashHeight = [Math]::Round(300 * $factor)
        New-IconCanvas "SplashScreen.scale-$suffix.png" $splashWidth $splashHeight ([Math]::Round($splashHeight / 3))
    }

    foreach ($size in @(16, 24, 32, 48, 256)) {
        $iconBox = [Math]::Round($size * 0.9)
        New-IconCanvas "logo-44.targetsize-$size.png" $size $size $iconBox
        New-IconCanvas "logo-44.targetsize-${size}_altform-lightunplated.png" $size $size $iconBox
        New-IconCanvas "logo-44.targetsize-${size}_altform-unplated.png" $size $size $iconBox
        New-IconCanvas "logo-44.altform-lightunplated_targetsize-$size.png" $size $size $iconBox
        New-IconCanvas "logo-44.altform-unplated_targetsize-$size.png" $size $size $iconBox
    }

    New-IconCanvas 'icon-52.png' 52 52 47

    $icoMaster = Join-Path $temporaryDirectory 'icon-master-256.png'
    Invoke-Magick @(
        $sourcePath,
        '-trim', '+repage',
        '-resize', '246x246',
        '-gravity', 'center',
        '-background', 'none',
        '-extent', '256x256',
        '-strip',
        $icoMaster
    )
    Invoke-Magick @(
        $icoMaster,
        '-define', 'icon:auto-resize=256,128,96,72,64,48,32,24,16',
        (Join-Path $assetsPath 'icon.ico')
    )
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        $resolvedTemporaryDirectory = [System.IO.Path]::GetFullPath($temporaryDirectory)
        $resolvedTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if (-not $resolvedTemporaryDirectory.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
            -not ([System.IO.Path]::GetFileName($resolvedTemporaryDirectory)).StartsWith('DragLock-icons-', [System.StringComparison]::Ordinal)) {
            throw "Refusing to remove unexpected temporary directory: $resolvedTemporaryDirectory"
        }
        Remove-Item -LiteralPath $resolvedTemporaryDirectory -Recurse -Force
    }
}
