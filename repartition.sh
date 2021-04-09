#!/sbin/sh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Universal repartitioner for the 7870, V1.0
# Written by @Astrako
#

# New partitions size in Mb. These values are the recommended. Feel free to mod them according your needs
SYSTEMSIZE=4096
VENDORSIZE=512
CACHESIZE=64
#############

ODMSIZE=128 # New ODM partition size for those devices having it. Mod this value at your own risk

SGDISK=/sbin/sgdisk
DISK=/dev/block/mmcblk0

CP_DEBUG=`$SGDISK --print $DISK | grep CP_DEBUG | awk '{printf $1}'`
HIDDEN=`$SGDISK --print $DISK | grep HIDDEN | awk '{printf $1}'`
NAD_FW=`$SGDISK --print $DISK | grep NAD_FW | awk '{printf $1}'`
NAD_REFER=`$SGDISK --print $DISK | grep NAD_REFER | awk '{printf $1}'`
ODM=`$SGDISK --print $DISK | grep ODM | awk '{printf $1}'`
OMR=`$SGDISK --print $DISK | grep OMR | awk '{printf $1}'`
VENDOR=`$SGDISK --print $DISK | grep VENDOR | awk '{printf $1}'`

DISKCODE=`$SGDISK --print $DISK | grep SYSTEM | awk '{printf $6}'`
SECSIZE=`$SGDISK --print $DISK | grep 'sector size' | awk '{printf $4}'`

function delete() {
	# Delete partitions
	$SGDISK --delete=$1 $DISK
	
}

function calculate() {
	# Get SYSTEM partition number and delete it
	SYSPART=`$SGDISK --print $DISK | grep SYSTEM | awk '{printf $1}'`
	delete $SYSPART

	# Get VENDOR partition number and delete it, if exists
	if [ ! -z $VENDOR ]; then	
		VENDORPART=`$SGDISK --print $DISK | grep VENDOR | awk '{printf $1}'`
		delete $VENDORPART
	fi

	# Get CACHE partition number and delete it
	CACHEPART=`$SGDISK --print $DISK | grep CACHE | awk '{printf $1}'`
	delete $CACHEPART
	
	# Get ODM partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $ODM ]; then	
		ODMPART=`$SGDISK --print $DISK | grep ODM | awk '{printf $1}'`
		if [ $ODMPART -gt $SYSPART ]; then
			delete $ODMPART
		fi
	fi
	
	# Get HIDDEN partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $HIDDEN ]; then
		HIDDENPART=`$SGDISK --print $DISK | grep HIDDEN | awk '{printf $1}'`
		if [ $HIDDENPART -gt $SYSPART ]; then
			delete $HIDDENPART
		fi
	fi
	
	# Get OMR partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $OMR ]; then
		OMRPART=`$SGDISK --print $DISK | grep OMR | awk '{printf $1}'`
		if [ $OMRPART -gt $SYSPART ]; then
			OMRSIZE=`$SGDISK --print $DISK | grep OMR | awk '{printf $4 $5}' | sed 's/\.[0-9]*//g'`
			delete $OMRPART
		fi
	fi
	
	# Get CP_DEBUG partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $CP_DEBUG ]; then	
		CPDPART=`$SGDISK --print $DISK | grep CP_DEBUG | awk '{printf $1}'`
		if [ $CPDPART -gt $SYSPART ]; then
			CPDSIZE=`$SGDISK --print $DISK | grep CP_DEBUG | awk '{printf $4 $5}' | sed 's/\.[0-9]*//g'`
			delete $CPDPART
		fi
	fi
	
	# Get NAD_FW partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $NAD_FW ]; then
		NADFWPART=`$SGDISK --print $DISK | grep NAD_FW | awk '{printf $1}'`
		if [ $NADFWPART -gt $SYSPART ]; then
			NADFWSIZE=`$SGDISK --print $DISK | grep NAD_FW | awk '{printf $4 $5}' | sed 's/\.[0-9]*//g'`
			delete $NADFWPART
		fi
	fi
	
	# Get NAD_REFER partition number and delete it, if exists and is located after SYSTEM
	if [ ! -z $NAD_REFER ]; then
		NADRFPART=`$SGDISK --print $DISK | grep NAD_REFER | awk '{printf $1}'`
		if [ $NADRFPART -gt $SYSPART ]; then
			NADRFSIZE=`$SGDISK --print $DISK | grep NAD_REFER | awk '{printf $4 $5}' | sed 's/\.[0-9]*//g'`
			delete $NADRFPART
		fi
	fi
	
	# Get USERDATA partition number and delete it
	DATAPART=`$SGDISK --print $DISK | grep USERDATA | awk '{printf $1}'`
	delete $DATAPART
}
	
function repart() {	
	# SYSTEM repartition
	$SGDISK --new=0:0:+${SYSTEMSIZE}Mib --typecode=0:$DISKCODE --change-name=0:SYSTEM $DISK

	# VENDOR repartition
	$SGDISK --new=0:0:+${VENDORSIZE}Mib --typecode=0:$DISKCODE --change-name=0:VENDOR $DISK
	
	# CACHE repartition
	$SGDISK --new=0:0:+${CACHESIZE}Mib --typecode=0:$DISKCODE --change-name=0:CACHE $DISK
	
	# ODM repartition if exist and is located after SYSTEM partition
	if [ ! -z $ODM ] && [ $ODMPART -gt $SYSPART ]; then
		$SGDISK --new=0:0:+${ODMSIZE}Mib --typecode=0:$DISKCODE --change-name=0:ODM $DISK
	fi

	# OMR repartition if exist and is located after SYSTEM partition
	if [ ! -z $OMR ] && [ $OMRPART -gt $SYSPART ]; then
		$SGDISK --new=0:0:+$OMRSIZE --typecode=0:$DISKCODE --change-name=0:OMR $DISK
	fi	
		
	# CP_DEBUG repartition if exist and is located after SYSTEM partition
	if [ ! -z $CP_DEBUG ] && [ $CPDPART -gt $SYSPART ]; then
		$SGDISK --new=0:0:+$CPDSIZE --typecode=0:$DISKCODE --change-name=0:CP_DEBUG $DISK
	fi

	# NAD_FW repartition if exist and is located after SYSTEM partition
	if [ ! -z $NAD_FW ] && [ $NADFWPART -gt $SYSPART ]; then
		$SGDISK --new=0:0:+$NADFWSIZE --typecode=0:$DISKCODE --change-name=0:NAD_FW $DISK
	fi	
	
	# NAD_REFER repartition if exist and is located after SYSTEM partition
	if [ ! -z $NAD_REFER ] && [ $NADRFPART -gt $SYSPART ]; then
		$SGDISK --new=0:0:+$NADRFSIZE --typecode=0:$DISKCODE --change-name=0:NAD_REFER $DISK
	fi
	
	#USERDATA repartition
	$SGDISK --new=0:0:0 --typecode=0:$DISKCODE --change-name=0:USERDATA $DISK
	
}

# main
calculate
repart
