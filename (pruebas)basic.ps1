# Ejecutar el script directamente desde GitHub usando Invoke-WebRequest
#  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/practicasB-Juanjo/Script/main/basic.ps1" | Select-Object -ExpandProperty Content | Invoke-Expression
#  irm "https://raw.githubusercontent.com/practicasB-Juanjo/Script/main/basic.ps1" | iex
# Inicializar un registro para seguimiento de operaciones
$log = @()

# Función para registrar el estado de las operaciones
function Registrar-Estado {
    param (
        [string]$Operacion,
        [string]$Estado
    )
    $log += @{
        Operacion = $Operacion
        Estado = $Estado
    }
}

# Función para comprobar el éxito de una operación
function Comprobar-Exito {
    param (
        [string]$Operacion,
        [bool]$Exito
    )
    if ($Exito) {
        Registrar-Estado $Operacion "Éxito"
    } else {
        Registrar-Estado $Operacion "Error"
    }
}

# Instalar programas utilizando Winget
try {
    winget install --id=Adobe.Acrobat.Reader.64-bit -e --silent
    Comprobar-Exito "Instalación de Adobe Acrobat Reader" $true
} catch {
    Comprobar-Exito "Instalación de Adobe Acrobat Reader" $false
}

try {
    winget install --id=Google.Chrome -e --silent
    Comprobar-Exito "Instalación de Google Chrome" $true
} catch {
    Comprobar-Exito "Instalación de Google Chrome" $false
}

try {
    winget install --id=7zip.7zip -e --silent
    Comprobar-Exito "Instalación de 7-Zip" $true
} catch {
    Comprobar-Exito "Instalación de 7-Zip" $false
}

try {
    winget install --id=VideoLAN.VLC -e --silent
    Comprobar-Exito "Instalación de VLC" $true
} catch {
    Comprobar-Exito "Instalación de VLC" $false
}

try {
    winget install --id=RARLab.WinRAR -e --silent
    Comprobar-Exito "Instalación de WinRAR" $true
} catch {
    Comprobar-Exito "Instalación de WinRAR" $false
}

try {
    winget install --id=Mozilla.Firefox -e --silent
    Comprobar-Exito "Instalación de Firefox" $true
} catch {
    Comprobar-Exito "Instalación de Firefox" $false
}

# Deshabilitar IPv6 en todos los adaptadores
try {
    Get-NetAdapter | ForEach-Object {
        Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6
    }
    Comprobar-Exito "Deshabilitar IPv6 en adaptadores de red" $true
} catch {
    Comprobar-Exito "Deshabilitar IPv6 en adaptadores de red" $false
}

# Configurar plan de energía
try {
    powercfg -change -standby-timeout-ac 0
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    Comprobar-Exito "Configuración del plan de energía" $true
} catch {
    Comprobar-Exito "Configuración del plan de energía" $false
}

# Activar y luego desactivar BitLocker
try {
    $drives = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -eq "FullyDecrypted" }
    if ($drives -eq $null -or $drives.Count -eq 0) {
        Registrar-Estado "BitLocker" "No se encontraron volúmenes para cifrar."
    } else {
        foreach ($drive in $drives) {
            try {
                Enable-BitLocker -MountPoint $drive.MountPoint -RecoveryPasswordProtector -UsedSpaceOnly
                Disable-BitLocker -MountPoint $drive.MountPoint
                Comprobar-Exito "BitLocker en unidad $($drive.MountPoint)" $true
            } catch {
                Comprobar-Exito "BitLocker en unidad $($drive.MountPoint)" $false
            }
        }
    }
} catch {
    Comprobar-Exito "BitLocker" $false
}

# Buscar e instalar actualizaciones de Windows
try {
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
    Import-Module PSWindowsUpdate -ErrorAction Stop
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot
    Comprobar-Exito "Actualización de Windows" $true
} catch {
    Comprobar-Exito "Actualización de Windows" $false
}

# Actualizar controladores automáticamente
try {
    $devices = Get-PnpDevice -Status "Error" | Where-Object { $_.Class -ne $null }
    if ($devices.Count -gt 0) {
        foreach ($device in $devices) {
            try {
                Update-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
                Comprobar-Exito "Actualización del controlador $($device.Name)" $true
            } catch {
                Comprobar-Exito "Actualización del controlador $($device.Name)" $false
            }
        }
    } else {
        Registrar-Estado "Actualización de controladores" "No se encontraron dispositivos con errores."
    }
} catch {
    Comprobar-Exito "Actualización de controladores" $false
}

# Mostrar el registro final del estado de las operaciones
Write-Output "Resumen de operaciones:"
$log | ForEach-Object {
    Write-Output "$($_.Operacion): $($_.Estado)"
}
