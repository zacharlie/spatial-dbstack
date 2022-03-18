@echo off
setlocal
set thisdir=%~dp0
for %%a in ("%thisdir:~0,-1%") do set rootdir=%%~dpa
cd %rootdir%
echo "WARNING! This will delete all docker data from data/volumes"
SET /p choice=Are you sure you wish to continue this operation? [Y/N]:
IF NOT '%choice%'=='' SET choice=%choice:~0,1%
IF '%choice%'=='Y' GOTO process
IF '%choice%'=='y' GOTO process
ECHO.
GOTO exit

:exit
EXIT

:process
rmdir /q /s "%rootdir%/data/volumes/db-backup/"
rmdir /q /s "%rootdir%/data/volumes/grafana-data/"
rmdir /q /s "%rootdir%/data/volumes/log-data/'
rmdir /q /s "%rootdir%/data/volumes/pg-admin-data/"
rmdir /q /s "%rootdir%/data/volumes/postgis-data/"
rmdir /q /s "%rootdir%/data/volumes/uptime-kuma-data/"
EXIT
