# Runs Vivado batch simulation from PowerShell.
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TbArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$tclScript = Join-Path $scriptDir "sim.tcl"
$vivadoDir = Join-Path $repoRoot "vivado"

$vivadoCmd = Get-Command vivado -ErrorAction SilentlyContinue
if ($vivadoCmd) {
    $vivadoBin = "vivado"
} elseif ($env:XILINX_VIVADO -and (Test-Path "$env:XILINX_VIVADO\bin\vivado.bat")) {
    $vivadoBin = "$env:XILINX_VIVADO\bin\vivado.bat"
} elseif (Test-Path "E:\Xilinx_Vivado\Vivado\2019.2\bin\vivado.bat") {
    $vivadoBin = "E:\Xilinx_Vivado\Vivado\2019.2\bin\vivado.bat"
} else {
    Write-Error "vivado executable not found in PATH. Run settings64.bat from your Vivado installation first."
    exit 1
}

if (-not (Test-Path $vivadoDir)) {
    New-Item -ItemType Directory -Path $vivadoDir | Out-Null
}

# Run inside vivado/ so temporary files like .Xil stay isolated from source trees.
Push-Location $vivadoDir
try {
    if ($TbArgs) {
        & $vivadoBin -mode batch -source $tclScript -nolog -nojournal -tclargs @TbArgs
    } else {
        & $vivadoBin -mode batch -source $tclScript -nolog -nojournal
    }
} finally {
    Pop-Location
}
