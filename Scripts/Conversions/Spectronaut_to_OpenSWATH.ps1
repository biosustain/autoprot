param([string] $InputFilePath, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath "Report_OpenSWATH.tsv"
$results = Import-Csv $InputFilePath -Delimiter "`t"
$results = $results | Where-Object {($_.aggr_Fragment_Annotation -NotMatch "Arg6") -and ($_.aggr_Fragment_Annotation -NotMatch "Lys6")}
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$results = $results | ForEach-Object {if ($_.decoy -eq 'False') {$_.decoy = '0'} else {$_.decoy = '1'} $_}
$results = $results | ForEach-Object {if ($_.aggr_Fragment_Annotation) {$_.aggr_Fragment_Annotation = "$($_.aggr_Fragment_Annotation);"} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = "$($_.aggr_Peak_Area);"} $_}
$results = $results | Select-Object *,@{Name='peak_group_rank';Expression={'1'}}
$results | Export-Csv $OutputFilePath -Delimiter "`t" -UseQuotes Never -NoTypeInformation
