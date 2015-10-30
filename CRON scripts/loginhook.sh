#!/bin/bash

########################################################################## loginhook_p2.sh
# dskincaid | dsk@mit.edu               
# Copyright 2003, 2004, 2005, 2006, 2007, 2012 MIT
# MIT School of Architecture and Planning
##########################################################################################
# spawned by loginhook.sh (copied from /cron/.../loginhook_p1.sh)
# gets afs tokens, create user dir on local partitions, build handy symbolic links
# scope: macathena : public, fac, staff
##########################################################################################
# dskincaid :: 042106 : rewritten for bash
# dskincaid :: 042306 : turn off spotlight on /Volumes/backups so backups
# 						of fac, staff macs are not indexed
# dskincaid :: 071806 : will set sticky bit on local partitions and leave restrictive permissions.
#					  : as result, root must create folder and user need store user's stuff in own folder on same
# dskincaid :: 072407 : create user dirs on all partitions but boot
#					  : if exists partition named 'backups' then assumed for backups
# dskincaid :: 062112 : owing to mysterious credentials caching at login, another aklog is executed by LaunchAgent/login.sh
#					  : add user to /Groups/_developer if not already member
#					  : create /Users/MacAthena/$1 to redirect ~/Library components during LaunchAgent/login.sh
#					  : disabled mdutil on /afs
# dskincaid :: 063012 : disabled spotlight indexing on all sym links back to AFS (not sure this helps, but 20 minute
#					  : lockups seen at times when indexing and user logs in. suspect some mdimporter is mucking with AFS files
#					  : iMovie Events/Projects.localized symlinks are created for all volumes (required by iMovie 11)
# dskincaid :: 052513 : container assignment now handled through /Library/MacAthena/ID/containerID_*
# dskincaid :: 062213 : 802.1X now disabled in loginhook_p2.sh in effort to disable earlier in login sequence (had been disabled in login.sh)
# dskincaid :: 012513 : cupsenable all queues in event some are paused ro otherwise bolloxed.
##########################################################################################

copyFiles () 
	{
	# recursive search for files then mkdir and cp.
	for item in $(ls "$1"/"$2"| grep -v DS_Store)
	do
		if [ -d "$1"/"$2"/"$item" ]
		then
			copyFiles "$1"/"$2" "$item"
		else
			configPath="$1"/"$2"
			if [ "${item##*.}" = "sh" ]
			then # script. run it.
				"$configPath"/"$item"
				if [ $? -eq 0 ]
				then
					echo Script Status: OK : "$configPath"/"$item" >> /Library/MacAthena/${configPkg}_${cont##*/}_customconfig_sys.txt
				else
					echo Script Status: : FAILED: "$configPath"/"$item" >> /Library/MacAthena/${configPkg}_${cont##*/}_customconfig_sys.txt
				fi
			else
				mkdir -p /"${configPath##/*$configPkg/}"
				cp -vf "$1"/"$2"/"$item" /"${configPath##/*$configPkg/}/" >> /Library/MacAthena/${configPkg}_${cont##*/}_customconfig_sys.txt
			fi
		fi
	done
	unset IFS
	}
	
updateConfigSys ()
	{
	# make customizations to /. package named 99999999 will always install
	IFS="
	"
	configPathRoot="/afs/.athena.mit.edu/dept/cron/system/macathena/core/configuration_sys"
	for configPkg in $(ls "$configPathRoot")
	do
		if ! [ -e /Library/MacAthena/${configPkg}_customconfig_sys.txt ] || [ $configPkg = 99999999 ]
		then
			copyFiles "$configPathRoot" "$configPkg"
		fi
	done
	unset IFS
	}

updateLaunchAgentsDaemonsCore ()
	{
	# refresh core LaunchAgent/LaunchDaemon plists
	for daemonType in LaunchAgents LaunchDaemons
	do
		for plistFull in $(ls /afs/.athena.mit.edu/dept/cron/system/macathena/core/$daemonType/plists/*.plist)
		do
			plist=${plistFull##/*/}
 			if [ ! -e /Library/$daemonType/$plist ] || [ /afs/.athena.mit.edu/dept/cron/system/macathena/core/$daemonType/plists/$plist -nt /Library/$daemonType/$plist ]
 			then
 				echo "Installing /Library/$daemonType/$plist"
 				launchctl unload /Library/$daemonType/$plist 2>/dev/null
 				cp /afs/.athena.mit.edu/dept/cron/system/macathena/core/$daemonType/plists/$plist /Library/$daemonType
 				chown root /Library/$daemonType/$plist
 				chgrp wheel /Library/$daemonType/$plist
 				chmod 644 /Library/$daemonType/$plist
 				echo "Enabling /Library/$daemonType/$plist"
 				launchctl load /Library/$daemonType/$plist
 			fi
 		done
 	done
 	}
 
updateLaunchAgentsDaemonsContainer ()
	{
	# refresh container LaunchAgent/LaunchDaemon plists
	for daemonType in LaunchAgents LaunchDaemons
	do
		for plistFull in $(ls /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/$daemonType/plists/*.plist 2>/dev/null)
		do
			plist=${plistFull##/*/}
 			if [ ! -e /Library/$daemonType/$plist ] || [ /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/$daemonType/plists/$plist -nt /Library/$daemonType/$plist ]
 			then
 				echo "Installing /Library/$daemonType/$plist"
 				launchctl unload /Library/$daemonType/$plist 2>/dev/null
 				cp /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/$daemonType/plists/$plist /Library/$daemonType
 				chown root /Library/$daemonType/$plist
 				chgrp wheel /Library/$daemonType/$plist
 				chmod 644 /Library/$daemonType/$plist
 				echo "Enabling /Library/$daemonType/$plist"
 				launchctl load /Library/$daemonType/$plist
 			fi
 		done
	done
	}	

mountsConfig ()
	{
	# unmount WinAthena if -e
	[ -d /Volumes/WinAthena ] && echo "Unmount WinAthena:" `diskutil unmount /Volumes/WinAthena`

	# set spotlight off on selected volumes
	#mdutil -i off -v "/afs"
	[ -d /Volumes/backups ] && echo -e 'Spotlight' `mdutil -i off -v /Volumes/backups | tr -d '\n\t'`
	
	# create user dirs on stock volumes
	for vol in backups scratch
	do
		if [ -d /Volumes/"$vol" ] 
		then
			echo "Preparing /Volumes/${vol}/$1"
			if [ ! -d /Volumes/"$vol"/"$1" ]
			then
				mkdir /Volumes/"$vol"/"$1"
    		fi
    		
    		# ensure permissions are correct (eg. following HD replacement)
    		chmod 750 /Volumes/"$vol"/"$1"
   		 	chown "$1" /Volumes/"$vol"/"$1"
    		
    		# create symlinks to these
    		/bin/ln -sfh /Volumes/"$vol"/"$1" /a.local."$vol"
    		# place warning file (locked)
    		chflags nouchg /Volumes/"$vol"/"$1"/WARNING_READ_ME_NOW.txt
    		if [ "$vol" = scratch ]
    		then
    			echo "TEMPORARY STORAGE ONLY! All files stored in this folder may be deleted without warning. Backup your data!" > /Volumes/"$vol"/"$1"/WARNING_READ_ME_NOW.txt
    		elif [ "$vol" = backups ]
    		then
    			echo "FOR CRON BACKUPS ONLY! DO NOT USE! To restore a file/folder from backups, please contact cron@mit.edu." > /Volumes/"$vol"/"$1"/WARNING_READ_ME_NOW.txt
    		fi
    		chflags uchg /Volumes/"$vol"/"$1"/WARNING_READ_ME_NOW.txt
    		
    		# touch to reset the modification clock (of relevance to LaunchDaemon edu.mit.core_purge_dir)
       	 	touch /Volumes/"$vol"/"$1"
    	fi
    done
	}

usersDirPrep ()
	{
	# set up local dirs for MacAthena Lion
	echo "Preparing /Users/MacAthena/$1"
	if ! [ -d /Users/MacAthena/"$1" ]
	then
		echo "Creating /Users/MacAthena/$1"
		mkdir -p /Users/MacAthena/"$1"
		chown admin /Users/MacAthena
		chgrp wheel /Users/MacAthena
		chmod 755 /Users/MacAthena
		chown -R "$1" /Users/MacAthena/"$1"
		chgrp -R staff /Users/MacAthena/"$1"
		chmod -R 755 /Users/MacAthena/"$1"
	fi
	touch /Users/MacAthena
	chflags hidden /Users/MacAthena
	
	# symlinks
	/bin/ln -sfh "$macathenaHome" /Users/"$1"
    /bin/ln -sfh "$macathenaHome" /afs."$1".macdata
    #though user may be macathena, his home might still be local (soa, smentrek et al)
    #/bin/ln -sfh "$HOME" /Users/"$1"
    #/bin/ln -sfh "$HOME" /afs."$1".macdata
	
	# leave warning in /Users/Shared
	chflags nouchg /Volumes/MacAthena/Users/Shared/WARNING_READ_ME_NOW.txt
    echo "TEMPORARY STORAGE ONLY! All files stored in this folder may be deleted without warning!" > /Volumes/MacAthena/Users/Shared/WARNING_READ_ME_NOW.txt
    chflags uchg /Volumes/MacAthena/Users/Shared/WARNING_READ_ME_NOW.txt
	}

deadusersPrep ()
	{
	if [ ! -d /tmp/deadusers ]
	then
		mkdir -p /tmp/deadusers
	else
		rm -f /tmp/deadusers/*
	fi
	chown "$1" /tmp/deadusers
	chmod 755 /tmp/deadusers
	}
	
updateSymlinkedApps ()
	{
	for app in CertAid _SOS _cronAdobePrefReset _cronResetDock _cronPurgeTrash _cronCheckQuota _cronMountDFS
	do
		rm -rf /Applications/${app}*
		ln -sf /afs/.athena.mit.edu/dept/cron/system/macathena/core/Applications/$app/${app}.app /Applications/$app
	done
	}

iMoviePrep ()
	{
	#STILL THE CASE!?!?!?!?!?!!
	#create symlink for iMovie 11 : no control over which vol iMovie will try writing iMovie Projects to... (!)
	if [ -d /Volumes/scratch ]
	then
		for vol in `ls /Volumes | grep -v "MacAthena" | grep -v ".DS_Store"`
		do
			ln -sfh /Volumes/scratch/$1/Movies/iMovie\ Projects.localized /Volumes/"$vol"/iMovie\ Projects.localized
			ln -sfh /Volumes/scratch/$1/Movies/iMovie\ Events.localized /Volumes/"$vol"/iMovie\ Events.localized
		done
	fi
	}
	
#################################################################################### BEGIN

echo "[+] : loginhook_p2.sh" `date '+[ %H:%M:%S ]'`

# set permissions on log file so (user) launchagent and launchdaemon standardout can write to /var/log/macathena.log
for f in macathena.log macathena_purge.log
do
	[ -f /var/log/$f ] || [ $(touch /var/log/$f) ]
	chmod 666 /var/log/$f
done

#set variables
os_version=`sw_vers -productVersion`

# determine computer's container
if [ -f /Library/MacAthena/ID/containerID_* ]
then
	container=`echo $(ls /Library/MacAthena/ID/containerID_*) | awk -F_ '{print $NF}' | sed 's/-/\//g'`
else
	# make best guess and create
	case ${HOSTNAME%%.*} in
 		act* )
			container="act" ;;
		cronm* )
 			container="cronmw" ;;
 		lib* )
 			container="lib" ;;
 		oeit-01* )
 			container="oeit/01" ;;
 		oeit-260* )
 			container="oeit/260" ;;
 		oeit-261* )
 			container="oeit/261" ;;
 		oeit-37* )
 			container="oeit/37" ;;
        *plazma* )
        	container="plazma" ;;
        w20* )
        	container="ist" ;;
       	pulkovo* )
        	container="atic" ;;
 		* )
 			container="archdusp";;
	esac
	containerID="/Library/MacAthena/ID/containerID_"`echo $container | sed 's/\//-/g'`
	touch $containerID
	chflags uchg $containerID
fi

echo Container: $container

# enable all printer queues
cupsenable $(lpstat -p | grep disabled | cut -d " " -f 2)

# update loginwindow Security Banner
if [ /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/Security/PolicyBanner.rtfd -nt /Library/Security/PolicyBanner.rtfd ]
then
	echo "Updating LoginWindow Security Banner"
	cp -R /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/Security/PolicyBanner.rtfd /Library/Security/ 2>/dev/null
fi

# set up ticket/token visor directory for LaunchDaemon
deadusersPrep

# update symlinked apps
updateSymlinkedApps

# refresh core LaunchAgent/LaunchDaemon plists
updateLaunchAgentsDaemonsCore

# refresh container LaunchAgent/LaunchDaemon plists
updateLaunchAgentsDaemonsContainer
	
# refresh other system configuration
updateConfigSys

# unmount WinAthena, manage spotlight indexing etc.
mountsConfig "$1"

# add user to _developer (Xcode requirement)
[ $(dscl . -read /Groups/_developer | grep -c $1) = 1 ] || [ `dscl . append /Groups/_developer GroupMembership $1` ]

# tokens, 802.1x, source container-specific loginhook
macathenaHome=`dscl /LDAPv3/ldap-too.mit.edu -read /Users/"$1" NFSHomeDirectory 2>/dev/null | awk '{print $NF}'`
if [ `echo $macathenaHome | grep -c athena.mit.edu` != 1 ] #problem accessing record. try ldap.mit.edu.
then
	macathenaHome=`dscl /LDAPv3/ldap.mit.edu -read /Users/"$1" NFSHomeDirectory 2>/dev/null | awk '{print $NF}'`
fi

if [ `echo $macathenaHome | grep -c athena.mit.edu` = 1 ]
then
	# get tokens (note: owing to mysterious credentials caching at loginwindow, another aklog is executed by LaunchAgent)
	`su "$1" -c /usr/bin/'aklog -cell athena.mit.edu'`
	
	usersDirPrep "$1"

    #iMoviePrep
	
	#  disable 802.1X autoconnect for user. This will suppress eapolcontrol prompts if eapolclient were ever re-enabled (see loginhook_1)
	echo "Disabling 802.1X autoconnect ($1)"
	su - "$1" -c "defaults -currentHost write com.apple.network.eapolcontrol EthernetAutoConnect -bool false"
	
	# source container-specific loginhook script if specified
	if [ -f /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/LoginHook/loginhook_"${container##*/}".sh ]
	then
		echo "Sourcing > loginhook_"${container##*/}.sh
		source /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/LoginHook/loginhook_"${container##*/}".sh
	else
		echo "No container loginhook script to run."
	fi
else
    #  disable 802.1X autoconnect for user. This will suppress eapolcontrol prompts if eapolclient were ever re-enabled (see loginhook_1)
    echo "Disabling 802.1X autoconnect ($1)"
    su - "$1" -c "defaults -currentHost write com.apple.network.eapolcontrol EthernetAutoConnect -bool false"
fi

echo "[-] : loginhook_p2.sh" `date '+[ %H:%M:%S ]'`

return 0