@echo off
setlocal
set CUDA_VERSION=
for /f "tokens=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 delims= " %%a in ('nvcc --version') do (
    if "%%a"=="Cuda" (
        for /f "tokens=1 delims=," %%a in ("%%e") do (
            for /f "tokens=1,2 delims=." %%a in ("%%a") do (
                set CUDA_VERSION=%%a_%%b
            )
        )
    )
)
if "%CUDA_VERSION%"=="" (
    echo CUDA not found!
) else (
    echo CUDA Version: %CUDA_VERSION%
    echo Reinstalling torch with CUDA support
    "%~dp0\python-3.10.11-embed\python.exe" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 --no-deps --no-cache-dir --force-reinstall --upgrade
    echo Done
)