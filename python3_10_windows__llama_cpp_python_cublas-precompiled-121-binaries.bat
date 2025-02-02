@echo off
setlocal
set CMAKE_ARGS=-DGGML_CUDA=on 
set FORCE_CMAKE=1
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
echo CUDA Version: %CUDA_VERSION%
echo %CMAKE_ARGS%
if "%CUDA_VERSION%"=="" (
    echo CUDA not found, skipping CUBLAS llama-cpp-python update. Try running windows_cpu_update_llama.bat instead for CPU support.
) else (
    echo Updating scikit-build-core
    "%~dp0\python-3.10.11-embed\python.exe" -m pip install scikit-build-core --upgrade
    echo Updating llama-cpp-python
    "%~dp0\python-3.10.11-embed\python.exe" -m pip install llama-cpp-python --no-deps --no-cache-dir --force-reinstall --upgrade --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121
    echo Done
)