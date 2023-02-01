param([string] $InputFilePath, [string] $name, [string[]] $samples, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath ($name + "_PDreport.tsv")
$results = Import-Csv $InputFilePath -Delimiter ","
$OrgSamples = $results[0].psobject.Properties.Name -match "Abundances"
foreach ($sam in $OrgSamples) {
    $res = $results | ForEach-Object {
        $seq = $_."Annotated Sequence"
        $seq = $seq.SubString($seq.IndexOf(".") + 1, $seq.LastIndexOf(".") - $seq.IndexOf(".") - 1)
        $mod = $_."Modifications"
        if ($mod) {
            if ($mod -match "13C") {
                $aFA = "_"+$seq+"[Arg6][Lys6]_.2"
            }
            else {
                $mod = $mod.SubString($mod.IndexOf("x") + 1, $mod.IndexOf(" ") - $mod.IndexOf("x") - 1)
                $aFA = "_"+$seq+"["+$mod+"]_.2"
            }
        }
        [PSCustomObject]@{
            run_id                   = $samples[$OrgSamples.IndexOf($sam)]
            ProteinName              = $_."Master Protein Accessions"
            FullPeptideName          = $seq
            Sequence                 = $seq
            decoy                    = "False"
            m_score                  = $_."Qvality q-value"
            Charge                   = 2
            aggr_Fragment_Annotation = $aFA
            aggr_Peak_Area           = $_.$sam
        }
    }
    $res = $res | Where-Object {$_.aggr_Peak_Area}
    $res | Export-Csv $OutputFilePath -Delimiter "`t" -UseQuotes Never -NoTypeInformation -Append
}
