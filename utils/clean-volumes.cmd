@echo off
cd %~dp0
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
rmdir /q /s %~dp0/../data/volumes/db-backup/
rmdir /q /s %~dp0/../data/volumes/grafana-data/
rmdir /q /s %~dp0/../data/volumes/log-data/
rmdir /q /s %~dp0/../data/volumes/pg-admin-data/
rmdir /q /s %~dp0/../data/volumes/postgis-data/
EXIT
