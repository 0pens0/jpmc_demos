@ echo off

call test_app_rules.bat
call test_iam_rules.bat
call test_naming_rules.bat
call test_network_rules.bat

kubectl apply -f dep-99994-990004-1001-prod-ops-fail.yaml
