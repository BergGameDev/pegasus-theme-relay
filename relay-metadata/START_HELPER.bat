@echo off
cd /d "%~dp0"
py -3 -c "import sys" >nul 2>&1
if not errorlevel 1 (
    py -3 relay_metadata.py --managed
    goto finished
)
python -c "import sys" >nul 2>&1
if not errorlevel 1 (
    python relay_metadata.py --managed
    goto finished
)
echo Install Python 3 and the helper requirements before running this tool.
:finished
pause
