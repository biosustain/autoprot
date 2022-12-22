param([string] $InputFilePath, [string] $OutputDirPath)
$results = Import-Csv $InputFilePath -Delimiter "`t" | Select-Object -ExpandProperty ProteinName -Unique
$counter = 150
$protIDs = $results | Get-Random -Count $counter
$concs = Get-Random -Minimum 1.2345678 -Maximum 1234.5678 -Count $counter
$randomConcFile = for ($i = 0; $i -lt $counter; $i++) {
    [PSCustomObject]@{
        "Protein Id" = $protIDs[$i]
        "Amounts"    = $concs[$i]
    }
}
$randomConcFile = $randomConcFile | ForEach-Object {if ($_.Amounts) {$_.Amounts = $_.Amounts -replace ",","."} $_}
$randomConcFile | Export-Csv (Join-Path $OutputDirPath ("randomConcFile.csv")) -Delimiter "`t" -UseQuotes Never -NoTypeInformation