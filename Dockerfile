# escape=`
# Builds the Flutter application for Windows (x64). Requires Docker in Windows containers mode:
# Flutter cannot cross-compile Windows desktop binaries from a Linux container.
# The build context is the parent directory holding template-flutter and template-flutter-api-client:
#
#   docker build -f template-flutter/Dockerfile --build-arg API_BASE_URL=https://api.example.com `
#     -t template-flutter-windows ..
#
# The packaged artifacts are stored in C:\artifacts\windows; `make docker-build-windows` copies them
# into build/releases/windows.

ARG WINDOWS_TAG=ltsc2022
FROM mcr.microsoft.com/windows/servercore:${WINDOWS_TAG} AS sdk
SHELL ["powershell", "-NoLogo", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG FLUTTER_VERSION=3.47.5
ARG MINGIT_URL=https://github.com/git-for-windows/git/releases/download/v2.56.0.windows.2/MinGit-2.56.0.2-64-bit.zip

RUN Invoke-WebRequest https://aka.ms/vs/17/release/vs_buildtools.exe -OutFile C:\vs_buildtools.exe; `
    $process = Start-Process C:\vs_buildtools.exe -Wait -PassThru -ArgumentList `
        '--quiet', '--wait', '--norestart', '--nocache', `
        '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended'; `
    if ($process.ExitCode -notin 0, 3010) { throw ('Build Tools installation failed: ' + $process.ExitCode) }; `
    Remove-Item C:\vs_buildtools.exe

RUN Invoke-WebRequest $env:MINGIT_URL -OutFile C:\mingit.zip; `
    Expand-Archive C:\mingit.zip -DestinationPath C:\git; `
    Remove-Item C:\mingit.zip; `
    Invoke-WebRequest ('https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_' + $env:FLUTTER_VERSION + '-stable.zip') -OutFile C:\flutter.zip; `
    Expand-Archive C:\flutter.zip -DestinationPath C:\; `
    Remove-Item C:\flutter.zip; `
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\git\cmd;C:\flutter\bin', 'Machine')

RUN git config --global --add safe.directory '*'; `
    flutter config --no-analytics --no-cli-animations --enable-windows-desktop; `
    flutter precache --windows --no-android --no-web --no-ios --no-linux --no-macos; `
    flutter doctor -v

FROM sdk AS build
ARG API_BASE_URL=http://localhost:8989
WORKDIR C:\workspace
COPY template-flutter-api-client template-flutter-api-client
COPY template-flutter template-flutter
RUN .\template-flutter\scripts\package-windows.ps1 -ApiBaseUrl $env:API_BASE_URL -OutputDir C:\artifacts
