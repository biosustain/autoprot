param(
    [Parameter(Mandatory=$true)][string] $mode,
    [Parameter(Mandatory=$true)][string] $approach,
    [Parameter(Mandatory=$true)][string] $InputDir,
    [Parameter(Mandatory=$true)][string] $ExpName,
    [Parameter(Mandatory=$true)][string] $fasta,
    [Parameter(Mandatory=$true)][string] $totalProt,
    [string] $SpecLib,
    [string] $ISpep
)

$ErrorActionPreference = 'Stop'
if ($mode -ne "DDA" -and $mode -ne "DIA") {
    Write-Error -Message "-approach must be either `"DDA`" or `"DIA`""
}
if ($approach -ne "label" -and $approach -ne "labelfree" -and $approach -ne "UPS2") {
    Write-Error -Message "-mode must be either `"label`", `"labelfree`" or `"UPS2`""
}
if ($mode -eq "DIA") {
    if (!$SpecLib) {Write-Error -Message "File with spectral library is required"}
}
if ($approach -eq "label" -or $approach -eq "UPS2") {
    if (!$ISpep) {Write-Error -Message "File with IS concentrations is required"}
}

$OutputDir = Join-Path $InputDir ((Get-Date -format 'yyyyMMdd_HHmmss') + "_" + $ExpName + "_" + $mode + "_" + $approach)
$intermediate = "$OutputDir\intermediate_results"
$DIAanalysis = "$PSScriptRoot\DIA_analysis"
$conversions = "$PSScriptRoot\Conversions"
$normalisation = "$PSScriptRoot\Normalisation"
$quantification = "$PSScriptRoot\Quantification"
New-Item -ItemType Directory -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Path $intermediate | Out-Null

## DIA analysis using Spectronaut
if ($mode -eq "DIA") {
    $settings = "$DIAanalysis\pipeline_settings.prop"
    $fileType = ".*\.raw"
    $SNargsList = "-d $InputDir -a $SpecLib -s $settings -o $intermediate -n $ExpName -f $fileType"
    Start-Process -FilePath spectronaut -ArgumentList $SNargsList -Wait
    $SNoutputDir = (Get-ChildItem -Path $intermediate -Filter ("*" + $ExpName) -Recurse -Directory).Fullname
    $SNreport = Join-Path $intermediate ($ExpName + "_SNreport.tsv")
    Import-Csv $SNreport -Delimiter "`t" | Where-Object {$_.aggr_Peak_Area -ne "NaN"} | Export-Csv $SNreport -Delimiter "`t" -UseQuotes Never -NoTypeInformation
    Copy-Item -Path (Join-Path $SNoutputDir ($ExpName + "_Report_pipeline_report (Normal).xls")) -Destination $SNreport
    $samples = Import-Csv $SNreport -Delimiter "`t" | Select-Object -ExpandProperty run_id -Unique
    if ($approach -eq "labelfree") {$INreport = $SNreport}
}

## DIA analysis using DIA-NN


## Conversion of DDA results in PeptideGroups (.CSV) format
if ($mode -eq "DDA") {
    & "$conversions\DDAconversion.ps1" -InputFilePath $DDA -name $ExpName -OutputDirPath $intermediate
    $PDreport = Join-Path $intermediate ($ExpName + "_PDreport.tsv")
    $samples = Import-Csv $PDreport -Delimiter "`t" | Select-Object -ExpandProperty run_id -Unique
    if ($approach -eq "labelfree") {$INreport = $PDreport}
}

## IS extraction for label approach
if ($approach -eq "label") {
    if ($mode -eq "DIA") {
        $report = $SNreport
    }
    elseif ($mode -eq "DDA") {
        $report = $PDreport
    }

    & "$conversions\ISextraction.ps1" -InputFilePath $report -ISpepFilePath $ISpep -name $ExpName -samples $samples -OutputDirPath $intermediate
    $ISreport = Join-Path $intermediate ($ExpName + "_ISpep_int.csv")
    $NLreport = Join-Path $intermediate ($ExpName + "_NL.tsv")
    $INreport = $NLreport
}

## Normalisation using Top3, Topall, iBAQ, APEX, NSAF, xTop or LFAQ
$methods = "top","all","iBAQ","APEX","NSAF","LFAQ","xTop"

## using aLFQ - R package
& "$conversions\Report_to_OpenSWATH.ps1" -InputFilePath $INreport -name $ExpName -OutputDirPath $intermediate
$aLFQrscript = "$normalisation\PeptoProtInference.R"
$aLFQargsList = "$aLFQrscript $intermediate $ExpName $fasta"
Start-Process -FilePath Rscript -ArgumentList $aLFQargsList -Wait

## using xTop - Python package
& "$conversions\Report_to_xTopinput.ps1" -InputFilePath $INreport -name $ExpName -samples $samples -OutputDirPath $intermediate
$xTopInput = $ExpName + "_xTop.csv"
$xTopPYscript = Join-Path ($env:Path -split ";" | Where-Object {$_ -match "xtop"}) "xTop_pipeline.py"
$xTopargsList = "`"$xTopPYscript`" $xTopInput"
Start-Process -FilePath python -ArgumentList $xTopargsList -WorkingDirectory $intermediate -Wait
$xTopOutputDir = (Get-ChildItem -Path $intermediate -Filter "*export" -Recurse -Directory).Fullname
Copy-Item -LiteralPath (Join-Path $xTopOutputDir ("[" + $xTopInput + "] Intensity xTop.csv")) -Destination (Join-Path $intermediate ($ExpName + "_prot_int_xTop.csv"))

## using LFAQ - C++ executables and LFAQ.py wrapper
$LFAQintermediate = "$intermediate\LFAQintermediate"
New-Item -ItemType Directory -Path $LFAQintermediate | Out-Null
& "$conversions\convert_input_LFAQ.ps1" -InputFilePath $INreport -name $ExpName -samples $samples -OutputDirPath $LFAQintermediate
$LFAQPYscript = "$normalisation\lfaq.py"
$LFAQexe = $env:Path -split ";" | Where-Object {$_ -match "LFAQ"}
$randomConcFile = "$normalisation\randomConcFile.csv"
foreach ($sam in $samples) {
    $samFile = Join-Path $LFAQintermediate ($ExpName + "_" + $sam + ".csv")
    $LFAQargsList = "$LFAQPYscript $samFile $fasta $LFAQintermediate `"$LFAQexe`" --IdentificationFileType `"PeakView`" --IdentifierOfStandardProtein `"P`" --StandardProteinsFilePath $randomConcFile"
    Start-Process -FilePath python -ArgumentList $LFAQargsList -Wait
    Rename-Item -Path "$LFAQintermediate\ProteinResultsExperimentOnlyOne.txt" -NewName ("ProteinResults_" + $sam + ".txt")
}
& "$conversions\convert_output_LFAQ.ps1" -InputFilesPath $LFAQintermediate -name $ExpName -samples $samples
Copy-Item -Path (Join-Path $LFAQintermediate ($ExpName + "_prot_int_LFAQ.csv")) -Destination (Join-Path $intermediate ($ExpName + "_prot_int_LFAQ.csv"))

## Absolute quantification using label or label-free approach
$AQPYscript = "$quantification\AbsQuant.py"
if ($approach -eq "label") {
    $AQargsList = "$AQPYscript --label `"label`" --name $ExpName --inDir $intermediate --sam $samples --met $methods --tot $totalProt --Sint $ISreport --Sconc $ISpep"
}
elseif ($approach -eq "labelfree") {
    $AQargsList = "$AQPYscript --label `"unlabel`" --name $ExpName --inDir $intermediate --sam $samples --met $methods --tot $totalProt --fasta $fasta"
}
Start-Process -FilePath python -ArgumentList $AQargsList -Wait
$AQoutputDir = "$intermediate\Absolute_quantification"
foreach ($m in $methods) {
    $outputFileName = $ExpName + "_prot_conc_" + $m + ".csv"
    Copy-Item -Path (Join-Path $AQoutputDir $outputFileName) -Destination (Join-Path $OutputDir $outputFileName)
}
