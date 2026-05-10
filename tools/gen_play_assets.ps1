# Generates the Play Console listing artwork:
#   play_store/feature_graphic_1024x500.png
#   play_store/phone_01_hero_1080x1920.png
#   play_store/phone_02_camera_1080x1920.png
#   play_store/phone_03_ocr_1080x1920.png
#   play_store/phone_04_library_1080x1920.png
#   play_store/tablet_1080x1920.png            (7" tablet, 9:16)
#   play_store/tablet10_1440x2560.png          (10" tablet, 9:16)
#
# All renders in pure System.Drawing so it runs anywhere with a Windows
# JRE-style toolchain, no Flutter / browser screenshot dance required.

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$projRoot = Split-Path -Parent $root
$outDir = Join-Path $projRoot 'play_store'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# ---------- palette (global so script blocks invoked via & can see them) ----------
$global:brandBlue    = [System.Drawing.Color]::FromArgb(0xFF,0x25,0x63,0xEB)
$global:brandDark    = [System.Drawing.Color]::FromArgb(0xFF,0x1D,0x4E,0xD8)
$global:brandTint    = [System.Drawing.Color]::FromArgb(0xFF,0xEF,0xF6,0xFF)
$global:brandLine    = [System.Drawing.Color]::FromArgb(0xFF,0xBF,0xDB,0xFE)
$global:ink          = [System.Drawing.Color]::FromArgb(0xFF,0x0F,0x17,0x2A)
$global:body         = [System.Drawing.Color]::FromArgb(0xFF,0x37,0x41,0x51)
$global:muted        = [System.Drawing.Color]::FromArgb(0xFF,0x6B,0x72,0x80)
$global:line         = [System.Drawing.Color]::FromArgb(0xFF,0xE5,0xE7,0xEB)
$global:bg           = [System.Drawing.Color]::FromArgb(0xFF,0xFA,0xFA,0xFA)
$global:pdfRed       = [System.Drawing.Color]::FromArgb(0xFF,0xEF,0x44,0x44)
$global:pdfRedTint   = [System.Drawing.Color]::FromArgb(0xFF,0xFE,0xE2,0xE2)
$global:jpgBlueTint  = [System.Drawing.Color]::FromArgb(0xFF,0xDB,0xEA,0xFE)
$global:amber        = [System.Drawing.Color]::FromArgb(0xFF,0xF5,0x9E,0x0B)
$global:amberTint    = [System.Drawing.Color]::FromArgb(0xFF,0xFE,0xF3,0xC7)
$global:amberInk     = [System.Drawing.Color]::FromArgb(0xFF,0x92,0x40,0x0E)
$global:green        = [System.Drawing.Color]::FromArgb(0xFF,0x22,0xC5,0x5E)
$global:premiumStart = [System.Drawing.Color]::FromArgb(0xFF,0xFF,0x95,0x00)
$global:premiumEnd   = [System.Drawing.Color]::FromArgb(0xFF,0xFF,0x6B,0x00)
$global:white        = [System.Drawing.Color]::White
$global:black        = [System.Drawing.Color]::Black
$global:shadow       = [System.Drawing.Color]::FromArgb(0x40,0x00,0x00,0x00)
# Local aliases so the rest of the script can read them as $brandBlue etc.
$brandBlue=$global:brandBlue;$brandDark=$global:brandDark;$brandTint=$global:brandTint
$brandLine=$global:brandLine;$ink=$global:ink;$body=$global:body;$muted=$global:muted
$line=$global:line;$bg=$global:bg;$pdfRed=$global:pdfRed;$pdfRedTint=$global:pdfRedTint
$jpgBlueTint=$global:jpgBlueTint;$amber=$global:amber;$amberTint=$global:amberTint
$amberInk=$global:amberInk;$green=$global:green;$premiumStart=$global:premiumStart
$premiumEnd=$global:premiumEnd;$white=$global:white;$black=$global:black;$shadow=$global:shadow

# ---------- helpers ----------
function New-RoundedRectPath {
    param([float]$x,[float]$y,[float]$w,[float]$h,[float]$r)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    if ($d -gt $w) { $d = $w }
    if ($d -gt $h) { $d = $h }
    if ($d -le 0) {
        $p.AddRectangle((New-Object System.Drawing.RectangleF($x,$y,$w,$h)))
        return $p
    }
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-Canvas {
    param([int]$w,[int]$h,[System.Drawing.Color]$bg=$null)
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    if ($bg -ne $null) { $g.Clear($bg) }
    return @($bmp, $g)
}

function Save-PNG { param($bmp,$g,$path); $g.Dispose(); $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); Write-Host "Wrote $path" }

function Get-Font {
    param([string]$family='Segoe UI',[float]$size,[System.Drawing.FontStyle]$style=[System.Drawing.FontStyle]::Regular)
    return New-Object System.Drawing.Font($family,$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-Text {
    param($g,[string]$text,$font,[System.Drawing.Color]$color,[float]$x,[float]$y)
    $b = New-Object System.Drawing.SolidBrush($color)
    $g.DrawString($text, $font, $b, $x, $y)
    $b.Dispose()
}

function Draw-TextCenter {
    param($g,[string]$text,$font,[System.Drawing.Color]$color,[float]$cx,[float]$cy)
    $sz = $g.MeasureString($text, $font)
    Draw-Text $g $text $font $color ($cx - $sz.Width/2) ($cy - $sz.Height/2)
}

function Fill-RoundRect {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r,[System.Drawing.Color]$color)
    $p = New-RoundedRectPath $x $y $w $h $r
    $b = New-Object System.Drawing.SolidBrush($color)
    $g.FillPath($b, $p)
    $b.Dispose(); $p.Dispose()
}

function Stroke-RoundRect {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r,[System.Drawing.Color]$color,[float]$thick=1)
    $p = New-RoundedRectPath $x $y $w $h $r
    $pen = New-Object System.Drawing.Pen($color, $thick)
    $g.DrawPath($pen, $p)
    $pen.Dispose(); $p.Dispose()
}

function Fill-Rect {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[System.Drawing.Color]$color)
    $b = New-Object System.Drawing.SolidBrush($color)
    $g.FillRectangle($b, $x, $y, $w, $h)
    $b.Dispose()
}

# Brand-blue gradient strip background.
function Fill-BrandGradient {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,$c1=$null,$c2=$null,[bool]$horizontal=$false)
    if ($null -eq $c1) { $c1 = $global:brandBlue }
    if ($null -eq $c2) { $c2 = $global:brandDark }
    $p1 = New-Object System.Drawing.PointF($x, $y)
    $p2 = if ($horizontal) {
        New-Object System.Drawing.PointF(($x + $w), $y)
    } else {
        New-Object System.Drawing.PointF($x, ($y + $h))
    }
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($p1, $p2, [System.Drawing.Color]$c1, [System.Drawing.Color]$c2)
    $g.FillRectangle($br, $x, $y, $w, $h)
    $br.Dispose()
}

# DocScan-style logo card: white rounded square + brand-blue
# scan-document glyph (page outline + folded corner + scan beam).
function Draw-LogoCard {
    param($g,[float]$x,[float]$y,[float]$size,[System.Drawing.Color]$cardColor=$global:white)
    $r = $size * 0.22
    Fill-RoundRect $g $x $y $size $size $r $cardColor
    $cx = $x + $size / 2
    $cy = $y + $size / 2
    $pageW = $size * 0.36
    $pageH = $size * 0.46
    $stroke = $size * 0.024
    $cut = $size * 0.09
    $left = $cx - $pageW / 2; $top = $cy - $pageH / 2
    $right = $left + $pageW; $bottom = $top + $pageH
    $cutX = $right - $cut; $cutY = $top + $cut
    $pen = New-Object System.Drawing.Pen($global:brandBlue, $stroke)
    $pen.LineJoin = 'Round'
    $pen.StartCap = 'Round'
    $pen.EndCap = 'Round'
    $page = New-Object System.Drawing.Drawing2D.GraphicsPath
    $page.AddLine($left,$top,$cutX,$top)
    $page.AddLine($cutX,$top,$right,$cutY)
    $page.AddLine($right,$cutY,$right,$bottom)
    $page.AddLine($right,$bottom,$left,$bottom)
    $page.AddLine($left,$bottom,$left,$top)
    $g.DrawPath($pen, $page); $page.Dispose()
    $fold = New-Object System.Drawing.Drawing2D.GraphicsPath
    $fold.AddLine($cutX,$top,$cutX,$cutY)
    $fold.AddLine($cutX,$cutY,$right,$cutY)
    $g.DrawPath($pen, $fold); $fold.Dispose()
    $pen.Dispose()
    # scan beam through middle
    $beamThk = $size * 0.032
    $beamPad = $size * 0.06
    Fill-RoundRect $g ($left - $beamPad) ($cy - $beamThk/2) ($pageW + $beamPad*2) $beamThk ($beamThk/2) $global:brandBlue
}

# Tiny inline logo + wordmark used at the bottom of phone screens.
function Draw-FootBrand {
    param($g,[float]$x,[float]$y,[float]$logoSize,[float]$fontSize,[System.Drawing.Color]$fg)
    # Draw a brand-tinted card behind the glyph so the footer logo
    # reads against the white footer band.
    Draw-LogoCard $g $x $y $logoSize $global:brandTint
    $fontTitle = Get-Font 'Segoe UI' $fontSize ([System.Drawing.FontStyle]::Bold)
    $fontTag   = Get-Font 'Segoe UI' ($fontSize*0.55) ([System.Drawing.FontStyle]::Regular)
    $titleH = $g.MeasureString('Doc Scanner Pro', $fontTitle).Height
    $tagH = $g.MeasureString('Scan. Save. Share.', $fontTag).Height
    $totalH = $titleH + $tagH + 4
    $textY = $y + ($logoSize - $totalH) / 2
    Draw-Text $g 'Doc Scanner Pro' $fontTitle $fg ($x + $logoSize + 24) $textY
    Draw-Text $g 'Scan. Save. Share.' $fontTag $global:muted ($x + $logoSize + 24) ($textY + $titleH + 4)
    $fontTitle.Dispose(); $fontTag.Dispose()
}

# Pick the largest font size so [text] fits inside [maxW] horizontally.
function Get-FittedFont {
    param($g,[string]$text,[float]$maxW,[float]$startSize,[System.Drawing.FontStyle]$style=[System.Drawing.FontStyle]::Regular,[float]$minSize=12,[string]$family='Segoe UI')
    $size = $startSize
    while ($size -ge $minSize) {
        $f = Get-Font $family $size $style
        $tw = $g.MeasureString($text, $f).Width
        if ($tw -le $maxW) { return $f }
        $f.Dispose()
        $size -= 2
    }
    return Get-Font $family $minSize $style
}

# Caption banner used at the top of phone screens. Both lines are
# auto-shrunk so they don't bleed past the canvas edges.
function Draw-CaptionBand {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[string]$line1,[string]$line2='')
    Fill-BrandGradient $g $x $y $w $h
    $maxW = $w * 0.90
    $f1 = Get-FittedFont $g $line1 $maxW ($h * 0.30) ([System.Drawing.FontStyle]::Bold)
    if ($line2) {
        $f2 = Get-FittedFont $g $line2 $maxW ($h * 0.16) ([System.Drawing.FontStyle]::Regular)
        Draw-TextCenter $g $line1 $f1 $global:white ($x + $w/2) ($y + $h * 0.42)
        Draw-TextCenter $g $line2 $f2 ([System.Drawing.Color]::FromArgb(0xE0,0xFF,0xFF,0xFF)) ($x + $w/2) ($y + $h * 0.74)
        $f2.Dispose()
    } else {
        Draw-TextCenter $g $line1 $f1 $global:white ($x + $w/2) ($y + $h/2)
    }
    $f1.Dispose()
}

# Drop shadow behind a rounded rectangle.
function Draw-DropShadow {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r,[float]$blur=10,[float]$dy=8)
    for ($i = $blur; $i -ge 1; $i--) {
        $alpha = [int](48 * (1 - $i / $blur))
        $c = [System.Drawing.Color]::FromArgb($alpha, 0, 0, 0)
        Stroke-RoundRect $g ($x - $i) ($y - $i + $dy) ($w + $i*2) ($h + $i*2) ($r + $i) $c 1
    }
}

# Mock library doc card (used in screen 4 and tablet shots).
function Draw-DocCardListRow {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[string]$title,[bool]$isPdf,[string]$meta)
    Fill-RoundRect $g $x $y $w $h 22 $white
    Stroke-RoundRect $g $x $y $w $h 22 $line 1.5
    $badgeSize = $h * 0.7
    $badgeX = $x + ($h - $badgeSize) / 2 + $h * 0.05
    $badgeY = $y + ($h - $badgeSize) / 2
    $badgeBg = if ($isPdf) { $pdfRedTint } else { $jpgBlueTint }
    Fill-RoundRect $g $badgeX $badgeY $badgeSize $badgeSize 16 $badgeBg
    $iconColor = if ($isPdf) { $pdfRed } else { $brandBlue }
    $iconLabel = if ($isPdf) { 'PDF' } else { 'JPG' }
    $iconFont = Get-Font 'Segoe UI' ($badgeSize * 0.36) ([System.Drawing.FontStyle]::Bold)
    Draw-TextCenter $g $iconLabel $iconFont $iconColor ($badgeX + $badgeSize/2) ($badgeY + $badgeSize/2)
    $iconFont.Dispose()

    $textX = $badgeX + $badgeSize + $h * 0.25
    $titleFont = Get-Font 'Segoe UI' ($h * 0.22) ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g $title $titleFont $ink $textX ($y + $h * 0.18)
    $titleFont.Dispose()

    $chipW = $h * 0.55; $chipH = $h * 0.28
    $chipY = $y + $h * 0.55
    Fill-RoundRect $g $textX $chipY $chipW $chipH ($chipH/2) ([System.Drawing.Color]::FromArgb(0xFF,0xF3,0xF4,0xF6))
    $chipFont = Get-Font 'Segoe UI' ($chipH * 0.55) ([System.Drawing.FontStyle]::Bold)
    $chipLabel = if ($isPdf) { 'PDF' } else { 'JPG' }
    Draw-TextCenter $g $chipLabel $chipFont $muted ($textX + $chipW/2) ($chipY + $chipH/2)
    $chipFont.Dispose()
    $metaFont = Get-Font 'Segoe UI' ($h * 0.14) ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g $meta $metaFont $muted ($textX + $chipW + 16) ($chipY + $chipH/2 - $h*0.10)
    $metaFont.Dispose()
}

# Mock bottom-nav bar (Home / Camera / Settings).
function Draw-BottomNav {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h)
    Fill-Rect $g $x $y $w $h $white
    Fill-Rect $g $x $y $w 1 $line
    $tabs = @(
        @{label='Home'; sel=$false},
        @{label='Camera'; sel=$true},
        @{label='Settings'; sel=$false}
    )
    $tabW = $w / $tabs.Count
    $f = Get-Font 'Segoe UI' ($h * 0.18) ([System.Drawing.FontStyle]::Bold)
    foreach ($i in 0..($tabs.Count-1)) {
        $tab = $tabs[$i]
        $cx = $x + $tabW * $i + $tabW/2
        if ($tab.sel) {
            $btnSize = $h * 0.78
            Fill-RoundRect $g ($cx - $btnSize/2) ($y + ($h - $btnSize)/2) $btnSize $btnSize ($btnSize/2) $brandBlue
            $cf = Get-Font 'Segoe UI Symbol' ($btnSize * 0.38) ([System.Drawing.FontStyle]::Regular)
            Draw-TextCenter $g 'CAM' (Get-Font 'Segoe UI' ($btnSize*0.22) ([System.Drawing.FontStyle]::Bold)) $white $cx ($y + $h/2)
            $cf.Dispose()
        } else {
            Draw-TextCenter $g $tab.label $f $muted $cx ($y + $h/2)
        }
    }
    $f.Dispose()
}

# Mock status bar with carrier / clock at top of phone screens.
function Draw-StatusBar {
    param($g,[float]$x,[float]$y,[float]$w,[float]$h,[System.Drawing.Color]$bg=$white,[System.Drawing.Color]$fg=$ink)
    Fill-Rect $g $x $y $w $h $bg
    $f = Get-Font 'Segoe UI' ($h * 0.42) ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g '9:41' $f $fg ($x + $w * 0.07) ($y + $h * 0.22)
    Draw-Text $g 'LTE   100%' $f $fg ($x + $w * 0.74) ($y + $h * 0.22)
    $f.Dispose()
}

# ---------- screen renderers ----------

function Render-FeatureGraphic {
    $w = 1024; $h = 500
    $cv = New-Canvas $w $h $brandBlue
    $bmp = $cv[0]; $g = $cv[1]
    Fill-BrandGradient $g 0 0 $w $h
    # decorative glow
    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow.AddEllipse(700, -150, 600, 600)
    $bb = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
    $bb.CenterColor = [System.Drawing.Color]::FromArgb(0x60,0xFF,0xFF,0xFF)
    $bb.SurroundColors = @([System.Drawing.Color]::FromArgb(0x00,0xFF,0xFF,0xFF))
    $g.FillPath($bb, $glow); $bb.Dispose(); $glow.Dispose()

    # text block, sized to leave room for the icon on the right
    $textW = 600
    $titleFont = Get-FittedFont $g 'Doc Scanner Pro' $textW 64 ([System.Drawing.FontStyle]::Bold)
    $tagFont   = Get-Font 'Segoe UI' 26 ([System.Drawing.FontStyle]::Regular)
    $featFont  = Get-Font 'Segoe UI' 22 ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g 'Doc Scanner Pro' $titleFont $white 64 90
    Draw-Text $g 'Scan. Save. Share.' $tagFont ([System.Drawing.Color]::FromArgb(0xE0,0xFF,0xFF,0xFF)) 64 180
    $bullets = @(
        'Live edge detection',
        'On-device OCR  -  5 scripts',
        'Clean text-on-white PDF / JPG',
        'Lifetime Premium  -  $4.99 once'
    )
    $by = 250
    foreach ($b in $bullets) {
        Fill-RoundRect $g 64 ($by + 6) 14 14 7 $white
        Draw-Text $g $b $featFont ([System.Drawing.Color]::FromArgb(0xF0,0xFF,0xFF,0xFF)) 92 $by
        $by += 38
    }
    $titleFont.Dispose(); $tagFont.Dispose(); $featFont.Dispose()

    # right side: large logo card
    Draw-LogoCard $g 690 90 300 $white
    Save-PNG $bmp $g (Join-Path $outDir 'feature_graphic_1024x500.png')
}

# A common framework: brand band caption + screen content + footer.
function Render-PhoneCaption {
    param([string]$file,[string]$line1,[string]$line2,[scriptblock]$drawScreen,[int]$w=1080,[int]$h=1920,[int]$captionH=300,[int]$footerH=170)
    $cv = New-Canvas $w $h $bg
    $bmp = $cv[0]; $g = $cv[1]
    Draw-CaptionBand $g 0 0 $w $captionH $line1 $line2
    & $drawScreen $g 0 $captionH $w ($h - $captionH - $footerH)
    # footer
    Fill-Rect $g 0 ($h - $footerH) $w $footerH $white
    Fill-Rect $g 0 ($h - $footerH) $w 1 $line
    Draw-FootBrand $g 50 ($h - $footerH + ($footerH - 90)/2) 90 36 $ink
    Save-PNG $bmp $g (Join-Path $outDir $file)
}

# ---------- screen content blocks ----------

# Hero panel: large logo + tagline + 4 pill features
$drawHero = {
    param($g,$x,$y,$w,$h)
    Fill-Rect $g $x $y $w $h $bg
    $cx = $x + $w/2
    $logoSize = 360
    Draw-LogoCard $g ($cx - $logoSize/2) ($y + 40) $logoSize $brandTint
    $tFont = Get-Font 'Segoe UI' 64 ([System.Drawing.FontStyle]::Bold)
    Draw-TextCenter $g 'Doc Scanner Pro' $tFont $ink $cx ($y + $logoSize + 110)
    $sFont = Get-Font 'Segoe UI' 30 ([System.Drawing.FontStyle]::Regular)
    Draw-TextCenter $g 'A real document scanner in your pocket' $sFont $body $cx ($y + $logoSize + 195)
    $tFont.Dispose(); $sFont.Dispose()
    $features = @(
        @{title='Live edge detection'; icon='AUTO'},
        @{title='On-device OCR (5 scripts)'; icon='OCR'},
        @{title='Clean text-on-white PDF / JPG'; icon='PDF'},
        @{title='$4.99 lifetime Premium'; icon='PRO'}
    )
    $py = $y + $logoSize + 280
    foreach ($f in $features) {
        $pillX = $cx - 380
        $pillW = 760
        $pillH = 92
        Fill-RoundRect $g $pillX $py $pillW $pillH 22 $white
        Stroke-RoundRect $g $pillX $py $pillW $pillH 22 $line 1.4
        # icon block
        Fill-RoundRect $g ($pillX + 14) ($py + 14) ($pillH - 28) ($pillH - 28) 16 $brandTint
        $iFont = Get-Font 'Segoe UI' 22 ([System.Drawing.FontStyle]::Bold)
        Draw-TextCenter $g $f.icon $iFont $brandDark ($pillX + $pillH/2 + 0) ($py + $pillH/2)
        $iFont.Dispose()
        $tf = Get-Font 'Segoe UI' 28 ([System.Drawing.FontStyle]::Bold)
        Draw-Text $g $f.title $tf $ink ($pillX + $pillH + 14) ($py + ($pillH - 36)/2)
        $tf.Dispose()
        $py += 110
    }
}

# Camera viewfinder mock with green quad
$drawCamera = {
    param($g,$x,$y,$w,$h)
    Fill-Rect $g $x $y $w $h $black
    # status bar inside
    Draw-StatusBar $g $x $y $w 64 $black $white
    $titleFont = Get-Font 'Segoe UI' 36 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g 'Scan Document' $titleFont $white ($x + 50) ($y + 96)
    $titleFont.Dispose()

    # auto-detect pill
    $pillX = $x + 60; $pillY = $y + 200
    Fill-RoundRect $g $pillX $pillY 320 64 32 ([System.Drawing.Color]::FromArgb(0xB0,0,0,0))
    Fill-RoundRect $g ($pillX + 24) ($pillY + 24) 16 16 8 $green
    $pillFont = Get-Font 'Segoe UI' 22 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g 'Ready - hold steady' $pillFont $white ($pillX + 56) ($pillY + 18)
    $pillFont.Dispose()

    # Big "preview" dark rounded card with a tilted document outline
    $pvX = $x + 50; $pvY = $y + 300; $pvW = $w - 100; $pvH = $h - 580
    $shadowPath = New-RoundedRectPath ($pvX - 4) ($pvY + 8) ($pvW + 8) ($pvH + 8) 36
    $sb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0x60,0,0,0))
    $g.FillPath($sb, $shadowPath); $sb.Dispose(); $shadowPath.Dispose()
    Fill-RoundRect $g $pvX $pvY $pvW $pvH 36 ([System.Drawing.Color]::FromArgb(0xFF,0x1F,0x29,0x37))

    # gridlines hint
    $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0x30,0xFF,0xFF,0xFF), 1)
    for ($i = 1; $i -lt 4; $i++) {
        $g.DrawLine($gridPen, $pvX + $pvW*$i/4, $pvY + 12, $pvX + $pvW*$i/4, $pvY + $pvH - 12)
        $g.DrawLine($gridPen, $pvX + 12, $pvY + $pvH*$i/4, $pvX + $pvW - 12, $pvY + $pvH*$i/4)
    }
    $gridPen.Dispose()

    # Document quad (slightly tilted) drawn as filled white-ish polygon
    $cx = $pvX + $pvW/2; $cy = $pvY + $pvH/2
    $halfW = $pvW * 0.34; $halfH = $pvH * 0.36
    $offset = 24
    $tl = New-Object System.Drawing.PointF(($cx - $halfW + $offset), ($cy - $halfH))
    $tr = New-Object System.Drawing.PointF(($cx + $halfW + $offset/2), ($cy - $halfH + 30))
    $br = New-Object System.Drawing.PointF(($cx + $halfW - 10), ($cy + $halfH))
    $bl = New-Object System.Drawing.PointF(($cx - $halfW - 30), ($cy + $halfH - 30))
    $quad = @($tl, $tr, $br, $bl)
    $paperBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0xFF,0xF5,0xF5,0xF5))
    $g.FillPolygon($paperBrush, $quad)
    $paperBrush.Dispose()
    # fake text lines on the paper
    $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0x40,0x9C,0xA3,0xAF), 4)
    for ($i = 0; $i -lt 7; $i++) {
        $r = 0.16 + $i * 0.10
        $ax = [float](((1 - $r) * $tl.X + $r * $bl.X) + 24)
        $ay = [float]((1 - $r) * $tl.Y + $r * $bl.Y)
        $bx = [float](((1 - $r) * $tr.X + $r * $br.X) - 24)
        $by = [float]((1 - $r) * $tr.Y + $r * $br.Y)
        $g.DrawLine($linePen, $ax, $ay, $bx, $by)
    }
    $linePen.Dispose()

    # green outline + corner pips
    $greenPen = New-Object System.Drawing.Pen($green, 6)
    $g.DrawPolygon($greenPen, $quad)
    $greenPen.Dispose()
    $pipBrush = New-Object System.Drawing.SolidBrush($green)
    $pipBorder = New-Object System.Drawing.Pen($white, 4)
    foreach ($p in $quad) {
        $g.FillEllipse($pipBrush, $p.X - 18, $p.Y - 18, 36, 36)
        $g.DrawEllipse($pipBorder, $p.X - 18, $p.Y - 18, 36, 36)
    }
    $pipBrush.Dispose(); $pipBorder.Dispose()

    # bottom controls strip
    $cy2 = $y + $h - 220
    Fill-Rect $g ($x) $cy2 $w 220 ([System.Drawing.Color]::FromArgb(0xFF,0x0F,0x14,0x1C))
    # shutter circle
    $sCx = $x + $w/2; $sCy = $cy2 + 110
    $sR = 70
    $shutterOuter = New-Object System.Drawing.Pen($white, 8)
    $g.DrawEllipse($shutterOuter, $sCx - $sR, $sCy - $sR, $sR*2, $sR*2)
    $shutterOuter.Dispose()
    Fill-RoundRect $g ($sCx - $sR + 18) ($sCy - $sR + 18) (($sR - 18)*2) (($sR - 18)*2) ($sR - 18) $white
}

# OCR results page mock
$drawOcr = {
    param($g,$x,$y,$w,$h)
    Fill-Rect $g $x $y $w $h $bg
    Draw-StatusBar $g $x $y $w 64 $bg $ink
    # app bar
    $abY = $y + 64; $abH = 100
    Fill-Rect $g $x $abY $w $abH $white
    Fill-Rect $g $x ($abY + $abH) $w 1 $line
    $abFont = Get-Font 'Segoe UI' 32 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g 'Recognised text' $abFont $ink ($x + 60) ($abY + ($abH - 38)/2)
    $abFont.Dispose()
    # copy icon hint
    Fill-RoundRect $g ($x + $w - 110) ($abY + 24) 50 50 12 $brandTint
    $cp = Get-Font 'Segoe UI Symbol' 22 ([System.Drawing.FontStyle]::Bold)
    Draw-TextCenter $g 'Copy' (Get-Font 'Segoe UI' 18 ([System.Drawing.FontStyle]::Bold)) $brandDark ($x + $w - 85) ($abY + 49)

    # search bar
    $sbY = $abY + $abH + 30
    Fill-RoundRect $g ($x + 40) $sbY ($w - 80) 84 18 $white
    Stroke-RoundRect $g ($x + 40) $sbY ($w - 80) 84 18 $line 1.4
    $sbFont = Get-Font 'Segoe UI' 22 ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g 'Search in recognised text...' $sbFont $muted ($x + 84) ($sbY + 30)

    # stats
    $stFont = Get-Font 'Segoe UI' 18 ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g '3 / 3 pages   1,247 chars' $stFont $muted ($x + 50) ($sbY + 110)

    # page sections
    $sections = @(
        @{ idx='1'; title='Page 1 - 412 chars'; lines=@(
            'INVOICE  -  No. 2026-0042',
            'Issued to: Acme Corp.',
            'Date: 15 March 2026',
            'Total: $1,284.00'
        )},
        @{ idx='2'; title='Page 2 - 538 chars'; lines=@(
            'Description                      Qty   Amount',
            'Cloud hosting (annual)            1   $948.00',
            'Domain renewal                    2   $48.00',
            'Support hours                    24   $288.00'
        )},
        @{ idx='3'; title='Page 3 - 297 chars'; lines=@(
            'Thank you for your business.',
            'Payment terms: NET 30.',
            'Wire instructions on the next page.'
        )}
    )
    $sy = $sbY + 170
    foreach ($s in $sections) {
        $cardH = 80 + 30 + (40 * $s.lines.Count) + 30
        Fill-RoundRect $g ($x + 40) $sy ($w - 80) $cardH 22 $white
        Stroke-RoundRect $g ($x + 40) $sy ($w - 80) $cardH 22 $line 1.4
        # numbered chip + title
        Fill-RoundRect $g ($x + 70) ($sy + 28) 56 56 14 $brandTint
        $nf = Get-Font 'Segoe UI' 24 ([System.Drawing.FontStyle]::Bold)
        Draw-TextCenter $g $s.idx $nf $brandDark ($x + 98) ($sy + 56)
        $nf.Dispose()
        $tf = Get-Font 'Segoe UI' 22 ([System.Drawing.FontStyle]::Bold)
        Draw-Text $g $s.title $tf $ink ($x + 144) ($sy + 38)
        $tf.Dispose()
        # body text lines
        $bf = Get-Font 'Consolas' 22 ([System.Drawing.FontStyle]::Regular)
        $ly = $sy + 110
        foreach ($l in $s.lines) {
            Draw-Text $g $l $bf $ink ($x + 70) $ly
            $ly += 40
        }
        $bf.Dispose()
        $sy += $cardH + 20
    }
}

# Library page mock
$drawLibrary = {
    param($g,$x,$y,$w,$h)
    Fill-Rect $g $x $y $w $h $bg
    Draw-StatusBar $g $x $y $w 64 $bg $ink
    # title
    $titleFont = Get-Font 'Segoe UI' 56 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g 'My Documents' $titleFont $ink ($x + 50) ($y + 90)
    $titleFont.Dispose()
    # view-toggle buttons hint
    Fill-RoundRect $g ($x + $w - 200) ($y + 100) 70 70 16 $brandTint
    $tg = Get-Font 'Segoe UI' 18 ([System.Drawing.FontStyle]::Bold)
    Draw-TextCenter $g 'GRID' $tg $brandDark ($x + $w - 165) ($y + 135)
    Stroke-RoundRect $g ($x + $w - 110) ($y + 100) 70 70 16 $line 1.4
    Draw-TextCenter $g 'LIST' $tg $muted ($x + $w - 75) ($y + 135)
    $tg.Dispose()
    # search bar
    $sbY = $y + 200
    Fill-RoundRect $g ($x + 40) $sbY ($w - 80) 92 22 $white
    Stroke-RoundRect $g ($x + 40) $sbY ($w - 80) 92 22 $line 1.4
    $sbFont = Get-Font 'Segoe UI' 24 ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g 'Search documents...' $sbFont $muted ($x + 88) ($sbY + 32)
    $sbFont.Dispose()

    # premium upsell card
    $pY = $sbY + 120
    $p1 = New-Object System.Drawing.PointF(($x + 40), $pY)
    $p2 = New-Object System.Drawing.PointF(($x + 40 + ($w - 80)), $pY)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($p1, $p2, $premiumStart, $premiumEnd)
    $rrPath = New-RoundedRectPath ($x + 40) $pY ($w - 80) 110 22
    $g.FillPath($br, $rrPath)
    $br.Dispose(); $rrPath.Dispose()
    $pf = Get-Font 'Segoe UI' 28 ([System.Drawing.FontStyle]::Bold)
    Draw-Text $g 'Lifetime Premium  -  $4.99' $pf $white ($x + 70) ($pY + 18)
    $pf.Dispose()
    $pf2 = Get-Font 'Segoe UI' 20 ([System.Drawing.FontStyle]::Regular)
    Draw-Text $g 'No ads, unlimited scans, all features' $pf2 ([System.Drawing.Color]::FromArgb(0xE0,0xFF,0xFF,0xFF)) ($x + 70) ($pY + 60)
    $pf2.Dispose()

    # rows
    $docs = @(
        @{ t='Invoice 2026-0042';   pdf=$true;  m='2026-05-09  -  3 pages  -  486 KB' },
        @{ t='Lab notes - week 12'; pdf=$false; m='2026-05-08  -  2 pages  -  312 KB' },
        @{ t='Lease agreement';     pdf=$true;  m='2026-05-05  -  6 pages  -  1.1 MB' },
        @{ t='Receipt - dinner';    pdf=$false; m='2026-05-03  -  1 page   -  124 KB' },
        @{ t='Conference badge';    pdf=$false; m='2026-04-28  -  1 page   -  98 KB'  }
    )
    $ry = $pY + 150
    $rh = 130
    foreach ($d in $docs) {
        Draw-DocCardListRow $g ($x + 40) $ry ($w - 80) $rh $d.t $d.pdf $d.m
        $ry += $rh + 20
    }
}

# ---------- top-level renderers ----------

Render-FeatureGraphic

Render-PhoneCaption 'phone_01_hero_1080x1920.png' `
    'Real document scanner' 'Live edges, on-device OCR, clean PDF & JPG' `
    $drawHero

Render-PhoneCaption 'phone_02_camera_1080x1920.png' `
    'Live edge detection' 'Corners snap into place as you frame the page' `
    $drawCamera

Render-PhoneCaption 'phone_03_ocr_1080x1920.png' `
    'On-device OCR in 5 scripts' 'Latin / Chinese / Japanese / Korean / Devanagari' `
    $drawOcr

Render-PhoneCaption 'phone_04_library_1080x1920.png' `
    'Multi-page library' 'Rename, reorder, search, share' `
    $drawLibrary

# Tablet shots reuse the library mockup at larger canvases.
function Render-TabletLibrary {
    param([string]$file,[int]$w,[int]$h)
    $cv = New-Canvas $w $h $bg
    $bmp = $cv[0]; $g = $cv[1]
    $captionH = [int]($h * 0.16)
    $footerH  = [int]($h * 0.10)
    Draw-CaptionBand $g 0 0 $w $captionH 'Doc Scanner Pro' 'A real document scanner in your pocket'
    & $drawLibrary $g 0 $captionH $w ($h - $captionH - $footerH)
    Fill-Rect $g 0 ($h - $footerH) $w $footerH $white
    Fill-Rect $g 0 ($h - $footerH) $w 1 $line
    Draw-FootBrand $g 60 ($h - $footerH + ($footerH - 110)/2) 110 44 $ink
    Save-PNG $bmp $g (Join-Path $outDir $file)
}

Render-TabletLibrary  'tablet_1080x1920.png'    1080 1920
Render-TabletLibrary  'tablet10_1440x2560.png'  1440 2560

Write-Host ""
Write-Host "All assets in: $outDir"
