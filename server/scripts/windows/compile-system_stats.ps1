# Powershell script to compile system_stats

# Setting variables
$vc_bat_file="$(pwd)\packaging-config\installer\server\scripts\windows\vc-build-x64.bat"
$project_file="$(pwd)\system_stats\system_stats.vcxproj"
$out_dir="$(pwd)\system_stats\x64\Release\"

# Compilation
Invoke-Expression -Command "$vc_bat_file $project_file Release x64 $out_dir v143" || exit 1

# Copy system-stats dlls to correct place
Copy-Item "$(pwd)\system_stats\x64\Release\system_stats.dll" "$(pwd)\binaries-archive\pgsql\lib"
Copy-Item "$(pwd)\system_stats\x64\Release\system_stats.dll" "$(pwd)\packaging-config\installer\server"
