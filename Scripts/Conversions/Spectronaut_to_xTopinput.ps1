param([string] $InputFilePath, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath "Report_xTop.csv"
$results = Import-Csv $InputFilePath -Delimiter "`t"
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$results = $results | Where-Object {$_.decoy -eq "False"}
$results = $results | Where-Object {$_.aggr_Peak_Area -ne 1}
$results = $results | Where-Object {[double] $_.m_score -lt 0.01}
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$results = $results | Group-Object FullPeptideName, run_id | ForEach-Object {
	$entries = $_.Group
	[pscustomobject]@{
		FullPeptideName = $entries[0].FullPeptideName
		ProteinName     = $entries[0].ProteinName
		run_id          = $entries[0].run_id
		aggr_Peak_Area  = ($entries | Measure-Object aggr_Peak_Area -Sum).Sum
	}
}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$samples = $results | Select-Object -ExpandProperty run_id -Unique
$objectTemp = New-Object -TypeName PSObject
$objectTemp | Add-Member -MemberType NoteProperty -Name FullPeptideName -Value ""
$objectTemp | Add-Member -MemberType NoteProperty -Name ProteinName -Value ""
foreach ($sam in $samples) {
	$objectTemp | Add-Member -MemberType NoteProperty -Name $sam -Value ""
}
$results = $results | Group-Object FullPeptideName | ForEach-Object {
	$entries = $_.Group
	$objectCur = $objectTemp.PSObject.Copy()
	$objectCur.FullPeptideName = $entries[0].FullPeptideName
	$objectCur.ProteinName     = $entries[0].ProteinName
	foreach ($sam in $samples) {
		$objectCur.$sam        = ($entries | Where-Object run_id -eq $sam).aggr_Peak_Area
	}
	$count = 0
	foreach ($prop in $objectCur.PSObject.Properties) {if ($prop.Value) {$count++}}
	if ($count -ge 5) {$objectCur}
}
$results | Export-Csv $OutputFilePath -Delimiter "," -UseQuotes Never -NoTypeInformation
