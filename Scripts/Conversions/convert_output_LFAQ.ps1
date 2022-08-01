param([string] $InputFilesPath, [string] $name, [string[]] $samples)
$OutputFilePath = Join-Path $DirPath ($name + "_prot_int_LFAQ.csv")
foreach ($sam in $samples) {
	$res = Import-Csv (Join-Path $InputFilesPath ("ProteinResults_" + $sam + ".txt")) -Delimiter "`t"
	$res = $res | Group-Object "Protein IDs" | ForEach-Object {
		$entries = $_.Group
		[PSCustomObject]@{
			run_id        = $sam
			protein_id    = $entries[0]."Protein IDs"
			response_LFAQ = $entries[0].LFAQ
		}
	}
	$res | Export-Csv $OutputFilePath -Delimiter "," -UseQuotes Never -NoTypeInformation -Append
}
