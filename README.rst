
========
autoprot
========

.. image:: https://img.shields.io/badge/License-GPLv3-blue.svg
    :target: https://www.gnu.org/licenses/gpl-3.0
    :alt: GNU General Public License 3.0

.. image:: https://img.shields.io/badge/operating%20system-Windows-orange
    :target: https://www.microsoft.com/en-us/windows
    :alt: Windows

.. image:: https://img.shields.io/github/last-commit/biosustain/autoprot
    :target: https://github.com/biosustain/autoprot
    :alt: Last commit

|

The autoprot pipeline allows for absolute quantification of proteins from raw mass spectrometry (MS) files in an automated manner.
The pipeline covers data analysis from both DIA and DDA methods, where a fully open-source option is avalaible for DIA methods.
Raw data from labelled, label-free and standard-free approaches can be analysed with the pipeline.
The normalisation of peptide intensities into protein intensities is performed with seven different algorithms to identify the optimal algorithm for the current experiment.
The incorporated algorithms are Top3, Topall, iBAQ, APEX, NSAF, LFAQ, and xTop. 

Install
=======

The required files can be downloaded from this GitHub repository with the following command:

::

    git clone git@github.com:biosustain/autoprot.git

Due to the many available options, the autoprot pipeline depends on a number of different software and packages.
A list of all dependecies and their corresponding, tested version is provided below.
The ``autoprot.ps1`` script and multiple other scripts or executables have to be added to the PATH variable for the autoprot pipeline to work properly.
While file paths can be added to the PATH variable through the `command line <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.2>`_,
on Windows one can also add to the PATH variable through the `graphical user interface <https://docs.oracle.com/en/database/oracle/machine-learning/oml4r/1.5.1/oread/creating-and-modifying-environment-variables-on-windows.html#GUID-DD6F9982-60D5-48F6-8270-A27EC53807D0>`_ (GUI).

To test if the autoprot pipeline is set up properly for usage, the files in ``Examples\Input`` can be used for a test run with the following command:

::
    
    autoprot.ps1 -mode "directDIA" -approach "free" -InputDir "$PSScriptRoot\..\Examples\Input" -ExpName "test_run" -fasta "$PSScriptRoot\..\Examples\Input\" -totalProt "$PSScriptRoot\..\Examples\Input\" -BGSfasta "$PSScriptRoot\..\Examples\Input\"

The output files should be verified with the files in ``Examples\Output``.

Dependencies
^^^^^^^^^^^^

=================== ====================== ============
Name                Version                Source
=================== ====================== ============
PowerShell 7        7.2.4                  https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2#installing-the-msi-package (Windows operating system has PowerShell 5.1 as default, however PowerShell 7.2 (or higher) is required alongside the default, so that additional functions can be accessed. The whole pipeline runs on 7.2 or up.)
Python              3.8.8 (or higher)      https://www.anaconda.com/ (Including numpy==1.20.1, pandas==1.2.4, statsmodels==0.12.2, matplotlib==3.3.4, Biopython==1.78. Add location of python.exe to PATH variable.)
Spectronaut         16 (16.2.220903.53000) https://biognosys.com/software/spectronaut/ (Commercially available. Add location of spectronaut.exe to PATH variable.)
DIA-NN              1.8                    https://github.com/vdemichev/DiaNN (Open source.)
Proteome Discoverer 2.4.1.15               https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html (Commercially available. Not actually part of the pipeline, since no command line tool is available.)
R (Rscript)         4.1.1 (or higher)      https://cran.r-project.org/bin/windows/base/ (Add location of rscript.exe to PATH variable.)
aLFQ                1.3.5                  https://github.com/aLFQ/aLFQ (Add package to R.)
xTop                1.2                    https://gitlab.com/mm87/xtop (Add location of xTop_pipeline.py to PATH variable.)
LFAQ                1.0.0                  https://github.com/LFAQ/LFAQ (Add location of LFAQ executables to PATH variable.)
=================== ====================== ============

Usage
=====

The ``autoprot.ps1`` script can be executed in PowerShell 7 (when added to the PATH variable) as follows:

::

    autoprot.ps1 [args]

To access the autoprot help from the command line in PowerShell 7:

::

    Get-Help autoprot.ps1 -Full

When the ``autoprot.ps1`` script is located on a drive with restricted access, e.g. a network drive and is cannot be executed, the following command can provide access to execute the script:

::

    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

The available arguments are:

-mode        [string] **mandatory** specify the acquisition mode as "DDA", "DIA" or "directDIA".
-approach    [string] **mandatory** specify the quantification approach as "label", "unlabel" or "free".
-InputDir    [directory] **mandatory** specify the input directory containing all input files with raw MS spectra. The output directory will be located in the input directory after the run.
-ExpName     [string] **mandatory** specify the name of the experiment.
-fasta       [file] **mandatory** specify the FASTA file with the proteome sequences.
-totalProt   [file] **mandatory** specify the file with total protein amount for each sample. Optional to include the cell volume to be used for each sample.
-SpecLib     [file] (mandatory for "DIA" mode) specify the file with the spectral library for the "DIA" mode.
-BGSfasta    [file] (mandatory for "directDIA" mode with Spectronaut) specify the FASTA file in .BGSfasta format, which is required for the "directDIA" mode using Spectronaut (not open source).
-ISconc      [file] (mandatory for "label" and "unlabel" approaches) specify the file with the absolute concentrations of each standard peptide ("label" approach) or protein ("unlabel" approach).

Specific input data
===================

All workflows in ``DIA`` and ``directDIA`` mode can be initialised from .RAW files (Thermo Fisher Scientific instrument specific - please open an issue if another type is required)
using either `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland)
or `DIA-NN <https://github.com/vdemichev/DiaNN>`_ (open source; `Demichev et al., 2019 <https://www.nature.com/articles/s41592-019-0638-x>`_).
Any workflow in ``DDA`` mode can be initialised from the ``PeptideGroups.csv`` output file of `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_ (Thermo Fisher Scientific, Waltham, MA, USA).
How to get the ``PeptideGroups.csv`` file with `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_ results:
Open the .PDRESULTS file of the study in `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_,
click on "File" -> "Export" -> "To Microsoft Excel", select "Peptide Groups" from the drop-down menu for level 1 and click on "Export".
Open the resulting file in Microsoft Excel and save as a .CSV file with the name ``PeptideGroups``.

For a workflow in ``directDIA`` mode using `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland),
a BGSfasta version of the fasta file is required. This BGSfasta version can be obtained by loading the fasta file with the proteome sequences in `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland)
as a protein database. Then, the BGSfasta version of the fasta file can be found in the folder ``$HOME\Databases\Spectronaut\``.

The autoprot pipeline has two custom input files which are described below.

Total protein and cell volume
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The table with total protein amount for each sample should have the following headers: ``Sample`` [string] with the name of each sample which should be the same as the names of the .RAW files,
``TPA`` [float] with the total protein amount of each sample in µg/cell, ``Volume`` [float] **optional** column with specific cell volume of each sample in fL (1e-15 L).
An example file for the total protein and cell volume table can be found in ``Examples\Input\totalProt_example.csv``.

======= ======= =======
Sample  TPA     Volume
======= ======= =======
sample1 <float> <float>
sample2 <float> <float>
...     ...     ...
======= ======= =======

Internal standard concentration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For the ``labelled`` approach, the table with the concentration for each internal standard should be peptide-based (for example AQUA or QconCAT peptides) with the following headers:
``FullPeptideName`` [string] with the peptide sequence, ``ProteinName`` [string] with the UniProt identifier of the corresponding protein (should be identical to the identifiers in the fasta file with the proteome sequences),
``Concentration`` [float] with the spiked-in concentration of each internal standard peptide into the sample in fmol/µg whole cell lysate (total protein extracted).
An example file for the peptide-based internal standard concentration table can be found in ``Examples\Input\ISconc_peptides_example.csv``.

=============== =========== =============
FullPeptideName ProteinName Concentration
=============== =========== =============
sequence1       UniProt ID1 <float>
sequence2       UniProt ID2 <float>
...             ...         ...
=============== =========== =============

For the ``unlabel`` approach, the table with the concentration for each internal standard should be protein-based (for example UPS2 protein kit) with the following headers:
``ProteinName`` [string] with the UniProt identifier of the corresponding protein (should be identical to the identifiers in the fasta file with the proteome sequences),
``Concentration`` [float] with the spiked-in concentration of each internal standard peptide into the sample in fmol/µg whole cell lysate (total protein extracted).
An example file for the peptide-based internal standard concentration table can be found in ``Examples\Input\ISconc_proteins_example.csv``.

=========== =============
ProteinName Concentration
=========== =============
UniProt ID1 <float>
UniProt ID2 <float>
...         ...
=========== =============

Output data
===========

The output directory will be located in the input directory after the run and will contain seven files with a protein concentration table, one for each algorithm.
The protein concentration table has the following headers: ``ProteinName`` [string] with the UniProt identifier of the corresponding protein (identical to the identifiers in the fasta file with the proteome sequences),
``sample_conc(fmol/µg)_X`` [float] with the protein concentration in sample X in fmol/µg whole cell lysate (total protein extracted) for each sample,
``invivo_conc(mM)_X`` [float] with the *in vivo* protein concentration in sample X in mM (millimol/liter) for each sample.
An example file for the peptide-based internal standard concentration table can be found in ``Examples\Output\Example_prot_conc_alg.csv``.

=========== ====================== ================= ===
ProteinName sample_conc(fmol/µg)_X invivo_conc(mM)_X ...
=========== ====================== ================= ===
UniProt ID1 <float>                <float>           ...
UniProt ID2 <float>                <float>           ...
...         ...                    ...               ...
=========== ====================== ================= ===

Intermediate files
^^^^^^^^^^^^^^^^^^

All intermediate output files of the autoprot pipeline will be located in ``intermediate_results`` in the output directory.
In particular interest, the linear regression plots of the proteome absolute quantification for the ``labelled`` or ``unlabel`` approach will be located in ``intermediate_results\Absolute_quantification\LR_plots``.

Copyright
=========

* Copyright (c) 2022, Novo Nordisk Foundation Center for Biosustainability, Technical University of Denmark.
* Free software distributed under the `GNU General Public License 3.0 <https://www.gnu.org/licenses/>`_
