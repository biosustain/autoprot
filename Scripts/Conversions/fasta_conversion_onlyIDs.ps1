param([string] $InputFilePath, [string] $fastaName, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath ($fastaName + "_onlyIDs.fasta")
$Sequences = Get-Content -Path $InputFilePath
$Sequences = $Sequences | ForEach-Object {
    if ($_ -match "^>") {
        $ID = $_.SubString($_.IndexOf("|") + 1, $_.IndexOf("|",$_.IndexOf("|") + 1) - $_.IndexOf("|") - 1)
        ">" + $ID
    }
    else {
        $_
    }
}
Set-Content -Path $OutputFilePath -Value $Sequences
