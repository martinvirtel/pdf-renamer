# PDF-namer

This bash script goes through a list of PDF or image  files in an `inbox` directory, converts the images to PDF, copys them into an `archive` directory 
where they are named after their MD5 hashes. Then it interactively goes through the PDFs and allows you to give them meaningful names (creating hard links 
in a `named` directory). If the meaningful names start with year / month or year / month / day (like 20010911_report.pdf), the file date is adjusted according
to the date in the filename. If the filename start with a `label:` ending in a `:`, the rest of the filename is taken from the MD5 hash.

The directory names are defined in `bin/namer.sh`.


## Installation

The script depends on okular (the KDE PDF viewer), dialog (the bash UI) and imagemagick (to convert images into PDF)

```bash



sudo apt-get install okular dialog imagemagick

```


