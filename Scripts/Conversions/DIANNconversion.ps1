param([string] $InputFilePath, [string] $name, [string] $OutputDirPath)
$OutputFilePath = Join-Path $OutputDirPath ($name + "DIANNreport.tsv")
$results = Import-Csv $InputFilePath -Delimiter "`t"

$results = $results | ForEach-Object {
    $id = $_."Precursor.Id"
    $seq = $_."Stripped.Sequence"
    $charge = $_."Precursor.Charge"
    if ($id -match "SILAC-R-H") {
        $aFA = "_"+$seq+"[Arg6]_."+$charge
    }
    elseif ($id -match "SILAC-K-H") {
        $aFA = "_"+$seq+"[Lys6]_."+$charge
    }
    elseif ($id -match "UniMod") {
        $mod = $id.SubString($id.IndexOf(":") - 6, 9)
        $aFA = "_"+$seq+"["+$mod+"]_."+$charge
    }
    else {
        $mod = 0
        $aFA = "_"+$seq+"_."+$charge
    }
    [PSCustomObject]@{
        run_id                   = $_."Run"
        ProteinName              = $_."Protein.Ids"
        FullPeptideName          = $seq
        Sequence                 = $seq
        decoy                    = "False"
        m_score                  = $_."Q.Value"
        Charge                   = $charge
        aggr_Fragment_Annotation = $aFA
        aggr_Peak_Area           = $_."Precursor.Translated"
    }
}
$results | Export-Csv $OutputFilePath -Delimiter "`t" -UseQuotes Never -NoTypeInformation
