# =============================================================================
# SCRIPT V2: GENERACIÓN DE USUARIOS CON EMAIL (CAMPO MAIL)
# =============================================================================

# 1. Configuración de la Contraseña
$PasswordTexto = "#PruebaGsync"
$PasswordSegura = ConvertTo-SecureString $PasswordTexto -AsPlainText -Force

# 2. Obtener la raíz del dominio
try {
    $DomainObj = Get-ADDomain
    $DomainRoot = $DomainObj.DistinguishedName
    $DnsRoot = $DomainObj.DNSRoot # Ej: ad.fergava.es
    Write-Host "Dominio detectado: $DnsRoot ($DomainRoot)" -ForegroundColor Green
}
catch {
    Write-Host "Error: No se detecta el dominio. Ejecuta en un DC." -ForegroundColor Red
    Break
}

# --- Definición de Datos ---
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
    $OUName = $OU.Name
    $OUPath = "OU=$OUName,$DomainRoot"
    
    # Asegurar que la OU existe
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'")) {
        New-ADOrganizationalUnit -Name $OUName -Path $DomainRoot
        Write-Host "OU '$OUName' creada." -ForegroundColor Cyan
    }

    foreach ($User in $OU.Users) {
        $FullName = "$($User.First) $($User.Last)"
        # Aquí construimos el email igual que el UPN
        $Email = "$($User.Account)@$DnsRoot" 
        
        try {
            # Intentamos crear el usuario CON el campo EmailAddress
            New-ADUser -Name $FullName `
                       -GivenName $User.First `
                       -Surname $User.Last `
                       -SamAccountName $User.Account `
                       -UserPrincipalName $Email `
                       -EmailAddress $Email `
                       -Path $OUPath `
                       -AccountPassword $PasswordSegura `
                       -Enabled $true `
                       -PasswordNeverExpires $true `
                       -CannotChangePassword $true `
                       -ErrorAction Stop
            
            Write-Host "   [+] Creado: $FullName - Email: $Email" -ForegroundColor Green
        }
        catch {
            # Si el usuario ya existe, LE ACTUALIZAMOS EL EMAIL
            Write-Host "   [~] El usuario '$FullName' ya existe. Actualizando Email..." -NoNewline
            try {
                Set-ADUser -Identity $User.Account -EmailAddress $Email -ErrorAction Stop
                Write-Host " HECHO ($Email)" -ForegroundColor Yellow
            }
            catch {
                Write-Host " ERROR al actualizar." -ForegroundColor Red
            }
        }
    }
}
Write-Host "`nScript finalizado. Todos los usuarios tienen ahora el campo 'E-mail' lleno."
