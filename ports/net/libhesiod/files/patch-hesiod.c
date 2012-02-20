--- hesiod.c.orig	2007-12-17 01:54:47.000000000 -0500
+++ hesiod.c	2007-12-17 02:04:47.000000000 -0500
@@ -45,7 +45,7 @@
 
 #include <sys/types.h>
 #include <netinet/in.h>
-#include <arpa/nameser.h>
+#include <arpa/nameser_compat.h>
 #include <errno.h>
 #include <netdb.h>
 #include <resolv.h>
