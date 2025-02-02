@echo off
setlocal
echo Updating scikit-build-core
"%~dp0\python-3.10.11-embed\python.exe" -m pip install scikit-build-core --upgrade
set CMAKE_ARGS=-DLLAMA_VULKAN=1
set FORCE_CMAKE=1
echo Updating llama-cpp-python
"%~dp0\python-3.10.11-embed\python.exe" -m pip install llama-cpp-python --no-deps --no-cache-dir --force-reinstall --upgrade
echo Done