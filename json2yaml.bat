@echo off

rem Delete output from prior run
if exist %1.yaml del %1.yaml

python -c "import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)" < %1.json > %1.yaml