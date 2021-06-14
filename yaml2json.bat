@echo off

rem Delete output from prior run
if exist %1.json del %1.json

python -c "import sys, yaml, json; json.dump(yaml.load(sys.stdin, yaml.SafeLoader), sys.stdout, indent=4)" < %1.yaml > %1.json