UTL=chain
SRC=manuscript
DST=article
ART=`{ls -d manuscript/*.org | sed 's/manuscript\/\([^/.]*\)\..*$/\1/'}

default:V: publish validate

$DST/([^/.]+)\.html:RD: $SRC/\\1.org
 emacs --batch --load $UTL/web.el $prereq\
       --eval '(progn (outline-show-all)
                      (font-lock-flush)
                      (font-lock-fontify-buffer)
                      (org-html-export-to-html))'\
       >>/dev/null 2>&1
 mv $SRC/$stem1.html $target

publish:V: ${ART:%=$DST/%.html}

%-valid:V: $DST/%.html
 wtidy -quiet -modify $prereq

validate:V: ${ART:%=%-valid}