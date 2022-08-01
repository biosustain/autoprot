param([string] $mode, [string] $approach, [string] $InputDir, [string] $ExpName, [string] $SpecLib, [string] $ISpep)#, [string] $fasta)
# write checks for input variables, especially for mode (DIA or DDA) and approach (label or labelfree)


$OutputDir = Join-Path $InputDir ((Get-Date -format 'yyyyMMdd_HHmmss') + "_" + $ExpName)
$intermediate = "$OutputDir\intermediate_results"
#$DIAanalysis = "$PSScriptRoot\DIA_analysis"
#$conversions = "$PSScriptRoot\Conversions"
#$normalisation = "$PSScriptRoot\Normalisation"
#$quantification = "$PSScriptRoot\Quantification"
New-Item -ItemType Directory -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Path $intermediate | Out-Null

# DIA analysis using Spectronaut
if ($mode -eq "DIA") {
    $settings = "$PSScriptRoot\pipeline_settings.prop"
    $fileType = ".*\.raw"
    $SNargsList = "-d $InputDir -a $SpecLib -s $settings -o $intermediate -n $ExpName -f $fileType"
    Start-Process -FilePath spectronaut -ArgumentList $SNargsList -Wait
    $SNoutputDir = (Get-ChildItem -Path $intermediate -Filter ("*" + $ExpName) -Recurse -Directory).Fullname
    $oldSNreport = Join-Path $SNoutputDir ($ExpName + "_Report_pipeline_report (Normal).xls")
    $SNreport = Join-Path $intermediate ($ExpName + "_SNreport.tsv")
    Copy-Item -Path $oldSNreport -Destination $SNreport
    $samples = Import-Csv $SNreport -Delimiter "`t" | Select-Object -ExpandProperty run_id -Unique
    if ($approach -eq "labelfree") {$INreport = $SNreport}
}

# DIA analysis using DIA-NN


# Conversion of DDA results in PeptideGroups (.CSV) format
if ($mode -eq "DDA") {
    & "$PSScriptRoot\DDAconversion.ps1" -InputFilePath $DDA -name $ExpName -OutputDirPath $intermediate
    $PDreport = Join-Path $intermediate ($ExpName + "_PDreport.tsv")
    $samples = Import-Csv $PDreport -Delimiter "`t" | Select-Object -ExpandProperty run_id -Unique
    if ($approach -eq "labelfree") {$INreport = $PDreport}
}

# IS extraction for label approach
if ($approach -eq "label") {
    if ($mode -eq "DIA") {
        $report = $SNreport
    }
    elseif ($mode -eq "DDA") {
        $report = $PDreport
    }

    & "$PSScriptRoot\ISextraction.ps1" -InputFilePath $report -ISpepFilePath $ISpep -name $ExpName -samples $samples -OutputDirPath $intermediate
    $ISreport = Join-Path $intermediate ($ExpName + "_ISpep_int.csv")
    $NLreport = Join-Path $intermediate ($ExpName + "_NL.csv")
    $INreport = $NLreport
}

# Normalisation using Top3, Topall, iBAQ, APEX, NSAF, xTop or LFAQ


