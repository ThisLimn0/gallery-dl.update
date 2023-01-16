@ECHO OFF & SETLOCAL EnableDelayedExpansion
MODE 70,15 & TITLE gallery-dl.update.bat
SET "RepoURL=https://github.com/mikf/gallery-dl/releases/latest/"
SET "DownloadURL=https://github.com/mikf/gallery-dl/releases/download/"
SET "Binary=gallery-dl.exe"
SET "removeOld=false"

CALL :FileExistCheck
CALL :CheckVersion
CALL :VersionCompare
CALL :Download
PAUSE >NUL
EXIT /B


:FileExistCheck
:::Check file exist
IF EXIST "%~dp0!Binary!" (
    REM File exists.
) ELSE (
   ECHO.File does not exist.
   CALL :GetRemoteVersion
   CALL :Download
)
EXIT /B


:CheckVersion
:::Check local version
FOR /F "usebackq tokens=*" %%G IN (`CALL "%~dp0!Binary!" --version`) DO (
   SET "VerL=v%%G"
   REM ECHO.Local version: !VerL!
   IF DEFINED VerL (
      EXIT /B
   )
)
EXIT /B

:VersionCompare
:::Grab remote version and compare to local version
CALL :GetRemoteVersion
IF "!VerL!"=="!VerR!" (
   ECHO.!Binary! is up to date.
   PAUSE
   EXIT
) ELSE (
   ECHO.!Binary!: remote !VerR! ^<^> !VerL! --^> local is outdated.
   REM ECHO.Version is outdated.
)
EXIT /B

:GetRemoteVersion
CALL :PowershellDownload "%RepoURL%" "%~dp0version.html"
FOR /F "usebackq tokens=1-2" %%G IN (`FINDSTR /R /C:"<title>" version.html`) DO (
   SET "VerR=%%H"
   REM ECHO.Remote version: !VerR!
   IF DEFINED VerR (
      DEL /F /Q "%~dp0version.html"
      EXIT /B
   )
)
ECHO.Failed to get a remote version.
PAUSE
EXIT

:Download
:::Download new version
IF /I "!removeOld!" == "true" (
   IF EXIST "%~dp0!Binary!.old" (
      DEL /F /Q "%~dp0!Binary!.old"
   )
) ELSE IF /I "!removeOld!" == "false" (
   IF EXIST "%~dp0!Binary!" (
      REN "%~dp0!Binary!" "!Binary!.old" >NUL
   )
)
ECHO.Downloading new version...
CALL :PowershellDownload "!DownloadURL!!VerR!/!Binary!" "%~dp0!Binary!"
FOR /F "usebackq tokens=*" %%G IN (`CALL "%~dp0!Binary!" --version`) DO (
   SET "VerLn=v%%G"
   ECHO.Updated to version: !VerLn!
   IF DEFINED VerL (
      EXIT /B
   )
)
EXIT /B

:PowershellDownload
SET "PowershellDLMRemotePath=%~1"
SET "PowershellDLMLocalPath=%~2"
powershell -command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;(New-Object System.Net.WebClient).DownloadFile('!PowershellDLMRemotePath!','!PowershellDLMLocalPath!')" >NUL
EXIT /B



