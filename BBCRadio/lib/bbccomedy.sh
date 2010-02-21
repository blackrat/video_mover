#!/bin/bash
#Note: This script used the eval function to pass by reference. First parameter in most cases is the variable name. Use caution.

#GLOBAL VARIABLES - old style

#NO_ENC=echo
#DEBUG=echo

##########################################################################################
##########################################################################################
# Utility functions
#
# Date/Time manipulation, string manipulation
#
##########################################################################################
##########################################################################################

##########################################################################################
# Globals
##########################################################################################

SED=/bin/sed
GNU_DATE=/bin/date
MKDIR=/bin/mkdir

##########################################################################################
# Functions 
##########################################################################################

##########################################################################################
#Function:	set_init_value
#Description:	return the value or the default value of a parameter
#
#Requires:	
#Externals:
#Input:		$1 variable to change
#		$2 value
#		$3 default value
#Returns	Value or default value if value not set
##########################################################################################
set_init_value ()
{
local rc=$2
	
	if [ -z $2 ] ; then rc=$3 ; fi
	eval "$1=${rc}"
}
##########################################################################################

##########################################################################################
#Function:	make_dir
#Description:	Create directory tree
#
#Requires:	set_init_value
#Externals:	mkdir
#Input:		$1	directory tree to create
#Returns:	none
##########################################################################################
make_dir ()
{
local makedir
set_init_value makedir ${MKDIR} "/bin/mkdir"

	if [ ! -d $1 ] ; then
		${makedir} -p $1 >> ${g_debug_log}
	fi
}
##########################################################################################

##########################################################################################
#Function:	get_datestamp
#Description:	Returned the date specified by a particular offset
#
#Requires:	set_init_value
#Externals:	GNU date
#Input:		$1 variable name for datestame
#		$2 offset
##########################################################################################
get_datestamp()
{
local datestamp=""
local date

set_init_value date ${GNU_DATE} "/bin/date"

	if [ -x ${date} ] ; then
		datestamp=`${date} --date="$2 days" +%Y%m%d`
	else
		echo FATAL: get_datestamp reports ${date} "(Gnu Date)" is missing or not executable.
		exit 1
	fi
	eval "$1=${datestamp}"
}
##########################################################################################

##########################################################################################
#Function:	get_tv_anytime_datestamp
#Description:	Returned the date specified by a particular offset in the format used
#		by TV_Anytime
#
#Requires:	set_init_value
#Externals:	GNU date
#Input:		$1 variable name for datestame
#		$2 offset
##########################################################################################
get_tv_anytime_datestamp()
{
local datestamp=""
local date

set_init_value date ${GNU_DATE} "/bin/date"

	if [ -x ${date} ] ; then
		datestamp=`${date} --date="$2 days" +%Y-%m-%d\T`
	else
		echo FATAL: get_datestamp reports ${date} "(Gnu Date)" is missing or not executable.
		exit 1
	fi
	eval "$1=${datestamp}"
}

##########################################################################################
#Function:	get_tv_anytime_timestamp
#Description:	Returned the time specified in the format used
#		by TV-Anytime
#
#Requires:	set_init_value
#Externals:	GNU date
#Input:		$1 variable name for datestame
#		$2 time in hhmm format
get_tv_anytime_time()
{
local timestamp=""

	timestamp=${2:0:2}":"${2:2:2}"00Z"
	eval "$1=${timestamp}"
}

##########################################################################################
#Function:	get_dow
#Description:	Returns the name of the day of the week
#
#Requires:	set_init_value
#Externals:	GNU date
#Input:		$1 variable name
#		$2 offset from current day
#Returns:	Name of the day of the week
##########################################################################################
get_dow ()
{
local dow
local date

set_init_value date ${GNU_DATE} "/bin/date"

	if [ -x ${date} ] ; then
		dow=`"${date}" --date="$2 days" +%w`
	else
		echo FATAL: get_dow reports ${date} "(Gnu Date)" is missing or not executable.
		exit 1
	fi
	case ${dow} in 
		1) dow="mon"
		;;
		2) dow="tue"
		;;
		3) dow="wed"
		;;
		4) dow="thu"
		;;
		5) dow="fri"
		;;
		6) dow="sat"
		;;
		0) dow="sun"
		;;
		*) echo "Unrecognised date:" ${dow} >> ${g_error_log}
	esac
	eval "$1=${dow}"
}
##########################################################################################

##########################################################################################
#Function:	normalize_name
#Description:	Returned the name in a "safe" format
#
#Requires:	set_init_value, normalize_description
#Externals:	sed
#Input:		$1 variable name for normalized name
#		$2 name
##########################################################################################
normalize_name ()
{
local name=$2
local sed
set_init_value sed ${SED} "/bin/sed"

	if [ -x ${sed} ] ; then
		name=`echo "$2" | ${sed} -e 's/\ /_/g'`
		normalize_description p_name ${name}
		name=${p_name}
	else
		echo ERROR: normalize_name reports ${sed} "(sed)" is missing or not executable.
	fi
	eval "$1='${name}'" 
}
##########################################################################################

##########################################################################################
#Function:	normalize_description
#Description:	Returned the description in a "safe" format
#
#Requires:	set_init_value
#Externals:	sed
#Input:		$1 variable name for normalized description
#		$2 description
##########################################################################################
normalize_description ()
{
local name=$2
local sed=""
set_init_value sed ${SED} "/bin/sed"
	
	if [ -x ${sed} ] ; then
		name=`echo "${name}" | ${sed} -e 's/\.//g'`
		name=`echo "${name}" | ${sed} -e 's/\,//g'`
		name=`echo "${name}" | ${sed} -e 's/://g'`
		name=`echo "${name}" | ${sed} -e 's/"//g'`
		name=`echo "${name}" | ${sed} -e "s/'//g"`
	else
		echo ERROR: normalize_description reports ${sed} "(sed)" is missing or not executable.
	fi
	eval "$1='${name}'" 
}
##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
#
# TV-Anytime Functions
#
# Functions for creating and manipulating the TV-Anytime grabber files
#
##########################################################################################


##########################################################################################
# Globals
##########################################################################################
TV_ANYTIME_DIR=~/.borg/TV_Anytime
WGET=/usr/bin/wget
TAR=/bin/tar

##########################################################################################
# Functions 
##########################################################################################

##########################################################################################
#Function: tv_anytime_setup
#Description:	Grabs programme listings to TV_ANYTIME directory tree for the specified day
#
#Requires:	set_init_value, make_dir 
#Externals:	wget, tar
#Input:        	$1 offset
#Returns:  	None
##########################################################################################
tv_anytime_setup()
{
local dir
local grabber
local datestamp
local curdir
local newdatestamp
local offsetcount

set_init_value dir "${TV_ANYTIME_DIR}" "~/.borg/TV_Anytime"
set_init_value grabber "${WGET}" "/usr/bin/wget"
set_init_value tar "${TAR}" "/bin/tar"

	make_dir ${dir}
	get_datestamp p_datestamp $1
	datestamp=${p_datestamp}
	offsetcount=$(( $1 -6 ))
	while [ ${offsetcount} -le $1 ]; do
		get_datestamp p_datestamp ${offsetcount}
		if [ -d ${dir}/${p_datestamp} ] ; then
			echo ${dir}/${p_datestamp} exists. Delete to refetch.
			g_tv_anywhere_datestamp=${p_datestamp}
			return 0
		else
			offsetcount=$(( ${offsetcount} +1 ))
		fi
	done
	offsetcount=$(( $1 -6 ))
	found=0
	while [ ${offsetcount} -le $1 ]; do
		get_datestamp p_datestamp ${offsetcount}
		offsetcount=$(( ${offsetcount} +1 ))
		if [ -e ${dir}/${p_datestamp}.tar.gz ] ; then
			found=${p_datestamp}
			g_tv_anywhere_datestamp=${p_datestamp}
			echo ${dir}/${p_datestamp}.tar.gz exists. Delete to refetch
		fi
	done
	echo ${found}
	echo ${datestamp}
	if [ ${found} = 0 ]; then
		if [ -x ${grabber} ] ; then
			${grabber} http://backstage.bbc.co.uk/feeds/tvradio/${datestamp}.tar.gz --output-document=${dir}/${datestamp}.tar.gz
		else
			echo ${grabber} "(wget)" is not executable or does not exist
		fi
	else
		datestamp=${found}
	fi
	if [ -e ${dir}/${datestamp}.tar.gz ] ; then
		if [ -x ${tar} ] ; then
			curdir=`pwd`
			cd ${dir}
			${tar} -zxvf ${datestamp}.tar.gz
			if [ -d xml13 ] ; then
				mv xml13 ${datestamp}
			fi
			g_tv_anywhere_datestamp=${p_datestamp}
			cd ${curdir}
		else
			echo ${tar} "(tar)" is not executable or does not exist
		fi
	fi
}
##########################################################################################

##########################################################################################
#Function:	tv_anytime_get_details
#Description:	Get Program details from tv_anytime listings
#
#Requires:	set_init_value,  normalize_name, normalize_description 
#Externals:	xmlstarlet
#Input:		$1 variable name for title
#		$2 variable name for description
#		$3 channel
#		$4 datestamp
#		$5 time
##########################################################################################
tv_anytime_get_details()
{
local dir
local xml_file
local tree
local title
local desc
local b_time
local z_time
local crid
local channel
local namespace
local xml

set_init_value dir "${TV_ANYTIME_DIR}" "~/.borg/TV_Anytime"
set_init_value xml "${XML_PARSER}" "/usr/bin/xmlstarlet"

	case $3 in
		"bbc7") channel="BBCSeven"
		;;
		"bbc_radio4") channel="BBCRFour"
		;;
		*) echo "Unrecognised channel $3" >> ${debug_log}
		;;
	esac
#	z_time=$(( $5 - 100 )) # Use this short term for British Summer Time
	z_time=$5
	b_time=${4:0:4}"-"${4:4:2}"-"${4:6:2}"T"${z_time:0:2}":"${5:2:2}":00Z"
	namespace=' -N t=urn:tva:metadata:2005 '
	xml_file=${g_tv_anywhere_datestamp}/$4${channel}_pl.xml
	tree="//t:ScheduleEvent[t:PublishedStartTime='$b_time']/t:Program"

	crid=`${xml} sel ${namespace} -T -t -m ${tree} -v "@crid" -n ${dir}/${xml_file}`
	xml_file=${g_tv_anywhere_datestamp}/$4${channel}_pi.xml
	tree="//t:ProgramInformation[@programId='${crid}']/t:BasicDescription"

	title=`${xml} sel ${namespace} -T -t -m ${tree} -v "t:Title" -n ${dir}/${xml_file}`
	desc=`${xml} sel ${namespace} -T -t -m ${tree} -v "t:Synopsis[@length='short']" -n ${dir}/${xml_file}`
	normalize_name $1 "${title}"
	normalize_description $2 "${desc}"
}
##########################################################################################

##########################################################################################
##########################################################################################
#
# Bleb Functions
#
# Functions for creating and manipulating the Bleb UK TV grabber files
#
##########################################################################################

##########################################################################################
# Globals
##########################################################################################

BLEB_DIR=~/.borg/bleb
BLEB_CONF="bleb.conf"
BLEB_GRABBER=/usr/bin/tv_grab_uk_bleb
BLEB_TREE=/tv/programme
XML_PARSER=/usr/bin/xmlstarlet

##########################################################################################
# Functions 
##########################################################################################

##########################################################################################
#Function: bleb_setup
#Description:	Grabs programme listings to bleb.xml for the specified day and channel
#
#Requires:	set_init_value, make_dir
#Externals:	tv_grab_uk_bleb
#Input:	   	$1 channel 
#          	$2 offset
#Returns:  	None
##########################################################################################
bleb_setup ()
{
local dir
local conf_file
local grabber
local xml_file=""

set_init_value dir "${BLEB_DIR}" "~/.borg/bleb"
set_init_value conf_file "${BLEB_CONF}" "bleb.conf"
set_init_value grabber "${BLEB_GRABBER}" "/usr/bin/tv_grab_uk_bleb" 

	make_dir ${dir}	
	conf_file=${dir}/${conf_file}
	xml_file=${dir}/${g_datestamp}_$1.xml

	if [ -e ${xml_file} ] ; then
		echo ${xml_file} already exists. Delete to download new file. >> ${g_debug_log}
	else
		echo $1 > ${conf_file}
		if [ -x ${grabber} ] ; then
			${grabber} --output ${xml_file} --days=1 --offset=$2 --config-file ${conf_file} 2>>${g_debug_log} 
		else
			echo ERROR: bleb_setup reports ${grabber} "(tv_grab_uk_bleb)" is missing or not executable.
		fi
	fi
}
##########################################################################################

##########################################################################################
#Function:	bleb_get_details
#Description:	Get Program details from bleb listings
#
#Requires:	set_init_value, bleb_filename, normalize_name, normalize_description 
#Externals:	xmlstarlet
#Input:		$1 variable name for title
#		$2 variable name for description
#		$3 channel
#		$4 datestamp
#		$5 time
##########################################################################################
bleb_get_details ()
{
local dir
local xml_file
local tree
local title
local desc
local b_time

set_init_value dir "${BLEB_DIR}" "~/.borg/bleb"
set_init_value tree "${BLEB_TREE}" "/tv/programme"
set_init_value xml "${XML_PARSER}" "/usr/bin/xmlstarlet"
xml_file=""
title=""
desc=""

	b_time=$4$5"00 +0100"
	xml_file=${dir}/$4_$3.xml

	title=`${xml} sel -T -t -m ${tree}[@start="'${b_time}'"] -v title -n ${xml_file}`
	desc=`${xml} sel -T -t -m ${tree}[@start="'${b_time}'"] -v desc -n ${xml_file}`

	normalize_name $1 "${title}"
	normalize_description $2 "${desc}"
}
##########################################################################################



##########################################################################################
##########################################################################################
#
# Radio Functions
#
# Functions for recording radio programmes
#
##########################################################################################

echo Define record_radio 

##########################################################################################
#Function:	record_radio
#Description:	Record radio programs from the given url to a filename detected from the programme listings. Skip if file exists or is a duplicate, or cannot be found
#
#Externals:	mplayer, lame, cat, rm
#Input:		$1 url
#		$2 datestamp
#		$3 time of recording
#		$4 channel
##########################################################################################
radio_record ()
{
check_file=""
local name
local desc
local long_name
local check_file
local recorded

	echo $2 $3 $4 >> ${g_debug_log}
	recorded=1
#	bleb_get_details p_name p_desc $4 $2 $3 
	tv_anytime_get_details p_name p_desc $4 $2 $3 
	if [ "${p_name}" = "" ] ; then
		if [ $3 = 1830 ] ; then
#			bleb_get_details p_name p_desc $4 $2 1832
			tv_anytime_get_details p_name p_desc $4 $2 1832
		fi
	fi
	if [ "${p_name}" = "" ] ; then
		name="unknown"
		desc="Unknown"
		check_file=$2_$3_$4_${name}.chk
	else
		name=${p_name}
		desc=${p_desc}
		check_file=$2_$4_${name}.chk
	fi
	echo Attempting to record ${name} >> ${g_debug_log}
	echo Description ${desc} >> ${g_debug_log}
	long_name=$2_$3_$4_${name}

	if [ -e ${g_chk}/$check_file ]; then
		desc2=`cat ${g_chk}/${check_file}` 
		if [ "${desc:0:50}" = "${desc2:0:50}" ] ; then
			echo Won\'t record ${g_mp3}/${name}/${long_name}.mp3 while ${g_chk}/${check_file} exists
			echo Won\'t record ${g_mp3}/${name}/${long_name}.mp3 while ${g_chk}/${check_file} exists >> ${g_debug_log}
		fi
  else
		if [ -e ${g_mp3}/${name}/${long_name}.mp3 ] ; then
			echo ${g_mp3}/${name}/${long_name}.mp3 already exists. Delete to rerecord. >> ${g_debug_log}
			echo ${g_mp3}/${name}/${long_name}.mp3 already exists. Delete to rerecord.
		else
			if [ -e ${g_wav}/${name}/${long_name}.wav ] ; then
				echo ${g_wav}/${name}/${long_name}.wav exists. Delete to rerecord. Will continue with mp3 encoding >> ${g_debug_log}
				echo ${g_wav}/${name}/${long_name}.wav exists. Delete to rerecord. Will continue with mp3 encoding
			else
				make_dir ${g_wav}/${name}
				${DEBUG} mplayer -prefer-ipv4 -vc null -vo null -bandwidth 99999999999 -ao pcm:fast -ao pcm:waveheader -ao pcm:file=${g_wav}/${name}/${long_name}.wav $1 
				if [ -e ${g_wav}/${name}/${long_name}.wav ] ; then
					echo ${g_wav}/${name}/${long_name}.wav recording successful. >> ${g_debug_log}
					echo ${g_wav}/${name}/${long_name}.wav recording successful. 
				else
					echo ${g_wav}/${name}/${long_name}.wav recording failed. >> ${g_debug_log}
					echo ${g_wav}/${name}/${long_name}.wav recording failed. >> ${g_error_log}
					echo ${g_wav}/${name}/${long_name}.wav recording failed.
					recorded=0
				fi
			fi
		fi
	fi
	if [ ! -e ${g_mp3}/${name}/${long_name}.mp3 ] ; then
		if [ -e ${g_wav}/${name}/${long_name}.wav ] ; then
			make_dir ${g_mp3}/${name}
			${NO_ENC} ${DEBUG} lame ${g_wav}/${name}/${long_name}.wav ${g_mp3}/${name}/${long_name}.mp3 
			${NO_ENC} ${DEBUG} rm ${g_wav}/${name}/${long_name}.wav 
			echo ${desc} > ${g_chk}/${check_file}
		fi
	fi	
	if [ -e ${g_mp3}/${name}/${long_name}.mp3 ] ; then
	  if [ ! -e ${g_mp3cd}/${name}/${long_name}_010.00_011.00.mp3 ] ; then
			make_dir ${g_mp3}/${name}
			mp3splt -f -t 1.00 -d ${g_mp3cd}/${name} ${g_mp3}/${name}/${long_name}.mp3
			echo Splitting ${name} into 1 minute pieces for audio cd
		fi
		if [ ! -e ${g_guide}/${long_name}.txt ] ; then
			make_dir ${g_guide}
			echo Adding missing guide details for ${name} to ${g_guide}/${long_name}.txt
			echo ${name} > ${g_guide}/${long_name}.txt
			echo ${desc} >> ${g_guide}/${long_name}.txt
		fi
	fi
	return ${recorded}
}

##########################################################################################

echo Define main

##########################################################################################
##########################################################################################
#	Main function
#
#	Entry point for the Record Radio Function
#
##########################################################################################

main ()
{
# Create required directories
	make_dir ${g_root}
	make_dir ${g_wav}
	make_dir ${g_mp3}
	make_dir ${g_chk}
	make_dir ${g_guide}
	make_dir ${g_mp3cd}
	cd ${g_root}

# Get Datestamp and Day of Week
	get_datestamp g_datestamp ${g_offset}
	get_dow g_dow ${g_offset}

# Setup Bleb programme listings for required channels and dates
#	bleb_setup ${g_radio4} ${g_offset} 
#	bleb_setup ${g_bbc7} ${g_offset}

# Setup TV-Anytime programme listings for required dates
	tv_anytime_setup ${g_offset}
	
	for g_time in 1830 
	do
	  recorded=0
		for g_type in comedy factual science
		do
		  if [ ${recorded} = 0 ] ; then
				g_url=rtsp://rmv8.bbc.net.uk/radio4/${g_type}/${g_dow}${g_time}.ra 
				radio_record ${g_url} ${g_datestamp} ${g_time} ${g_radio4}
				recorded=$?
			fi
		  if [ ${recorded} = 0 ] ; then
				g_url=rtsp://rmv8.bbc.net.uk/radio4/${g_type}/${g_time}_${g_dow}.ra 
				radio_record ${g_url} ${g_datestamp} ${g_time} ${g_radio4}
				recorded=$?
			fi
		done
	  if [ ${recorded} = 0 ] ; then
			g_url=rtsp://rmv8.bbc.net.uk/radio4/${g_dow}${g_time}.ra 
			radio_record ${g_url} ${g_datestamp} ${g_time} ${g_radio4}
			recorded=$?
		fi
	  if [ ${recorded} = 0 ] ; then
			g_url=rtsp://rmv8.bbc.net.uk/radio4/${g_time}_${g_dow}.ra 
			radio_record ${g_url} ${g_datestamp} ${g_time} ${g_radio4}
			recorded=$?
		fi
	done

	for g_time in 1800 1830 2200 2230 2300 2330
	do
		g_url=rtsp://rmv8.bbc.net.uk/bbc7/${g_time}_${g_dow}.ra
		radio_record ${g_url} ${g_datestamp} ${g_time} ${g_bbc7}
	done
}
##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
#
#	Real Main 
#
#	Actual entry point for the shell script
#
##########################################################################################
#GLOBAL VARIABLES - new style

set_init_value g_root ${ROOT_DIR} "/vault/med01/audio/radio"
set_init_value g_wav ${WAV_DIR} ${g_root}/"episodes"
set_init_value g_mp3 ${MP3_DIR} ${g_root}/"episodes"
set_init_value g_mp3cd ${MP3CD_DIR} ${g_root}/"mp3cd"
set_init_value g_chk ${CHK_DIR} ${g_root}/"check"
set_init_value g_guide ${GUIDE_DIR} ${g_root}/"guide"
set_init_value g_radio4 ${RADIO4} "bbc_radio4"
set_init_value g_bbc7 ${BBC7} "bbc7"
set_init_value g_error_log ${ERROR_LOG} ${g_root}/"error.log"
set_init_value g_debug_log ${DEBUG_LOG} ${g_root}/"debug.log"
set_init_value g_lock_file ${LOCK} ${g_root}/"bbccomedy.lck"

if [ ! -e "${g_lock_file}" ] ; then
	echo `date` >> ${g_error_log}
	echo `date` >> ${g_debug_log}
	echo `date` > ${g_lock_file}
	echo BBC Radio Recording Programme starting >> ${g_debug_log}
	echo BBC Radio Recording Programme starting 
	while [ -n "$1" ]; do
	set_init_value g_offset $1 -1
		main $1 
		shift
	done
	echo BBC Radio Recording Programme exiting >> ${g_debug_log}
	echo BBC Radio Recording Programme exiting
	rm ${g_lock_file}
fi
##########################################################################################

