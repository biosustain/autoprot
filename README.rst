
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

Install
=======

Installation

Dependencies
^^^^^^^^^^^^

=================== ====================== ============
Name                Version                Source
=================== ====================== ============
PowerShell 7        7.2.4                  https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2#installing-the-msi-package (Windows operating system has PowerShell 5.1 as default, however PowerShell 7.2 (or higher) is required alongside the default, so that additional functions can be accessed. The whole pipeline runs on 7.2 or up.)
Python              3.8.8 (or higher)      https://www.anaconda.com/ (Including argparse, numpy, pandas, statsmodels.api, matplotlib.pyplot, Biopython. Add location of python.exe to PATH variable.)
Spectronaut         16 (16.2.220903.53000) https://biognosys.com/software/spectronaut/ (Commercially available. Add location of spectronaut.exe to PATH variable.)
DIA-NN              1.8                    https://github.com/vdemichev/DiaNN (Open source.)
Proteome Discoverer 2.4.1.15               https://www.thermofisher.com/dk/en/home/industrial/mass-spectrometry/liquid-chromatography-mass-spectrometry-lc-ms/lc-ms-software/multi-omics-data-analysis/proteome-discoverer-software.html (Commercially available. Not actually part of the pipeline, since no command/line tool is available.)
R (Rscript)         4.1.1 (or higher)      https://cran.r-project.org/bin/windows/base/ (Add location of rscript.exe to PATH variable.)
aLFQ                1.3.5                  https://github.com/aLFQ/aLFQ (Add package to R.)
xTop                1.2                    https://gitlab.com/mm87/xtop (Add location of xTop_pipeline.py to PATH variable.)
LFAQ                1.0.0                  https://github.com/LFAQ/LFAQ (Add location of LFAQ executables to PATH variable.)
=================== ====================== ============

Input data
==========

Input data

Usage
=====

The ``main.ps1`` script can be used in PowerShell 7 as follows:

::

    main.ps1 [commands]
    
The available commands are:

-mode        [string] **mandatory** specify the acquisition mode as "DDA", "DIA" or "directDIA".
-approach    [string] **mandatory** specify the quantification approach as "label", "unlabel" or "free".
-InputDir    [directory] **mandatory** specify the input directory containing all input files with raw MS spectra. The output directory will be located in the input directory after the run.
-ExpName     [string] **mandatory** specify the name of the experiment.
-fasta       [file] **mandatory** specify the FASTA file.
-totalProt   [file] **mandatory** specify the file with total protein amount for each sample. Optional to include the cell volume to be used for each sample
-SpecLib     [file] (mandatory for "DIA" mode) specify the file with the spectral library for the "DIA" mode.
-BGSfasta    [file] (mandatory for "directDIA" mode with Spectronaut) specify the FASTA file in .BGSfasta format, which is required for the "directDIA" mode using Spectronaut (not open-source).
-ISconc      [file] (mandatory for "label" and "unlabel" approaches) specify the file with the absolute concentrations of each standard peptide ("label" approach) or protein ("unlabel" approach).

Output data
===========

Output data


Copyright
=========

* Copyright (c) 2022, Novo Nordisk Foundation Center for Biosustainability, Technical University of Denmark.
* Free software distributed under the `GNU General Public License 3.0 <https://www.gnu.org/licenses/>`_
