@echo off

docker run --rm -it -v %~dp0\..:/docs squidfunk/mkdocs-material build
