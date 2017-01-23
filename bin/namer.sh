#! /bin/bash
 
 TF=/tmp/$$.out 
 LOGFILE=/tmp/$$.stderr
 SCANNER=/media/martin/SD_VOL/DCIM/100MEDIA/
 INBOX=./scanner-inbox
 ARCHIVE=./archive 
 ANNOTATED=./named
 PROJECT="PDF Renamer"



function finish {
   rm -f $TF $LOGFILE
   if [ "$OKULARPID" != "" ] ; then
      kill -TERM $OKULARPID
   fi
}

trap finish EXIT


function errlog { echo "$@" 1>&2; }

function from_scanner {
    if [ -e $1 ] ; then 
        errlog Reading from Scanner $1
	    rsync -av $1 $INBOX
    fi
}


function to_archive {
   if file -i $1 | grep -c image >/dev/null ;  then 
     fname=$1.pdf
     if [ $1 -nt $fname ] ; then
        convert $1 $fname >/dev/null 2>&1 
        touch -r $1 $fname
        errlog Converted $1 to $fname
     fi
   else 
     fname=$1
   fi 
   export `md5sum --tag $fname  | sed "s_MD5 (_src=_;s_) = \(.*\)_ dest=$ARCHIVE/\1.pdf_;"`
   if [ $src -nt $dest ] ; then 
      cp -p $src $dest
      errlog Copied $src to $dest
   fi
}


function annotate {
   test -e "$1" || return 10 
   F=`find $ARCHIVE -samefile $1 | tail -1`
   test -e "$F" || (errlog "$F \# not found"; return 10)
   okular --noraise --unique $F 2>/dev/null &
   if [ "$OKULARWINDOW" = "" ] ; then
    export OKULARPID=`ps ax | grep okular | sed -n '1s/^\([0-9]*\).*/\1/p'`
    export OKULARWINDOW=`xdotool search --name okular | tail -1`
    echo OKULAR: PID $OKULARPID Window $OKULARWINDOW
   fi 
   annotatedfile=`find $ANNOTATED -samefile $F | tail -1`
   annotation=`echo $annotatedfile | sed "s_$ANNOTATED/__;s_\.pdf__g" `
   dialog  --title "$F - new filename" \
           --backtitle "$TITLE" \
           --cancel-label "Beenden" \
           --inputbox "'label:' or 'YYYYMMDD_000.00_comment'" 8 90 "$annotation" 2>$TF 
   retval=$?
   if [ "$retval" == "0" ] ; then 
       edited=`cat $TF`
       if [ "$edited" != "" -a "$edited" != "$annotation" ] ; then
            bn=`basename $F`
            newannotated=`echo $ANNOTATED/$edited.pdf | sed "s/ /_/g;s_\(/[^:]*:\)\(.*\)_\1${bn}_"`
            ln $F $newannotated
            touchdate $newannotated
            if [ "$annotatedfile" != "" -a -f "$annotatedfile" ] ; then
                    rm $annotatedfile
                    errlog $F \# from $annotatedfile to $newannotated
            else 
                    errlog $F \# to $newannotated
            fi 
       fi 
  else 
    errlog "aborted on prompt"
    return $retval 
  fi

}

function touchdate {
    command=`echo $1 | sed  "s_\([^ ]*/\([2-9][0-9][0-9][0-9][0-1][0-9]\)00\)_touch -t \2011111 \1_;t; \
                            s_\([^ ]*/\([2-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]\)\)_touch -t \21111 \1_;t; \
                            s_\(.*\)_echo No Date found in \1_ 
    "` 
    $command 
    #echo $command
    #echo -n "Break? " 
    #read -n 1 response

}

function ask {
#dialog --title "Inputbox - To take input from you" \
#    --backtitle "Linux Shell Script Tutorial Example" \
#    --inputbox "Enter your name " 8 60 2>$TF

# dialog --inputbox "Enter your name:" 8 40 2>answer
# dialog  --form text 8 40  60 10 neu 1 1 item 1 10 0 0

dialog --title "Inputbox - To take input from you" \
       --backtitle "Linux Shell Script Tutorial Example" \
       --form "Enter your name " \
			15 80 0 \
        "field1: "              1 1 "$user"             1 25 40 0 \
        "field2:"               2 1 "$shell"            2 25 40 0 \
        "field3:"               3 1 "$groups"           3 25 40 0 \
        "field4:"               4 1 "$home"             4 25 40 0 \
2>$TF


if [ -e $TF ] ; then 
    echo a ist $(cat $TF)
fi 

}



# Starts here 


if [ "$*" == "" ] ; then
    glob=`find $ARCHIVE -type f -links 1`
    export TITLE="$PROJECT - Naming unnamed files"
elif [ "$1" == "all" ] ; then 
    glob=`find $ARCHIVE -type f`
    export TITLE="$PROJECT - Naming all files"
else 
    glob="$*"
    export TITLE="$PROJECT - Naming files from arguments"
fi

echo $TITLE >>$LOGFILE

echo Checking new arrivals.
from_scanner $SCANNER 2>>$LOGFILE
for A in `ls $INBOX/*` ; do
    to_archive $A  2>>$LOGFILE
done


for A in $glob ; do 
    annotate $A 2>>$LOGFILE || break
done
echo Done:
NOWFILE=$(date +%Y%m%d%H%M.log) 
mv $LOGFILE $NOWFILE
cat $NOWFILE
