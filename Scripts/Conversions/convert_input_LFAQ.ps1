param([string] $InputFilePath, [string] $name, [string[]] $samples, [string] $OutputDirPath)
$results = Import-Csv $InputFilePath -Delimiter "`t"
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$results = $results | ForEach-Object {if (!$_.ProteinName) {$_.ProteinName = "P00000"} $_}
$results = $results | Where-Object {$_.decoy -eq "False"}
$results = $results | Where-Object {($_.aggr_Peak_Area -ne 1) -and ($_.aggr_Peak_Area -ne "NaN")}
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
foreach ($sam in $samples) {
	$res = $results | Group-Object FullPeptideName | ForEach-Object {
		$entries = $_.Group
		[pscustomobject]@{
			Protein            = $entries[0].ProteinName
			Peptide            = $entries[0].FullPeptideName
			"Precursor MZ"     = 0
			"Precursor Charge" = 0
			RT                 = 0
			$sam               = ($entries | Where-Object run_id -eq $sam).aggr_Peak_Area
		}
	}
	$res | Export-Csv (Join-Path $OutputDirPath ($name + "_" + $sam + ".csv")) -Delimiter "," -UseQuotes Never -NoTypeInformation
}
