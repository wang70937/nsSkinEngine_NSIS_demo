md output bin
copy /y %~dp0\license\license.rtf %~dp0\bin
set path==%path%;%~dp0/NSIS;
del /q %~dp0\blank
:: fix egg pain
copy /y %~dp0\NSIS\makensis.exe %~dp0\NSIS\makensis.exe.bak
del /q %~dp0\NSIS\makensis.exe
copy /y %~dp0\NSIS\makensis.exe.bak %~dp0\NSIS\makensis.exe

makensis.exe "%~f1"
pause