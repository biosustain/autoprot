param([string] $DirPath) #, [object] $samples)
$InputFilesPath = Join-Path $DirPath "LFAQ_intermediate"
$OutputFilePath = Join-Path $DirPath "Ec_proteins_int_LFAQ.csv"
$temp = Import-Csv F:\Data\ProtShtapa\Ec_DIA_simple_exp\Report_Ec_DIA_simple.tsv -Delimiter "`t"
$samples = $temp | Select-Object -ExpandProperty run_id -Unique
foreach ($sam in $samples) {
	$res = Import-Csv (Join-Path $InputFilesPath ("ProteinResults_" + $sam + ".txt")) -Delimiter "`t"
	$res = $res | Group-Object "Protein IDs" | ForEach-Object {
		$entries = $_.Group
		[pscustomobject]@{
			run_id        = $sam
			protein_id    = $entries[0]."Protein IDs"
			response_LFAQ = $entries[0].LFAQ
		}
	}
	$res | Export-Csv $OutputFilePath -Delimiter "," -UseQuotes Never -NoTypeInformation -Append
}
