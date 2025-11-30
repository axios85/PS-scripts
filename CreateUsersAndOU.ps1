# =============================================================================
# SCRIPT DE GENERACIÓN DE LABORATORIO AD PARA PRUEBAS DE GOOGLE WORKSPACE
# =============================================================================

# 1. Configuración de la Contraseña
# Convertimos la contraseña a SecureString como requiere AD
$PasswordTexto = "#PruebaGsync"
$PasswordSegura = ConvertTo-SecureString $PasswordTexto -AsPlainText -Force

# 2. Obtener la raíz del dominio actual automáticamente (ej. DC=miempresa,DC=local)
try {
    $DomainRoot = (Get-ADDomain).DistinguishedName
    Write-Host "Dominio detectado: $DomainRoot" -ForegroundColor Green
}
catch {
    Write-Host "Error: No se puede detectar el dominio. Asegúrate de ejecutar esto en un DC o con RSAT instalado." -ForegroundColor Red
    Break
}

# --- Definición de Datos ---

# Definimos las 2 OUs y sus usuarios
$OUs = @(
    @{
        Name = "GSync_Ventas"
        Users = @(
            @{First="Ana"; Last="Lopez"; Account="alopez"},
            @{First="Carlos"; Last="Ruiz"; Account="cruiz"},
            @{First="Beatriz"; Last="Mendez"; Account="bmendez"}
        )
    },
    @{
        Name = "GSync_Sistemas"
        Users = @(
            @{First="David"; Last="Vega"; Account="dvega"},
            @{First="Elena"; Last="Sanz"; Account="esanz"},
            @{First="Fernando"; Last="Gomez"; Account="fgomez"}
        )
    }
)

# --- Ejecución ---

foreach ($OU in $OUs) {
    
    # 3. Crear la OU
    $OUName = $OU.Name
    $OUPath = "OU=$OUName,$DomainRoot"
    
    Write-Host "--- Procesando OU: $OUName ---" -ForegroundColor Cyan

    try {
        New-ADOrganizationalUnit -Name $OUName -Path $DomainRoot -ErrorAction Stop
        Write-Host "OU '$OUName' creada exitosamente." -ForegroundColor Green
    }
    catch {
        Write-Host "La OU '$OUName' ya existe o hubo un error. Saltando creación." -ForegroundColor Yellow
    }

    # 4. Crear los 3 Usuarios dentro de esa OU
    foreach ($User in $OU.Users) {
        $FullName = "$($User.First) $($User.Last)"
        $UPN = "$($User.Account)@$((Get-ADDomain).DNSRoot)" # Genera user@dominio.com

        try {
            New-ADUser -Name $FullName `
                       -GivenName $User.First `
                       -Surname $User.Last `
                       -SamAccountName $User.Account `
                       -UserPrincipalName $UPN `
                       -Path $OUPath `
                       -AccountPassword $PasswordSegura `
                       -Enabled $true `
                       -PasswordNeverExpires $true `
                       -CannotChangePassword $true `
                       -ErrorAction Stop
            
            Write-Host "   [+] Usuario creado: $FullName ($UPN)" 
        }
        catch {
            Write-Host "   [!] El usuario '$FullName' ya existe o hubo un error." -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n======================================================="
Write-Host "Proceso finalizado."
Write-Host "Contraseña asignada: $PasswordTexto"
Write-Host "Usuarios configurados con: 'PasswordNeverExpires' y 'CannotChangePassword'"
Write-Host "======================================================="
