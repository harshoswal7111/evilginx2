@echo off
set GOARCH=amd64
echo Building...
go build -o .\build\websec.exe -mod=vendor && cls && .\build\websec.exe -p ./phishlets -t ./redirectors -developer -debug
