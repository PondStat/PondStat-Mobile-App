@echo off
echo Building Android App Bundle with Obfuscation...
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
echo Build complete.
