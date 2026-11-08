# Generates the LUNTI launcher icon sources from the app's own brand mark.
#
# The mark matches `_LuntiLeafMark` in lib/widgets/brand_header.dart and the
# splash: the Material `eco_rounded` leaf in forest green on a sage circle.
# Run from the project root:
#
#   powershell -ExecutionPolicy Bypass -File tool/generate_app_icon.ps1
#
# Outputs:
#   assets/icon/app_icon.png             opaque square icon (legacy launchers)
#   assets/icon/app_icon_foreground.png  transparent adaptive foreground layer
#   assets/icon/app_icon_monochrome.png  transparent Android 13 themed layer
#
# Then regenerate the Android mipmaps with:
#   dart run flutter_launcher_icons

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "assets\icon"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$fontPath = "C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf"
if (-not (Test-Path $fontPath)) {
  throw "Material Icons font not found at $fontPath"
}

# LUNTI brand tokens (lib/app/app_theme.dart).
$cream = [System.Drawing.Color]::FromArgb(255, 250, 248, 242)   # #FAF8F2
$sage = [System.Drawing.Color]::FromArgb(255, 232, 236, 223)    # #E8ECDF
$forest = [System.Drawing.Color]::FromArgb(255, 52, 78, 65)     # #344E41
$ecoCodePoint = [char]0xF6F2                                     # Icons.eco_rounded

$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($fontPath)
$family = $pfc.Families[0]

function New-LeafBitmap([int]$renderSize) {
  $canvas = New-Object System.Drawing.Bitmap $renderSize, $renderSize
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  $font = New-Object System.Drawing.Font(
    $family,
    [single]($renderSize * 0.75),
    [System.Drawing.FontStyle]::Regular,
    [System.Drawing.GraphicsUnit]::Pixel
  )
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $brush = New-Object System.Drawing.SolidBrush $forest
  $rect = New-Object System.Drawing.RectangleF 0, 0, $renderSize, $renderSize
  $g.DrawString([string]$ecoCodePoint, $font, $brush, $rect, $format)

  $brush.Dispose()
  $format.Dispose()
  $font.Dispose()
  $g.Dispose()

  # Crop to the glyph's actual ink so it can be centred exactly.
  $minX = $renderSize; $minY = $renderSize; $maxX = -1; $maxY = -1
  for ($y = 0; $y -lt $renderSize; $y++) {
    for ($x = 0; $x -lt $renderSize; $x++) {
      if ($canvas.GetPixel($x, $y).A -gt 8) {
        if ($x -lt $minX) { $minX = $x }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($y -gt $maxY) { $maxY = $y }
      }
    }
  }
  if ($maxX -lt 0) {
    $canvas.Dispose()
    throw "The eco glyph did not render; check the Material Icons font."
  }

  $cropRect = New-Object System.Drawing.Rectangle $minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1)
  $cropped = $canvas.Clone($cropRect, $canvas.PixelFormat)
  $canvas.Dispose()
  return $cropped
}

function New-Canvas([int]$size, [bool]$opaque, [System.Drawing.Color]$background) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear($(if ($opaque) { $background } else { [System.Drawing.Color]::Transparent }))
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  return @($bmp, $g)
}

function Add-Mark($graphics, [int]$size, [double]$haloRadius, [double]$circleRadius, [int]$leafHeight, $leaf) {
  $centre = $size / 2.0

  $haloBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(115, $sage))
  $graphics.FillEllipse($haloBrush, [single]($centre - $haloRadius), [single]($centre - $haloRadius), [single]($haloRadius * 2), [single]($haloRadius * 2))
  $haloBrush.Dispose()

  $circleBrush = New-Object System.Drawing.SolidBrush $sage
  $graphics.FillEllipse($circleBrush, [single]($centre - $circleRadius), [single]($centre - $circleRadius), [single]($circleRadius * 2), [single]($circleRadius * 2))
  $circleBrush.Dispose()

  $scale = $leafHeight / $leaf.Height
  $w = $leaf.Width * $scale
  $h = $leafHeight
  $dest = New-Object System.Drawing.RectangleF ([single]($centre - $w / 2)), ([single]($centre - $h / 2)), ([single]$w), ([single]$h)
  $graphics.DrawImage($leaf, $dest)
}

$leaf = New-LeafBitmap 1200

# Legacy square icon: cream canvas + sage mark.
$legacy = New-Canvas 1024 $true $cream
Add-Mark $legacy[1] 1024 390 350 360 $leaf
$legacy[0].Save((Join-Path $outDir "app_icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$legacy[1].Dispose(); $legacy[0].Dispose()

# Adaptive foreground: keep the mark inside the 66% safe zone of the 108dp layer.
$foreground = New-Canvas 1024 $false $cream
Add-Mark $foreground[1] 1024 330 295 300 $leaf
$foreground[0].Save((Join-Path $outDir "app_icon_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$foreground[1].Dispose(); $foreground[0].Dispose()

# Android 13 themed icon: a single-colour silhouette on transparent.
$mono = New-Canvas 1024 $false $cream
$monoScale = 360 / $leaf.Height
$monoW = $leaf.Width * $monoScale
$monoRect = New-Object System.Drawing.RectangleF ([single](512 - $monoW / 2)), ([single](512 - 180)), ([single]$monoW), ([single]360)
$mono[1].DrawImage($leaf, $monoRect)
$mono[0].Save((Join-Path $outDir "app_icon_monochrome.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$mono[1].Dispose(); $mono[0].Dispose()

$leaf.Dispose()
$pfc.Dispose()

Get-ChildItem $outDir | ForEach-Object { "wrote $($_.FullName) ($($_.Length) bytes)" }
