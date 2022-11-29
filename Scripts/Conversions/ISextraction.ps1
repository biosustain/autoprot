param([string] $InputFilePath, [string] $ISpepFilePath, [string] $name, [string[]] $samples, [string] $OutputDirPath)
$OutputFilePathIS = Join-Path $OutputDirPath ($name + "_ISpep_int.csv")
$OutputFilePathReport = Join-Path $OutputDirPath ($name + "_NL.tsv")
$results = Import-Csv $InputFilePath -Delimiter "`t"
$ISpep   = Import-Csv $ISpepFilePath -Delimiter ","
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$results = $results | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$results = $results | Where-Object {($_.aggr_Peak_Area -ne 1) -and ($_.aggr_Peak_Area -ne "NaN") -and ($_.aggr_Peak_Area -ne 0)}
$results = $results | Where-Object {[double] $_.m_score -lt 0.01}
$results = $results | ForEach-Object {if ($_.m_score) {$_.m_score = $_.m_score -replace ",","."} $_}
$objectTemp = New-Object -TypeName PSObject
$objectTemp | Add-Member -MemberType NoteProperty -Name FullPeptideName -Value ""
$objectTemp | Add-Member -MemberType NoteProperty -Name ProteinName -Value ""
foreach ($sam in $samples) {
	$objectTemp | Add-Member -MemberType NoteProperty -Name $sam -Value ""
}
$objectTemp | Add-Member -MemberType NoteProperty -Name labelled -Value ""
$ISint = $results | Where-Object {($_.aggr_Fragment_Annotation -Match "Arg6") -or ($_.aggr_Fragment_Annotation -Match "Lys6")}
$ISint = $ISint | Where-Object {$_.decoy -eq "False"}
$ISint = $ISpep | ForEach-Object{
    $pep = $_.FullPeptideName
    $match = $ISint | Where-Object {$_.FullPeptideName -eq $pep}
    if ($match) {
        foreach ($m in $match) {
            $m
        }
    }
}
$ISint = $ISint | Group-Object FullPeptideName, run_id | ForEach-Object{
    $entries = $_.Group
    [PSCustomObject]@{
        run_id          = $entries[0].run_id
        FullPeptideName = $entries[0].FullPeptideName
        ProteinName     = $entries[0].ProteinName
        aggr_Peak_Area  = ($entries | Measure-Object aggr_Peak_Area -Sum).Sum
    }
}
$ISint = $ISint | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$ISint = $ISint | Group-Object FullPeptideName | ForEach-Object{
    $entries = $_.Group
    $objectCur = $objectTemp.PSobject.Copy()
    $objectCur.FullPeptideName = $entries[0].FullPeptideName
    $objectCur.ProteinName     = $entries[0].ProteinName
    foreach ($sam in $samples) {
        $objectCur.$sam        = ($entries | Where-Object run_id -eq $sam).aggr_Peak_Area
    }
    $objectCur.labelled        = "yes"
    $objectCur
}
$results = $results | Where-Object {($_.aggr_Fragment_Annotation -NotMatch "Arg6") -and ($_.aggr_Fragment_Annotation -NotMatch "Lys6")}
$lightint = $ISint | ForEach-Object{
    $pep = $_.FullPeptideName
    $match = $results | Where-Object {$_.FullPeptideName -eq $pep}
    if ($match) {
        foreach ($m in $match) {
            $m
        }
    }
}
$lightint = $lightint | Where-Object {$_.decoy -eq "False"}
$lightint = $lightint | Group-Object FullPeptideName, run_id | ForEach-Object{
    $entries = $_.Group
    [PSCustomObject]@{
        run_id          = $entries[0].run_id
        FullPeptideName = $entries[0].FullPeptideName
        ProteinName     = $entries[0].ProteinName
        aggr_Peak_Area  = ($entries | Measure-Object aggr_Peak_Area -Sum).Sum
    }
}
$lightint = $lightint | ForEach-Object {if ($_.aggr_Peak_Area) {$_.aggr_Peak_Area = $_.aggr_Peak_Area -replace ",","."} $_}
$lightint = $lightint | Group-Object FullPeptideName | ForEach-Object{
    $entries = $_.Group
    $objectCur = $objectTemp.PSobject.Copy()
    $objectCur.FullPeptideName = $entries[0].FullPeptideName
    $objectCur.ProteinName     = $entries[0].ProteinName
    foreach ($sam in $samples) {
        $objectCur.$sam        = ($entries | Where-Object run_id -eq $sam).aggr_Peak_Area
    }
    $objectCur.labelled        = "no"
    $objectCur
}
$ISint | Export-Csv $OutputFilePathIS -Delimiter "," -UseQuotes Never -NoTypeInformation
$lightint | Export-Csv $OutputFilePathIS -Delimiter "," -UseQuotes Never -NoTypeInformation -Append
$results | Export-Csv $OutputFilePathReport -Delimiter "`t" -UseQuotes Never -NoTypeInformation
