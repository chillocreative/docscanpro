# One-shot tool: render the splash logo as a 1024x1024 launcher icon.
#
# Writes:
#   assets/icon/app_icon.png            (legacy / iOS-style icon)
#   assets/icon/app_icon_foreground.png (Android adaptive foreground)
#
# We render via System.Drawing instead of `dart run tools/gen_icon.dart`
# because Dart's native-asset hook runner trips on the space in
# 'D:\TEMPORARY FOLDER\flutter' when objective_c (a transitive iOS-only
# package) is in the dep tree. PowerShell + GDI+ has no such problem.

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$projRoot = Split-Path -Parent $root
$outDir = Join-Path $projRoot 'assets\icon'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$size = 1024
$brandBlue = [System.Drawing.Color]::FromArgb(0xFF, 0x25, 0x63, 0xEB)
$white = [System.Drawing.Color]::White
$transparent = [System.Drawing.Color]::Transparent

function New-RoundedRectPath {
    param(
        [float]$x, [float]$y,
        [float]$w, [float]$h,
        [float]$r
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-CardAndGlyph {
    param(
        [System.Drawing.Graphics]$g
    )
    # White rounded card — matches splash _LogoCard. 640x640 fits inside
    # the Android adaptive-icon safe zone (66% = 676px).
    $cardSize = 640
    $cardRadius = 140
    $cardLeft = ($size - $cardSize) / 2
    $cardTop = ($size - $cardSize) / 2

    $cardPath = New-RoundedRectPath -x $cardLeft -y $cardTop `
        -w $cardSize -h $cardSize -r $cardRadius
    $whiteBrush = New-Object System.Drawing.SolidBrush($white)
    $g.FillPath($whiteBrush, $cardPath)
    $whiteBrush.Dispose()
    $cardPath.Dispose()

    # Stylised scan-document glyph: a page outline with a folded
    # top-right corner, plus a horizontal scan beam through the middle.
    $cx = $size / 2
    $cy = $size / 2
    $pageW = 360
    $pageH = 460
    $stroke = 18
    $cornerCut = 90

    $left = $cx - $pageW / 2
    $top = $cy - $pageH / 2
    $right = $left + $pageW
    $bottom = $top + $pageH
    $cutX = $right - $cornerCut
    $cutY = $top + $cornerCut

    $bluePen = New-Object System.Drawing.Pen($brandBlue, $stroke)
    $bluePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $bluePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $bluePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Page outline (top → fold → right → bottom → left → back to start).
    $pagePath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pagePath.AddLine($left, $top, $cutX, $top)
    $pagePath.AddLine($cutX, $top, $right, $cutY)
    $pagePath.AddLine($right, $cutY, $right, $bottom)
    $pagePath.AddLine($right, $bottom, $left, $bottom)
    $pagePath.AddLine($left, $bottom, $left, $top)
    $g.DrawPath($bluePen, $pagePath)
    $pagePath.Dispose()

    # Folded-corner inner crease — the little "L" that suggests depth.
    $foldPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $foldPath.AddLine($cutX, $top, $cutX, $cutY)
    $foldPath.AddLine($cutX, $cutY, $right, $cutY)
    $g.DrawPath($bluePen, $foldPath)
    $foldPath.Dispose()
    $bluePen.Dispose()

    # Horizontal scan beam, slightly wider than the page, with rounded
    # ends. Drawn as a filled rounded rectangle.
    $beamThickness = 24
    $beamPad = 60
    $beamLeft = $left - $beamPad
    $beamWidth = ($right + $beamPad) - $beamLeft
    $beamPath = New-RoundedRectPath `
        -x $beamLeft `
        -y ($cy - $beamThickness / 2) `
        -w $beamWidth `
        -h $beamThickness `
        -r ($beamThickness / 2)
    $blueBrush = New-Object System.Drawing.SolidBrush($brandBlue)
    $g.FillPath($blueBrush, $beamPath)
    $blueBrush.Dispose()
    $beamPath.Dispose()
}

function Render-Icon {
    param(
        [string]$path,
        [bool]$transparentBg
    )
    $bmp = New-Object System.Drawing.Bitmap($size, $size, `
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = `
        [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = `
        [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = `
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    if ($transparentBg) {
        $g.Clear($transparent)
    } else {
        $g.Clear($brandBlue)
    }

    Draw-CardAndGlyph -g $g
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Wrote $path"
}

Render-Icon -path (Join-Path $outDir 'app_icon.png') -transparentBg $false
Render-Icon -path (Join-Path $outDir 'app_icon_foreground.png') `
    -transparentBg $true
