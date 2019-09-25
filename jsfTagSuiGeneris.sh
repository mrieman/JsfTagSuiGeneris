#!/bin/bash

#######################
# 
# This script recursively traverses through xhtml files and adds a JSF passthrough variable
# to allow all tags to have a uniquely identifiable attribute
#
# Debug[addJsfPassAttribute2file]: . . Old tag: <h:outputLabel for="input1234" value="This Cool Feild" />
# Debug[addJsfPassAttribute2file]: . . New tag: <h:outputLabel pass:mytag="myProject_x_108" for="input1234" value="This Cool Feild" />
#
#######################

projectName="myProject"
jsfPassPrefix="${projectName}_x";
counter=0;
tagRegex="(<(p\:|h\:|${projectName}\:|f\:)[a-zA-Z0-9]* )((?!pass:${projectName}tag=)[^>])+>";
headerString="xmlns:pass=\"http:\/\/xmlns.jcp.org\/jsf\/passthrough\" ";
jsfPassString="pass\:${projectName}tag=\"${jsfPassPrefix}";
replaceHeaderRegex="${headerString}";
replacejsfPassAttRegex="\1${jsfPassString}_${counter}\" \3";
logfile="jsfTagSuiGenerisLog.log";
regexExcChar="\\&\\:\\;\\^\\$\\.\\|\\?\\*\\+\\(\\)\\{\\}\\\"\\/\\\\";
filecount=1;
numberOfXhtmlFiles=0;
spinnerCount=-1;
debugEnabled=false;
scanPath="$PWD"

while test $# -gt 0
do
   case "$1" in
      -d | --directory ) # Directory to scan
         scanPath="$2";  ;;
      -p | --prefix ) # Prefix added to value
         jsfPassPrefix="$2"; ;;
      -l | --log ) # log file name
         logfile="$2"; ;;
      --help )
         show_usage;
         exit 1;
         ;;
      -v | --verbose ) 
         debugEnabled=true; ;;
   esac
   shift
done

if [ -z "$scanPath" -a "$scanPath" != " " ]; then scanPath="$(pwd)"; fi;
if [ -z "$jsfPassPrefix" -a "$jsfPassPrefix" != " " ]; then jsfPassPrefix="${projectName}_x"; fi;
if [ -z "$logfile" -a "$logfile" != " " ]; then $logfile="AddUniqueJsfPassthrough.log"; fi;

function log() {
  echo $1 >> $logfile
}

function progressSpinner() {
  spinnerCount=$((spinnerCount + 1));
  percentage=$((100*filecount/numberOfXhtmlFiles));
  case $spinnerCount in
    0) spinner=" | "; ;;
    1) spinner=" / "; ;;
    2) spinner="---"; ;;
    3) spinner=" \\ "; 
       spinnerCount=0;
       ;;
    *) spinner=" \. "; 
       spinnerCount=0;
       ;;
  esac
  echo -ne "File $filecount of $numberOfXhtmlFiles Complete: $percentage% $spinner"\\r
}

function initialize() {
  log "This is only the beginning, muahahahahah!" 
  log "   Debug: jsfPassPrefix = $jsfPassPrefix"
  log "   Debug: tagRegex = $tagRegex"
  log "   Debug: replaceHeaderRegex = $replaceHeaderRegex"
  log "   Debug: replacejsfPassAttRegex = $replacejsfPassAttRegex"
  log "   Debug: counter = $counter"
}

function addJsfPassHeader2File() {
  if grep -q $headerString "$1"; then
    log "   Debug[addJsfPassHeader2File]: nothing to do, $1 already contains $headerString" 
  else
    log "   Debug[addJsfPassHeader2File]: BEGIN $headerString to $1" 
    if $debugEnabled; then log "   Debug[addJsfPassHeader2File]: Sed command - \"0,/RE/s/(<html |<div xmlns=\"http\:\/\/www\.w3\.org\/1999\/xhtml\" )/\1${replaceHeaderRegex}/g\""; fi
    sed -r -i "0,/RE/s/(<html |<div xmlns=\"http:\/\/www\.w3\.org\/1999\/xhtml\" )/\1${replaceHeaderRegex}/g" $1
    log "   Debug[addJsfPassHeader2File]: END $headerString to $1" 
  fi
}

function addJsfPassAttribute2file() {
   log "   Debug[addJsfPassAttribute2file]:"
   log "   Debug[addJsfPassAttribute2file]: BEGIN function - for file $1"
   while grep --max-count=1 -o -P "(?s)${tagRegex}" $1 > /dev/null;
   do 
      uneditedOldtag=$(grep --max-count=1 -o -P "(?s)${tagRegex}" $1 | head -n1);
      uneditedNewtag=$(echo "$uneditedOldtag" | sed -r "s|(\W*[<a-zA-Z0-9:]+)\s(.*)|\1 ${jsfPassString}_${counter}\" \2|g")
      newtag=$(echo "$uneditedNewtag" | sed -E "s/([$regexExcChar])/\\\\\1/g" | sed -E "s/\[/\\\[/g" | sed -E "s/\]/\\\]/g" | sed -E "s/\s+/ /g")
      temptag=$(echo $uneditedOldtag | sed -E "s/([$regexExcChar])/\\\\\1/g" | sed -E "s/\[/\\\[/g" | sed -E "s/\]/\\\]/g" | sed -E "s/\s+/\\\\s+/g" ) 
      log "   Debug[addJsfPassAttribute2file]: tag found, updating"
      if $debugEnabled; then set -x; fi
      sed -r -i "0,/RE/s/$temptag/$newtag/" $1
      if $debugEnabled; then set +x; fi
      log "   Debug[addJsfPassAttribute2file]: . . Added  : ${jsfPassString}_${counter}\""
      log "   Debug[addJsfPassAttribute2file]: . . Old tag: $uneditedOldtag"
      log "   Debug[addJsfPassAttribute2file]: . . New tag: $uneditedNewtag"
      counter=$((counter + 1));
      progressSpinner
   done
   log "   Debug[addJsfPassAttribute2file]: END function"
}

function loop() { 
  for i in "$1"/*; do
    if [ -d "$i" ]; then
      loop "$i"
    elif [ -f "$i" ] && [[ "$i" =~ .*\.xhtml$ ]]; then 
      if grep -iPoz "(?s)$tagRegex" $i > /dev/null; then
         addJsfPassHeader2File $i
         addJsfPassAttribute2file $i
      fi
      filecount=$((filecount + 1));
      progressSpinner 
    fi
  done
}

set +H
initialize
filecount=1;
echo "Retrieving count of xhtml files:"
numberOfXhtmlFiles=$(grep --max-count=1 --include \*.xhtml -r --exclude-dir={.git,target} -loP "(<(p\:|h\:|${projectName}\:|f\:)[a-zA-Z0-9]* )((?!pass:${projectName}tag=)[^>])+>" | wc -l);
totalNumberOfXhtmlFiles=$(find . -name *.xhtml -not -path "*/.git/*" -not -path "*/target/*" | wc -l);
echo "  Total number files found: $totalNumberOfXhtmlFiles"
echo "  Number files needin work: $numberOfXhtmlFiles"
loop "$scanPath" 