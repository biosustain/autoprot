param([string] $InputFilePath, [string] $name, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath ($name + "_OpenSWATH.tsv")
$results = Import-Csv $InputFilePath -Delimiter "`t"
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$results = $results | Where-Object {($_.aggr_Peak_Area -ne 1) -and ($_.aggr_Peak_Area -ne "NaN") -and ($_.aggr_Peak_Area -ne 0)}
$results = $results | ForEach-Object {if ($_.decoy -eq 'False') {$_.decoy = '0'} else {$_.decoy = '1'} $_}
$results = $results | ForEach-Object {if ($_.aggr_Fragment_Annotation) {$_.aggr_Fragment_Annotation = "$($_.aggr_Fragment_Annotation);"} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = "$($_.aggr_Peak_Area);"} $_}
$results = $results | Select-Object *,@{Name='peak_group_rank';Expression={'1'}}
$results | Export-Csv $OutputFilePath -Delimiter "`t" -UseQuotes Never -NoTypeInformation
