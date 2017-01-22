SHELL := /bin/bash

.phony: archive

get-scanner :
	rsync -av /media/martin/SD_VOL/DCIM/100MEDIA/ ./scanner-inbox/

archive-pdf :
	$(shell for A in $$(md5sum ./scanner-inbox/* | sed 's_\([^ ]*\) \([^ ]*\)_test -e archive/\1.pdf || cp \2 archive/\1.pdf_' ;  do \
		echo $$A ;\
	done)

