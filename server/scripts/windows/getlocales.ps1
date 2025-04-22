# Powershell script to get system locales in their BCP-47 codes 
# followed by the long names minus names with non-ASCII characters.


# fetching all system locales
$cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) | Where-Object { $_.LCID -ne 127 }

# formatting BCP names for locales in "key=value" style 
$cultures | Sort-Object Name | ForEach-Object { $_.Name + '=' + $_.Name }

# filter cutlures containing only ASCII characters
$filteredCultures = $cultures | Where-Object { $_.EnglishName -match '^[\x00-\x7F]+$' } | Sort-Object EnglishName
 
# Formatting locales in a way that is recognizable by initdb
foreach ($culture in $filteredCultures) {
    $name = $culture.EnglishName
    if ($name -match '^([^,]+), ([^(]+) \(([^)]+)\)$') { 
        $name = "$($matches[1]) ($($matches[2])), $($matches[3])" 
    } elseif ($name -match '^(.+?) \(([^,]+), (.+?)\)$') { 
        $name = "$($matches[1]) ($($matches[2])), $($matches[3])" 
    } elseif ($name -match '^(.+?) \((.+)\)$') { 
        $name = "$($matches[1]), $($matches[2])" 
    }
        "$name=$name"
}
