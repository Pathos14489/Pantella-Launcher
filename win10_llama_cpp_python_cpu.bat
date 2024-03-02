@echo off
setlocal
set CMAKE_ARGS=""
set FORCE_CMAKE=0
echo Updating scikit-build-core
"%~dp0PythonFiles\python-3.10.11-embed\python.exe" -m pip install scikit-build-core --upgrade
echo Updating llama-cpp-python
"%~dp0PythonFiles\python-3.10.11-embed\python.exe" -m pip install llama-cpp-python --no-deps --no-cache-dir --force-reinstall --upgrade
echo Cleaning up directory
rmdir /s /q "./PythonFiles/llama_cpp_versions/cpu/ggufv2/%WIN_VERSION%/bin"
rmdir /s /q "./PythonFiles/llama_cpp_versions/cpu/ggufv2/%WIN_VERSION%/lib"
rmdir /s /q "./PythonFiles/llama_cpp_versions/cpu/ggufv2/%WIN_VERSION%/include"
echo Done