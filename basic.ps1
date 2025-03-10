# Ejecutar el script directamente desde GitHub usando Invoke-WebRequest
#  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/practicasB-Juanjo/Script/main/basic.ps1" | Select-Object -ExpandProperty Content | Invoke-Expression
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

# Instalar programas utilizando Winget
try {
    winget install --id=Adobe.Acrobat.Reader.64-bit -e --silent
    Registrar-Estado "Instalación de Adobe Acrobat Reader" "Éxito"
} catch {
    Registrar-Estado "Instalación de Adobe Acrobat Reader" "Error: $_"
}

try {
    winget install --id=Google.Chrome -e --silent
    Registrar-Estado "Instalación de Google Chrome" "Éxito"
} catch {
    Registrar-Estado "Instalación de Google Chrome" "Error: $_"
}

try {
    winget install --id=7zip.7zip -e --silent
    Registrar-Estado "Instalación de 7-Zip" "Éxito"
} catch {
    Registrar-Estado "Instalación de 7-Zip" "Error: $_"
}

try {
    winget install --id=VideoLAN.VLC -e --silent
    Registrar-Estado "Instalación de VLC" "Éxito"
} catch {
    Registrar-Estado "Instalación de VLC" "Error: $_"
}

try {
    winget install --id=RARLab.WinRAR -e --silent
    Registrar-Estado "Instalación de WinRAR" "Éxito"
} catch {
    Registrar-Estado "Instalación de WinRAR" "Error: $_"
}

try {
    winget install --id=Mozilla.Firefox -e --silent
    Registrar-Estado "Instalación de Firefox" "Éxito"
} catch {
    Registrar-Estado "Instalación de Firefox" "Error: $_"
}

# Deshabilitar IPv6 en todos los adaptadores
try {
    Get-NetAdapter | ForEach-Object {
        Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6
    }
    Registrar-Estado "Deshabilitar IPv6 en adaptadores de red" "Éxito"
} catch {
    Registrar-Estado "Deshabilitar IPv6 en adaptadores de red" "Error: $_"
}

# Configurar plan de energía
try {
    powercfg -change -standby-timeout-ac 0
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    Registrar-Estado "Configuración del plan de energía" "Éxito"
} catch {
    Registrar-Estado "Configuración del plan de energía" "Error: $_"
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
                Registrar-Estado "BitLocker en unidad $($drive.MountPoint)" "Éxito"
            } catch {
                Registrar-Estado "BitLocker en unidad $($drive.MountPoint)" "Error: $_"
            }
        }
    }
} catch {
    Registrar-Estado "BitLocker" "Error: $_"
}

# Buscar e instalar actualizaciones de Windows
try {
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot
    Registrar-Estado "Actualización de Windows" "Éxito"
} catch {
    Registrar-Estado "Actualización de Windows" "Error: $_"
}

# Actualizar controladores automáticamente
try {
    $devices = Get-PnpDevice -Status "Error" | Where-Object { $_.Class -ne $null }
    if ($devices.Count -gt 0) {
        foreach ($device in $devices) {
            try {
                Update-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
                Registrar-Estado "Actualización del controlador $($device.Name)" "Éxito"
            } catch {
                Registrar-Estado "Actualización del controlador $($device.Name)" "Error: $_"
            }
        }
    } else {
        Registrar-Estado "Actualización de controladores" "No se encontraron dispositivos con errores."
    }
} catch {
    Registrar-Estado "Actualización de controladores" "Error: $_"
}

# Mostrar el registro final del estado de las operaciones
Write-Output "Resumen de operaciones:"
$log | ForEach-Object {
    Write-Output "$($_.Operacion): $($_.Estado)"
}
