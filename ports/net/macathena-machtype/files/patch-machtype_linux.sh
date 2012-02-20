--- machtype_linux.sh.orig	2011-10-28 17:31:43.000000000 -0400
+++ machtype_linux.sh	2012-02-20 12:33:57.000000000 -0500
@@ -1,4 +1,4 @@
-#!/bin/sh
+#!/bin/bash
 # $Id: machtype_linux.sh,v 1.9 2003-08-12 21:47:50 jweiss Exp $
 
 # We need to support the following options:
@@ -91,7 +91,7 @@
 fi
 
 if [ $syspacks ]; then
-	echo "Linux does not use system packs." >&2
+	echo "MacAthena does not use system packs." >&2
 	printed=1
 fi
 
@@ -145,27 +145,26 @@
 fi
 
 if [ $display ] ; then
-	lspci | awk -F: '/VGA/ {print $3}' | sed -n -e 's/^ //' -e p
+	system_profiler SPDisplaysDataType | awk 'NR==3 { print }' | sed "s/^ *\(.*\):$/\1/"
 	printed=1
 fi
 
 if [ $rdsk ]; then
-	for d in /sys/block/[fhs]d*; do
-	    echo $(basename "$d"): \
-		$(xargs -I @ expr @ '*' 8 / 15625 < "$d/size")MB \
-		$(cat "$d/device/model" ||
-		  cat "/proc/ide/$(basename "$d")/model")
-	done 2>/dev/null
+	disks=`ls /dev/disk* | grep 'disk[0-9]*$'`
+	for disk in $disks
+	do
+		printf "%s: %s GB\n" "$(basename $disk)" "$(diskutil info "$disk" | awk '$1=="Total" { print  $3 }')"
+	done
 	printed=1
 fi
 
 if [ $memory ] ; then
+	physmem=$(($(sysctl -n hw.physmem)/1024))
+	usermem=$(($(sysctl -n hw.usermem)/1024))
 	if [ $verbose ]; then
-		awk '/^MemTotal:/ { printf "user=%d, phys=%d (%d M)\n",
-					   $2, $2, $2/1024 }' \
-		    /proc/meminfo
+		printf "user=%d, phys=%d (%d M)\n" $usermem $physmem $((physmem/1024))
 	else
-		awk '/^MemTotal:/ { printf "%d\n", $2 }' /proc/meminfo
+		echo $physmem
 	fi
 	printed=1
 fi
@@ -182,6 +181,6 @@
 fi
 
 if [ $printed -eq '0' ] ; then
-	echo linux
+	echo darwin
 fi
 exit 0
