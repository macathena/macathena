#!/bin/bash

########################################################################################## loginn.sh
# dskincaid | dsk@mit.edu | 042206          
# Copyright 2006, 2007, 2008, 2012 MIT
# MIT School of Architecture and Planning
##########################################################################################
# runs as LaunchAgent at login as part of Core MacAthena.
# copies prefs/config files as needed.
# checks user athena quota. creates useful symbolic links.
# does nothing if user root or admin.
# sources a container admin's login script (eg. 'login_ist.sh')if -e
# scope: all macathena macs : public, fac and staff
##########################################################################################
# dskincaid :: 20171123 : 10.5 (leopard) ready
# dskincaid :: 20090704 : now accommodates MacAthena updates across generations
# dskincaid :: 20090730 : change code so that local (non macathena) users get similar benefits (updates, etc)
# dskincaid :: 20110621 : ~/Caches and ~/Downloads now purged if file older than 30 days
# dskincaid :: 20120628 : mod for OS X 10.7:
#						802.1x disable 'autoenable'
#						redirect ~/Library/Caches (performance)
#						fix Microsoft Office .TemporaryItems idiocy
#						split OEIT into: 01, 04, 26, 37
# dskincaid :: 20120805 : added updateLaunchAgentsUser to allow pushing out ~/LaunchAgents
#						: added updateConfigUser, copyFiles to allow for pushing out customizations in ~
#						: these take the place of burdensome login.sh programming for customizations
#						: now one need only drop files/scripts/prefs into appropriate container and these will get deployed.
# dskincaid :: 20120808 : rewrote the way in which container specific login.sh are spawned (sourced). instead of this being set by edu.mit.core_login.plist
#						: it is computed at bottom of this script (based on hostname). this allows greater flexibility and relieves pain
#						: of having to edit edu.mit.core_login.plist entry through scripts.
# dskincaid :: 20130526 : container now specified by parsing /Library/MacAthena/ID/containerID*
# dskincaid :: 20130622 : 802.1X now disabled in loginhook_p2.sh in effort to disable earlier in login sequence
# dskincaid :: 20140709 : purging of user's Downloads, Caches, etc is now handled by separate LaunchAgent which runs every 30 min
#						: if ! -e /Volumes/scratch then symlinks directed to /Users/MacAthena/$USER
#						: tidied up code
# dskincaid :: 20140809 : setDock
##########################################################################################

notification ()
	{
		title=$1
		message=$2
		/afs/athena.mit.edu/dept/cron/system/macathena/core/scripts/support/terminal-notifier.app/Contents/MacOS/terminal-notifier -title "$title" -message "$message" -open "http://cronlasso.mit.edu/cron/p.lasso?t=7:2:1"
	}
	
uuidCalc ()
	{
	if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` == "00000000-0000-1000-8000-" ]]
	then
		uuid=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c51-62 | awk {'print tolower()'}`
	elif [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]
	then
		uuid=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
	fi
	}
	
updateByHostPrefs ()
	{
    # set $HOME/ByHosts to UUID of current machine (keep prefs constant)
    uuidCalc
	for plist in `ls "$HOME"/Library/Preferences/ByHost`
	do
		plist_new=`echo $plist | sed "s/\.[^.]*\.plist$/.$uuid.plist/"`
		mv $HOME/Library/Preferences/ByHost/$plist $HOME/Library/Preferences/ByHost/$plist_new
	done
	}

copyFiles () 
	{
	# recursive search for files then mkdir and cp.
	for item in $(ls "$1"/"$2")
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
					echo Script Status: OK : "$configPath"/"$item" >> "$HOME"/Library/MacAthena/${configPkg}_${cont##*/}_customconfig.txt
				else
					echo Script Status: : FAILED: "$configPath"/"$item" >> "$HOME"/Library/MacAthena/${configPkg}_${cont##*/}_customconfig.txt
				fi
			else
				mkdir -p "$HOME"/"${configPath##/*$configPkg/}"
				cp -vf "$1"/"$2"/"$item" "$HOME"/"${configPath##/*$configPkg/}/" >> "$HOME"/Library/MacAthena/${configPkg}_${cont##*/}_customconfig.txt
			fi
		fi
	done
	}
	
updateLaunchAgentsUser ()
	{
	# make core customizations to $HOME/LaunchAgents. Note: /Library/LaunchAgents are refreshed by loginhook_p2.sh (run with root privs)
	for daemonType in LaunchAgents
	do
		[ -d $HOME/Library/$daemonType ] || [ `mkdir -p $HOME/Library/$daemonType` ]
		for plistFull in $(ls /afs/.athena.mit.edu/dept/cron/system/macathena/core/${daemonType}User/plists/*.plist)
		do
			plist=${plistFull##/*/}
 			if [ ! -e "$HOME"/Library/$daemonType/$plist ] || [ /afs/.athena.mit.edu/dept/cron/system/macathena/core/${daemonType}User/plists/$plist -nt "$HOME"/Library/$daemonType/$plist ]
 			then
 				echo "Installing $HOME/Library/$daemonType/$plist"
 				launchctl unload "$HOME"/Library/$daemonType/$plist 2>/dev/null
 				cp /afs/.athena.mit.edu/dept/cron/system/macathena/core/${daemonType}User/plists/$plist "$HOME"/Library/$daemonType/
				chmod 644 "$HOME"/Library/$daemonType/$plist
 				echo "Enabling /Library/$daemonType/$plist"
 				launchctl load "$HOME"/Library/$daemonType/$plist
 			fi
 		done
 	done
	}
	
updateConfigUser ()
	{
	# make core and container-based customizations to $HOME. package named 99999999 will always install
	for cont in core $1
	do
		configPathRoot="/afs/.athena.mit.edu/dept/cron/system/macathena/$cont/configuration"
		for configPkg in $(ls "$configPathRoot")
		do
			if ! [ -e "$HOME"/Library/MacAthena/${configPkg}_${cont##*/}_customconfig.txt ] || [ $configPkg = 99999999 ]
			then
				osascript -e "beep"
				notification "MacAthena Updates [ $container ]" "You will be notified when ready : $configPkg"
				copyFiles "$configPathRoot" "$configPkg"
				notification "MacAthena Updates [ $container ]" "All done with update : $configPkg"
			fi
		done
 	done
	}

CertAidPrefCheck ()
	{
	# running CertAid under macathena is painful. 15-20 minutes to update identity prefs. this routine
	# removes user's existing prefs so new, truncated domain list can be built with cron template on next CertAid run.
	# assumes computer links to modified CertAid.app (which references the new template).
	if [ /afs/.athena.mit.edu/dept/cron/system/macathena/core/Applications/CertAid/cronCertAidSiteSettings.plist -nt $HOME/Library/Preferences/edu.mit.CertAid.plist ]
	then
		rm -rf $HOME/Library/Application\ Support/CertAid 2>/dev/null
		rm $HOME/Library/Preferences/edu.mit.CertAid.plist 2>/dev/null
	fi
	}

symlinksAthena ()
	{
	# symlinks to athena folders
	IFS="
	"
	ln -sfh "$athenaHome"/Public "$HOME"/afs."$USER".public
	ln -sfh "$athenaHome"/Private "$HOME"/afs."$USER".private
	ln -sfh "$athenaHome"/www "$HOME"/afs."$USER".www
	ln -sfh "$athenaHome" "$HOME"/afs."$USER"
	unset IFS
	
	# clean up any stale symlinks
	`find "$HOME" -maxdepth 1 -type l -print | perl -nle '-e || unlink'`
	}
	
symlinksVolumes ()
	{
	# symlinks to volumes
	IFS="
	"
	for partition in `ls /Volumes`
	do
		if [ -e /Volumes/"$partition"/"$USER" ] && [ "$partition" != "$bootvol" ]
		then
			/bin/ln -sfh /Volumes/"$partition"/"$USER" "$HOME"/a.local."$partition"
		fi
	done
	unset IFS
	}

symlinksLibraryItems ()
	{
	# symlinks to ~/Library stuff. required for improved performance (Caches) and functionality (Xcode, Adobe)
	msg="WARNING! FILES STORED HERE ARE REMOVED IN ACCORDANCE WITH ${container##*/} POLICY. You should set your Adobe applications preferences to store all projects and caches to your external hard drive or the scratch drive."

	[ -d /Users/MacAthena/"$USER"/Library/Preferences ] || [ `mkdir -p /Users/MacAthena/"$USER"/Library/Preferences` ]
	
	for dir in Caches Developer 'Application Support/iPhone Simulator' 'Application Support/Adobe/Common'
 	do
 		dirSUB="/${dir%/*}"
 		[ "$dirSUB" = "/${dir}" ] && dirSUB="/"
 		
 		[ -d "/Users/MacAthena/$USER/Library/$dir" ] || [ `mkdir -p "/Users/MacAthena/$USER/Library/$dir"` ]
 		[ "$dir" = 'Application Support/Adobe/Common' ] && echo "$msg" > "/Users/MacAthena/$USER/Library/$dir/WARNING_READ_ME_NOW.txt"
 		
 		if [ -d "$HOME"/Library/"$dir" ] && ! [ -h "$HOME"/Library/"$dir" ]
 		then
 			# some files can only be deleted/moved from athena session.
            echo "Removing ~/Library/$dir."
 			ssh -x athena.dialup.mit.edu "rm -rf ${athenaHome}/MacData/Library/${dir//\ /\\ }"
 		fi
        echo "Creating symlink: ~/Library/$dir -> /Users/MacAthena/$USER/Library/$dir"
 		ln -sfh /Users/MacAthena/$USER/Library/"$dir" "$HOME"/Library"$dirSUB"
 	done
 	
 	#if [ $USER = dsk ] || [ $USER = crntest ]
 	#then
 	# com.apple.sidebarlists.plist, com.apple.loginitems.plist not writeable under OX 10.9/OpenAFS 1.6.6
 	echo "plist maintenance:"
 	for pref in com.apple.sidebarlists.plist com.apple.loginitems.plist
 	do
 		prefshort=$(echo $pref | awk -F. '{print $3}')
 		if [ -h $HOME/Library/Preferences/$pref ]
 		then
 			# did not logout cleanly, restore to default
 			echo "$prefshort: need restore to default (no current setting found)."
 			if [ ! -e /Users/MacAthena/$USER/Library/Preferences/$pref ]
 			then
 				echo "$prefshort: cp from ~/Library/MacAthena/Sidebar/"
 				cp $HOME/Library/MacAthena/Sidebar/com.apple.sidebarlists.plist /Users/MacAthena/$USER/Library/Preferences/
 			fi
 		else
 			echo "$prefshort: moving to local"
 			mv $HOME/Library/Preferences/$pref /Users/MacAthena/$USER/Library/Preferences/
 		fi
		echo "$prefshort: creating symlink: ~/Library/Preferences/$pref ->/Users/MacAthena/$USER/Library/Preferences/$pref" 	
 		defaults read com.apple.sidebarlists > /dev/null 2>&1
 		ln -sfh /Users/MacAthena/$USER/Library/Preferences/$pref $HOME/Library/Preferences
 		defaults read com.apple.sidebarlists > /dev/null 2>&1
 	done
 	killall -9 Finder
 	#fi
	}

prepareUserDirs ()
	{
	# prepare 
	scratch_vol=/Volumes/$1
	msg="WARNING! FILES STORED HERE ARE REMOVED IN ACCORDANCE WITH ${container##*/} POLICY. Backup your stuff!"
	
	# some directories might not be present (first login)
	for dir in Documents Library/MacAthena/Dock .TemporaryItems
	do
		[ -d "$HOME"/"$dir" ] || [ `mkdir -p "$HOME"/"$dir"` ]
	done
	
	# A. We have $HOME/Library/Caches symlinked to /Users/MacAthena/$USER/Library/Caches for performance
 	# B. We require $HOME/Library/Caches/TemporaryItems for scanning, Adobe Apps, Outlook, inter alia (?)
 	# C. We require $HOME/Library/Caches/TemporaryItems symlinked back to $HOME/.TemporaryItems for Outlook (see 1. below)
 	# 1. Outlook requires that ~/Library/Caches/TemporaryItems exists and that it be on network drive for $HOME (hence symlink from local back to $HOME/.TemporaryItems)
 	# 2. Word requires presence of ~/Library/Caches/TemporaryItems, though this can now be a symlink to /dev/null
 	# 3. Word requires (for documents in AFS lockers outside $HOME) that ~/Library/Caches/TemporaryItems points to /dev/null
 	# SUM: 	everyone should have a $HOME/.TemporaryItems
 	#		outlook users should have symlink: "$HOME"/.TemporaryItems /Users/MacAthena/"$USER"/Library/Caches/TemporaryItems [set by archdusp container login.sh]
 	#		cluster users should have symlink: "$HOME"/.TemporaryItems /Users/MacAthena/"$USER"/Library/Caches/TemporaryItems [set by container-specific login.sh]
 	#		all others should have symlink: /dev/null /Users/MacAthena/"$USER"/Library/Caches/TemporaryItems [set here]
	ln -sfh /dev/null /Users/MacAthena/"$USER"/Library/Caches/TemporaryItems
	
	# set up Movies, Music sym links to ${scratch_vol} partition otherwise create local
	# set up .TemporaryItems/Adobe (for Audition)
	# note: CC defaults to ~/Documents/Adobe
	
	IFS="
	"
	for directory in 'Documents/Adobe' 'Movies/iMovie Projects.localized' 'Movies/iMovie Events.localized' Music
	do	
	 	if [ ${directory%%/*} = Documents ]
	 	then
	 		# treat a bit differently as do not want ~/Documents symlinked
	 		dir=$directory
	 		target="$HOME/$dir"	
	 	else
	 		dir="${directory%%/*}"
	 		target="$HOME"
	 	fi
	 	
	 	# if $dir -e and not symlinked, then rename
	 	if [ -d "$HOME/$dir" ] && [ ! -h "$HOME/$dir" ]
	 	then
	 		mv "$HOME"/"$dir" "$HOME/${dir}_afs"
    	fi
    		
	 	if [ -e "$scratch_vol" ]
	 	then
	 		# symlink to /Volumes/scratch
			mkdir -p "$scratch_vol/$USER/$directory"
	   		ln -sfh "$scratch_vol/$USER/$dir" $target
	   		echo "$msg" > "$scratch_vol/$USER/$dir/WARNING_READ_ME_NOW.txt"
		else
			# symlink to the local hidden store
			[ -d "/Users/MacAthena/$USER/$directory" ] || [ `mkdir -p /Users/MacAthena/"$USER"/$directory` ]
			ln -sfh "/Users/MacAthena/$USER/$dir" $target
	 		echo "$msg" > "/Users/MacAthena/$USER/$dir/WARNING_READ_ME_NOW.txt"
		fi
	done
	unset IFS
	}

afsQuotaCheck ()
	{
	quota_used_perc=`fs quota $athenaHome | awk -F% '{print $1}'`
	if [ $quota_used_perc -ge 90 ]
	then
		msg="/usr/bin/osascript -e 'tell app \"Finder\"' -e 'activate' -e 'display dialog \"Warning! $quota_used_perc% of your Athena quota is used! Delete or archive files now or risk losing data!\" & Return & Return & \"accounts@mit.edu\" buttons {\"OK\"} with icon caution giving up after 10' -e 'end'"
		eval "$msg"
	elif [ $quota_used_perc -lt 90 ] && [ $quota_used_perc -ge 85 ]
	then
		msg="/usr/bin/osascript -e 'tell app \"Finder\"' -e 'activate' -e 'display dialog \"Warning! $quota_used_perc% of your Athena quota is used! Please consider deleting or archiving files now.\" & Return & Return & \"accounts@mit.edu\" buttons {\"OK\"} with icon caution giving up after 5' -e 'end'"
		eval "$msg"
	fi
	}

setDock ()
	{
	# if current container is different than last container used, restore Dock
	if [ -f $HOME/Library/MacAthena/Dock/com.apple.dock.plist_${container/\//-} ] && [ `ls -t $HOME/Library/MacAthena/Dock | head -1` != "com.apple.dock.plist_${container/\//-}" ]
	then
		echo "Restoring user's Dock for ${container/\//-}"
		mv -f $HOME/Library/MacAthena/Dock/com.apple.dock.plist_${container/\//-} $HOME/Library/Preferences/com.apple.dock.plist
		#defaults read com.apple.dock > /dev/null 2>&1
	else
		echo "User's ${container/\//-} Dock is current, will refresh only."
	fi
	
	# disable autohide (enabled by logouthook to hide Dock when resetting across containers (cosmetic))
	defaults read com.apple.dock > /dev/null 2>&1
	defaults write com.apple.dock autohide -boolean false
	killall Dock
	
	# _SOS belongs in Dock. (restrict to 10.9 and above (dockutil bug for 10.8) and where Dock without _SOS)
	if [ `sw_vers -productVersion | awk -F. '{print $2}'` -eq 9 ] && [ `defaults read com.apple.dock | grep -c _SOS` -eq 0 ]
	then
		/afs/athena.mit.edu/dept/cron/system/macathena/core/scripts/support/dockutil --add "/afs/.athena.mit.edu/dept/cron/system/macathena/core/Applications/_SOS/_SOS.app"
	fi
	}
			
#################################################################################### BEGIN

container=`echo $(ls /Library/MacAthena/ID/containerID_*) | awk -F_ '{print $NF}' | sed 's/-/\//g'`

# check if remote user
if [ `echo $HOME | grep -c athena.mit.edu` = 1 ]
then
	homeType=MacAthena
	athenaHome=${HOME%/*}
	bootvol=`/usr/sbin/diskutil info / | grep 'Volume Name' | awk -F: '{print $2}' | sed 's/^[ ]*//'`
else
	homeType=Local
fi

echo "[+] : ${0##/*/}" `date '+[ %H:%M:%S ]'`
echo User: $USER : $homeType : $athenaHome : $HOME

if [ $homeType = MacAthena ]
then
	aklog
	
	# hide dock for time it is being tweaked
	#defaults write com.apple.dock autohide -boolean true
	#echo kill
	#killall Dock
	
	# reset expiration clock on /Users/MacAthena/"$USER" (clock checked by LaunchDaemon edu.mit.core_purge_dir)
	touch /Users/MacAthena/"$USER"
	
	# prepare local scratch storage for Adobe, Movies, Music, Pictures, Xcode
	prepareUserDirs scratch
	
	# update user environment: ByHost settings, LaunchAgents, configurations
	IFS="
	"
 	updateByHostPrefs
 	updateLaunchAgentsUser
 	
 	if [ ${HOSTNAME:0:6} = cronmw ] || [ ${HOSTNAME:0:4} = oeit ] || [ ${HOSTNAME:0:7} = act-iel ] || [ ${HOSTNAME:0:3} = w20 ] || [ ${HOSTNAME:0:3} = pul ] || [ ${HOSTNAME:0:3} = lib ]
 	then
		updateConfigUser "containers/$container"
 	fi
 	unset IFS
	
 	# symlinks for lib items, Athena lockers, scratch locations
	symlinksLibraryItems
	symlinksAthena
	symlinksVolumes
	
	# check that user's certaid prefs are current
	CertAidPrefCheck
	
	# check athena afs quota
	afsQuotaCheck

	# restore user's last saved Dock prefs for current container
	setDock
	
	# source container-specific login script if specified
	if [ -f /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/LaunchAgents/login_"${container##*/}".sh ]
	then
		echo "Sourcing > login_"${container##*/}.sh
		source /afs/.athena.mit.edu/dept/cron/system/macathena/containers/"$container"/LaunchAgents/login_"${container##*/}".sh
	else
		echo "No container login script to run."
	fi
else
	defaults write com.apple.dock autohide -boolean false
	killall Dock
fi

#osascript -e "beep beep"

echo "[-] : ${0##/*/}" `date '+[ %H:%M:%S ]'`

exit 0