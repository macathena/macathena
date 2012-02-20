--- machtype_linux.sh.orig	2007-12-24 21:51:18.000000000 -0600
+++ machtype_linux.sh	2007-12-25 00:20:57.000000000 -0600
@@ -1,4 +1,4 @@
-#!/bin/sh
+#!/bin/bash
 # $Id: machtype_linux.sh,v 1.9 2003/08/12 21:47:50 jweiss Exp $
 
 # We need to support the following options:
@@ -86,7 +86,7 @@
 fi
 
 if [ $syspacks ]; then
-	echo "Linux does not use system packs." >&2
+	echo "MacAthena does not use system packs." >&2
 	printed=1
 fi
 
@@ -133,32 +133,31 @@
 fi
 
 if [ $display ] ; then
-        /sbin/lspci | awk -F: '/VGA/ {print $3}' | sed -n -e 's/^ //' -e p
+	system_profiler SPDisplaysDataType | awk 'NR==3 { print }' | sed "s/^ *\(.*\):$/\1/"
 	printed=1
 fi
 
 if [ $rdsk ]; then
-	awk '/^SCSI device/ { print; }
-	     /^hd[a-z]:/ { print; }
-	     /^Floppy/ { for (i=3; i <= NF; i += 3) print $i ": " $(i+2); }' \
-	     /var/log/dmesg
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
-		awk 'BEGIN { FS="[^0-9]+" }
-		     /^Memory:/ { printf "user=%d, phys=%d (%d M)\n",
-				         $2*1.024, $3*1.024, $3/1000; }' \
-		    /var/log/dmesg
+		printf "user=%d, phys=%d (%d M)\n" $usermem $physmem $((physmem/1024))
 	else
-		awk 'BEGIN { FS="[^0-9]+" }
-		     /^Memory:/ { printf "%d\n", $3*1.024; }' /var/log/dmesg
+		echo $physmem
 	fi
 	printed=1
 fi
 
 if [ $printed -eq '0' ] ; then
-	echo linux
+	echo darwin
 fi
 exit 0
