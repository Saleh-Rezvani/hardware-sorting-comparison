@echo off
rem Runs Vivado batch simulation from Windows Command Prompt.
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "TCL_SCRIPT=%SCRIPT_DIR%sim.tcl"
set "VIVADO_DIR=%REPO_ROOT%\vivado"

where vivado >nul 2>&1
if %errorlevel% equ 0 (
    set "VIVADO_BIN=vivado"
) else if defined XILINX_VIVADO (
    set "VIVADO_BIN=%XILINX_VIVADO%\bin\vivado.bat"
) else if exist "E:\Xilinx_Vivado\Vivado\2019.2\bin\vivado.bat" (
    set "VIVADO_BIN=E:\Xilinx_Vivado\Vivado\2019.2\bin\vivado.bat"
) else (
    echo [ERROR] vivado executable not found in PATH.
    echo Run settings64.bat from your Vivado installation first.
    goto :handle_exit
)

if not exist "%VIVADO_DIR%" mkdir "%VIVADO_DIR%"

rem Run inside vivado/ so temporary files like .Xil stay isolated from source trees.
pushd "%VIVADO_DIR%"
call "%VIVADO_BIN%" -mode batch -source "%TCL_SCRIPT%" -nolog -nojournal -tclargs %*
popd

:handle_exit
rem Keep window open if launched by double-clicking from File Explorer.
echo %cmdcmdline% | findstr /i /c:"/c" >nul 2>&1
if %errorlevel% equ 0 pause
