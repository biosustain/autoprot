
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

The *autoprot* pipeline allows for absolute quantification of proteins from raw mass spectrometry (MS) files in an automated manner.
The pipeline covers data analysis from both DIA and DDA methods, where a fully open-source option is available for DIA methods.
Raw data from labelled, label-free and standard-free approaches can be analysed with the pipeline.
The normalisation of peptide intensities into protein intensities is performed with seven different algorithms to identify the optimal algorithm for the current experiment.
The incorporated algorithms are Top3 (`Silva et al., 2006 <https://www.sciencedirect.com/science/article/pii/S1535947620315127>`_),
Top all (`Silva et al., 2006 <https://www.sciencedirect.com/science/article/pii/S1535947620315127>`_),
iBAQ (`Schwanhausser et al., 2011 <https://www.nature.com/articles/nature10098>`_),
APEX (`Lu et al., 2007 <https://www.nature.com/articles/nbt1270>`_),
NSAF (`Zybailov et al., 2006 <https://pubs.acs.org/doi/full/10.1021/pr060161n>`_),
LFAQ (`Chang et al., 2019 <https://pubs.acs.org/doi/full/10.1021/acs.analchem.8b03267>`_),
and xTop (`Mori et al., 2021 <https://www.embopress.org/doi/full/10.15252/msb.20209536>`_).

Install
=======

The required files can be downloaded from this GitHub repository with the following command:

::

    git clone git@github.com:biosustain/autoprot.git

Due to the many available options, the *autoprot* pipeline depends on a number of different software and packages.
A list of all dependencies and their corresponding, tested version is provided below.
The ``autoprot.ps1`` script and multiple other scripts or executables have to be added to the PATH variable for the *autoprot* pipeline to work properly.
While file paths can be added to the PATH variable through the `command line <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.2>`_,
on Windows one can also add to the PATH variable through the `graphical user interface <https://docs.oracle.com/en/database/oracle/machine-learning/oml4r/1.5.1/oread/creating-and-modifying-environment-variables-on-windows.html#GUID-DD6F9982-60D5-48F6-8270-A27EC53807D0>`_ (GUI).

To test if the *autoprot* pipeline is set up properly, the files in ``Examples\Input`` can be used in combination with `raw MS files <https://www.ebi.ac.uk/pride/archive/projects/PXD043377>`_ of the standard-free DIA analysis (place the 9 .raw files in the ``Examples\Input`` folder first) for a test run with the following command:

::
    
    autoprot.ps1 -osDIA -mode "directDIA" -approach "free" -InputDir "$PSScriptRoot\..\Examples\Input" -ExpName "test_run" -fasta "$PSScriptRoot\..\Examples\Input\URF_UP000000625_E_coli.fasta" -totalProt "$PSScriptRoot\..\Examples\Input\CPD_example.csv"

The output files can be verified with the files in ``Examples\Output``.

Dependencies
^^^^^^^^^^^^

=================== ====================== ============
Name                Version                Source
=================== ====================== ============
PowerShell 7        7.2.4                  https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2#installing-the-msi-package (Windows operating system has PowerShell 5.1 as default, however PowerShell 7.2 (or higher) is required alongside the default, so that additional functions can be accessed. The whole pipeline runs on 7.2 or up.)
Python              3.8.8 (or higher)      https://www.anaconda.com/ (Including numpy==1.20.1, pandas==1.2.4, statsmodels==0.12.2, matplotlib==3.3.4, Biopython==1.78. Add location of python.exe to PATH variable.)
Spectronaut         17 (17.3.230224.55965) https://biognosys.com/software/spectronaut/ (Commercially available. Add location of spectronaut.exe to PATH variable.)
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

To access the *autoprot* help from the command line in PowerShell 7:

::

    Get-Help autoprot.ps1 -Full

When the ``autoprot.ps1`` script is located on a drive with restricted access, e.g. a network drive, and cannot be executed, the following command can provide access to execute the script:

::

    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

The available arguments are:

-osDIA           [flag] enables the open-source option for DIA analysis, which uses DIA-NN instead of Spectronaut.
-mode            [string] **mandatory** specify the acquisition mode as "DDA", "DIA" or "directDIA".
-approach        [string] **mandatory** specify the quantification approach as "label", "unlabel" or "free".
-InputDir        [directory] **mandatory** specify the input directory containing all input files with raw MS spectra. The output directory will be located in the input directory after the run.
-ExpName         [string] **mandatory** specify the name of the experiment.
-fasta           [file] **mandatory** specify the FASTA file with the proteome sequences.
-totalProt       [file] **mandatory** specify the file with the cellular protein density values for each sample.
-DDAresultsFile  [file] (mandatory for "DDA" mode) specify the file with the Proteome Discoverer Peptide Groups results.
-SpecLib         [file] (mandatory for "DIA" mode) specify the file with the spectral library for the "DIA" mode.
-BGSfasta        [file] (mandatory for "directDIA" mode with Spectronaut) specify the FASTA file in .BGSfasta format, which is required for the "directDIA" mode using Spectronaut (commercial).
-ISconc          [file] (mandatory for "label" and "unlabel" approaches) specify the file with the absolute concentrations of each standard peptide ("label" approach) or protein ("unlabel" approach).

Specific input data
===================

Ensure that the FASTA file with the proteome sequences follows the official UniProt configuration for the headers. An example FASTA file can be found in ``Examples\Input\URF_UP000000625_E_coli.fasta``.

All workflows in ``DIA`` and ``directDIA`` mode can be initialised from .RAW files (Thermo Fisher Scientific instrument specific - please open an issue if another type is required in combination with Spectronaut)
using either `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland)
or `DIA-NN <https://github.com/vdemichev/DiaNN>`_ (open source; `Demichev et al., 2019 <https://www.nature.com/articles/s41592-019-0638-x>`_).
Any workflow in ``DDA`` mode can be initialised from the ``PeptideGroups.csv`` output file of `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_ (Thermo Fisher Scientific, Waltham, MA, USA).
How to get the ``PeptideGroups.csv`` file with `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_ results:
Open the .PDRESULTS file of the study in `Proteome Discoverer <https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html>`_,
click on "File" -> "Export" -> "To Microsoft Excel", select "Peptide Groups" from the drop-down menu for level 1 and click on "Export".
Open the resulting file in Microsoft Excel and save as a .CSV file with the name ``PeptideGroups``.

For a workflow in ``directDIA`` mode using `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland),
a BGSfasta version of the fasta file is required. This BGSfasta version can be obtained by loading the fasta file with the proteome sequences in `Spectronaut <https://biognosys.com/software/spectronaut/>`_ (commercial; Biognosys AG, Schlieren, Switzerland)
as a protein database. Then, the BGSfasta version of the fasta file should be in the folder ``$HOME\Databases\Spectronaut\``.

The *autoprot* pipeline has two custom input files which are described below.

Cellular protein density
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The table with cellular protein density for each sample should have the following headers: ``Sample`` [string] with the name of each sample which should be the same as the names of the .RAW files and
``CPD`` [float] with the cellular protein density of each sample in g/L. An example file for the cellular protein density table can be found in ``Examples\Input\CPD_example.csv``.

======= =======
Sample  CPD    
======= =======
sample1 <float>
sample2 <float>
...     ...    
======= =======

Internal standard concentration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For the ``label`` approach, the table with the concentration for each internal standard should be peptide-based (for example AQUA or QconCAT peptides) with the following headers:
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

For the ``unlabel`` approach, the table with the concentration for each internal standard should be protein-based (for example UPS2 protein mix) with the following headers:
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
``invivo_conc(mM)_X`` [float] with the intracellular protein concentration in sample X in mM (millimol/liter) for each sample.
Example files for the protein-based results table can be found in the ``Examples\Output`` folder.

=========== ====================== ================= ===
ProteinName sample_conc(fmol/µg)_X invivo_conc(mM)_X ...
=========== ====================== ================= ===
UniProt ID1 <float>                <float>           ...
UniProt ID2 <float>                <float>           ...
...         ...                    ...               ...
=========== ====================== ================= ===

Intermediate files
^^^^^^^^^^^^^^^^^^

All intermediate output files of the *autoprot* pipeline will be located in ``intermediate_results`` in the output directory.
Of particular interest, the linear regression plots of the proteome absolute quantification for the ``labelled`` or ``unlabel`` approach will be located in ``intermediate_results\Absolute_quantification\LR_plots``.

Analysis settings
=================

Currently, only 13C(6) labelling of arginine (Arg6) and lysine (Lys6) residues is allowed for the ``label`` approach, which are incorporated into the DIA analysis settings of the ``directDIA`` mode.
However, the ``label`` approach is peptide-based, thus both methods using AQUA peptides or QconCAT proteins are supported.
The ``unlabel`` approach is protein-based and allows for any protein to be used as internal standard, e.g. UPS2 protein kit. 

The DIA analysis settings for both Spectronaut and DIA-NN include quantification on MS2 level.
Specifically for the ``directDIA`` mode, the DIA analysis settings include the Trypsin/P cleavage rule (digestion with Trypsin/Lys-C mix) and the following modifications: Carbamidomehtyl (C), Acetyl (Protein N-term), and Oxidation (M).
The exact settings can be found in the corresponding DIA analysis settings file in ``Scripts\DIA_analysis``.
DIA-NN uses config files which can be viewed using any text editor, while Spectronaut uses property files which can be viewed by importing the file into Spectronaut in the Settings tab.

Copyright
=========

* Copyright (c) 2023, Novo Nordisk Foundation Center for Biosustainability, Technical University of Denmark.
* Free software distributed under the `GNU General Public License 3.0 <https://www.gnu.org/licenses/>`_
