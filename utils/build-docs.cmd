@echo off
cd %~dp0

docker run --rm -it -v %~dp0\..:/docs squidfunk/mkdocs-material build
