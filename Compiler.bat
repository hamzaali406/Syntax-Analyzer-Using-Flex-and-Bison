@echo off
echo ============================================
echo Building MiniX++ Compiler
echo ============================================
echo.

echo Step 1: Clean up...
del lex.yy.c 2>nul
del y.tab.c 2>nul
del y.tab.h 2>nul
del minixpp.exe 2>nul
del output.txt 2>nul
del errors.txt 2>nul

echo Step 2: Run Bison...
bison -d -y minixpp.y
if errorlevel 1 (
    echo BISON ERROR: Check minixpp.y syntax
    pause
    exit /b 1
)

echo Step 3: Run Flex...
flex minixpp.l
if errorlevel 1 (
    echo FLEX ERROR: Check minixpp.l syntax
    pause
    exit /b 1
)

echo Step 4: Compile...
gcc lex.yy.c y.tab.c -o minixpp.exe
if errorlevel 1 (
    echo GCC ERROR: Try mingw32-gcc or install MinGW
    pause
    exit /b 1
)

echo.
echo ============================================
echo BUILD SUCCESSFUL!
echo ============================================
echo.
echo Test with:
echo   minixpp.exe test.mxpp
echo.
pause