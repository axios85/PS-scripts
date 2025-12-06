# 1. Crear un nuevo tema basado en el predeterminado
New-AdfsWebTheme -Name "TemaFergava" -SourceName default

# 2. Establecer el nuevo tema como activo
Set-AdfsWebConfig -ActiveThemeName "TemaFergava"

# 3. Subir el logo personalizado
Set-AdfsWebTheme -TargetName "TemaFergava" -Logo @{path="C:\Install\logo.png"}

# 4. Subir la imagen de fondo personalizada
Set-AdfsWebTheme -TargetName "TemaFergava" -Illustration @{path="C:\Install\fondo.jpg"}
