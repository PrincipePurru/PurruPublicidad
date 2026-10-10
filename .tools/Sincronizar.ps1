param(
 [string]$Carpeta=(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Imagenes De Prueba para Purru Publicidad'),
 [switch]$Publicar,
 [switch]$Vigilar,
 [string]$Repositorio='https://github.com/PrincipePurru/PurruPublicidad.git'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$git=(Get-Command git -ErrorAction SilentlyContinue).Source
if(!$git){$git=Join-Path $env:LOCALAPPDATA 'OpenClaw\deps\portable-git\mingw64\bin\git.exe'}
$base=Join-Path $PSScriptRoot 'Sitio'
$utf8=New-Object Text.UTF8Encoding($false)
function Git {
 param([string[]]$Argumentos)
 & $git -C $base @Argumentos
 if($LASTEXITCODE -ne 0){throw "Git no pudo completar la operacion. Revisa el inicio de sesion en el navegador. No pegues claves en la consola."}
}
function Preparar {
 if(!(Test-Path -LiteralPath $Carpeta -PathType Container)){throw "No existe la carpeta de imagenes: $Carpeta"}
 $files=@(Get-ChildItem -LiteralPath $Carpeta -File | Where-Object Extension -Match '^\.(png|jpg|jpeg|bmp)$' | Sort-Object Name)
 if($files.Count -gt 32){throw 'Hay mas de 32 imagenes. El prefab admite 32. No se publico ningun cambio.'}
 $slots=@{};$extras=@()
 foreach($f in $files){
   if($f.BaseName -match '^Cuadro[ _-]*(\d+)$'){
     $n=[int]$Matches[1]
     if($n -lt 1 -or $n -gt 32){throw "Numero fuera de 1-32: $($f.Name)"}
     if($slots.ContainsKey($n)){throw "Dos imagenes usan Cuadro $n. Conserva solo una."}
     $slots[$n]=$f
   }else{$extras+=,$f}
 }
 # Nombres nuevos reciben una asignacion persistente, sin renombrar originales.
 $mapPath=Join-Path $PSScriptRoot 'asignaciones-locales.json';$map=@{}
 if(Test-Path -LiteralPath $mapPath){$old=Get-Content -LiteralPath $mapPath -Raw|ConvertFrom-Json;foreach($p in $old.PSObject.Properties){$map[$p.Name]=[int]$p.Value}}
 foreach($f in $extras){
   $n=0;if($map.ContainsKey($f.Name) -and !$slots.ContainsKey($map[$f.Name])){$n=$map[$f.Name]}
   if(!$n){for($i=1;$i -le 32;$i++){if(!$slots.ContainsKey($i)){$n=$i;break}}}
   if(!$n){throw 'No quedan ranuras disponibles.'};$slots[$n]=$f;$map[$f.Name]=$n
 }
 $temp=Join-Path $PSScriptRoot ('Preparado-'+[Guid]::NewGuid().ToString('N'))
 [IO.Directory]::CreateDirectory($temp)|Out-Null
 $lines=New-Object 'Collections.Generic.List[string]';$lines.Add('PURRUPUBLICIDAD1');$items=@()
 try{
  for($i=1;$i -le 32;$i++){
   if(!$slots.ContainsKey($i)){$lines.Add('-');continue}
   $f=$slots[$i];$dest=Join-Path $temp ('cuadro-{0:00}.jpg' -f $i)
   $img=[Drawing.Image]::FromFile($f.FullName)
   try{
    if($img.PropertyIdList -contains 274){$o=$img.GetPropertyItem(274).Value[0];$rot=switch($o){2{'RotateNoneFlipX'}3{'Rotate180FlipNone'}4{'Rotate180FlipX'}5{'Rotate90FlipX'}6{'Rotate90FlipNone'}7{'Rotate270FlipX'}8{'Rotate270FlipNone'}default{'RotateNoneFlipNone'}};$img.RotateFlip([Drawing.RotateFlipType]::$rot)}
    $s=[Math]::Min(1,1024.0/[Math]::Max($img.Width,$img.Height));$w=[Math]::Max(1,[int]($img.Width*$s));$h=[Math]::Max(1,[int]($img.Height*$s))
    $bmp=New-Object Drawing.Bitmap $w,$h;$g=[Drawing.Graphics]::FromImage($bmp)
    try{$g.Clear([Drawing.Color]::White);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$g.DrawImage($img,0,0,$w,$h)
     $codec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where-Object MimeType -eq 'image/jpeg'
     $param=New-Object Drawing.Imaging.EncoderParameters 1;$param.Param[0]=New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality),([long]88)
     try{$bmp.Save($dest,$codec,$param)}finally{$param.Dispose()}
    }finally{$g.Dispose();$bmp.Dispose()}
   }finally{$img.Dispose()}
   $hash=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant();$lines.Add($hash)
   $items+=@{numero=$i;archivo=('cuadro-{0:00}.jpg' -f $i);nombre=$f.BaseName;ancho=$w;alto=$h;version=$hash}
  }
  [IO.File]::WriteAllText((Join-Path $temp 'estado.txt'),($lines -join "`n")+"`n",$utf8)
  [IO.File]::WriteAllText((Join-Path $temp 'galeria.json'),(ConvertTo-Json -InputObject @($items) -Depth 4),$utf8)
  [IO.File]::WriteAllText((Join-Path $temp 'index.html'),[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'galeria.html')),$utf8)
  [IO.File]::WriteAllText((Join-Path $temp '.nojekyll'),'',$utf8)
  [IO.Directory]::CreateDirectory($base)|Out-Null
  # Solo reemplazamos los archivos generados; nunca los originales ni otros archivos del repositorio.
  foreach($f in Get-ChildItem -LiteralPath $base -File){if($f.Name -match '^cuadro-\d{2}\.jpg$' -and !(Test-Path -LiteralPath (Join-Path $temp $f.Name))){Remove-Item -LiteralPath $f.FullName}}
  foreach($f in Get-ChildItem -LiteralPath $temp -File -Force){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $base $f.Name) -Force}
  [IO.File]::WriteAllText($mapPath,($map|ConvertTo-Json),$utf8)
  Write-Host ("Preparadas {0} imagenes de 32. Originales intactos." -f $items.Count) -ForegroundColor Cyan
 }finally{
  # El temporal es generado por esta ejecucion, dentro de Publicador~.
  $resolved=[IO.Path]::GetFullPath($temp);$allowed=[IO.Path]::GetFullPath($PSScriptRoot)+[IO.Path]::DirectorySeparatorChar
  if($resolved.StartsWith($allowed) -and (Split-Path $resolved -Leaf) -like 'Preparado-*'){Remove-Item -LiteralPath $resolved -Recurse -Force}
 }
}
function PublicarSitio {
 if(!(Test-Path -LiteralPath $git)){throw 'No se encuentra Git para publicar.'}
 if(!(Test-Path -LiteralPath (Join-Path $base '.git'))){
   Git -Argumentos @('init','-b','main');Git -Argumentos @('config','user.name','PrincipePurru');Git -Argumentos @('config','user.email','PrincipePurru@users.noreply.github.com');Git -Argumentos @('remote','add','origin',$Repositorio)
 }
 # La carpeta imagenes es la fuente editable desde GitHub. Actions regenera el sitio al cambiarla.
 $sources=Join-Path $base 'imagenes';[IO.Directory]::CreateDirectory($sources)|Out-Null
 $wanted=@(Get-ChildItem -LiteralPath $base -Filter 'cuadro-*.jpg' -File)
 foreach($f in Get-ChildItem -LiteralPath $sources -File){if($f.BaseName -match '^Cuadro (\d+)$'){$n=[int]$Matches[1];if(!(Test-Path -LiteralPath (Join-Path $base ('cuadro-{0:00}.jpg' -f $n)))){Remove-Item -LiteralPath $f.FullName}}}
 foreach($f in $wanted){$n=[int]([regex]::Match($f.BaseName,'\d+').Value);Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $sources ('Cuadro '+$n+'.jpg')) -Force}
 [IO.File]::WriteAllText((Join-Path $sources '.gitkeep'),'',$utf8)
 $toolDir=Join-Path $base '.tools';$flowDir=Join-Path $base '.github\workflows'
 [IO.Directory]::CreateDirectory($toolDir)|Out-Null;[IO.Directory]::CreateDirectory($flowDir)|Out-Null
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Sincronizar.ps1') -Destination (Join-Path $toolDir 'Sincronizar.ps1') -Force
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'galeria.html') -Destination (Join-Path $toolDir 'galeria.html') -Force
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'pages.yml') -Destination (Join-Path $flowDir 'pages.yml') -Force
 [IO.File]::WriteAllText((Join-Path $base '.gitignore'),".tools/Sitio/`n.tools/asignaciones-locales.json`n.tools/Preparado-*/`n",$utf8)
 # Si se edito desde GitHub, detener antes de reemplazar cambios de otra fuente.
 Git -Argumentos @('fetch','origin')
 $remote=& $git -C $base rev-parse --verify origin/main 2>$null
 if($LASTEXITCODE -eq 0){$local=& $git -C $base rev-parse HEAD;if($remote -ne $local){throw 'Hay cambios hechos desde GitHub. No se sobrescribieron. Usa Recuperar cambios de GitHub antes de volver a publicar desde PC.'}}
 # No sobrescribir cambios remotos. Si hay divergencia se conserva todo y se pide revisar.
 Git -Argumentos @('add','--all');$changes=& $git -C $base status --porcelain
 if($changes){Git -Argumentos @('commit','-m','Actualizar cuadros de PurruPublicidad')}
 Git -Argumentos @('push','-u','origin','main')
 Write-Host 'Publicado. GitHub Pages puede tardar unos minutos; el mundo revisa cada dos minutos y respeta la cache.' -ForegroundColor Green
}
do {
 try{Preparar;if($Publicar -or $Vigilar){PublicarSitio}}
 catch{Write-Host $_.Exception.Message -ForegroundColor Red;if(!$Vigilar){exit 1}}
 if($Vigilar){Write-Host 'Vigilando carpeta. Cierra esta ventana para detener. Proxima revision: 60 segundos.';Start-Sleep -Seconds 60}
}while($Vigilar)
