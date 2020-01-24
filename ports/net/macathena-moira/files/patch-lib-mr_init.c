--- lib/mr_init.c.orig	2019-12-21 14:25:43.000000000 -0500
+++ lib/mr_init.c	2019-12-21 14:31:30.000000000 -0500
@@ -20,15 +20,12 @@
   if (mr_inited)
     return;
 
-#if defined(__APPLE__) && defined(__MACH__)
-  add_error_table(&et_sms_error_table);
-  add_error_table(&et_krb_error_table);
-  add_error_table(&et_ureg_error_table);
-#else
   initialize_sms_error_table();
   initialize_krb_error_table();
   initialize_ureg_error_table();
-#endif
+  add_error_table(&et_sms_error_table);
+  add_error_table(&et_krb_error_table);
+  add_error_table(&et_ureg_error_table);
 
   mr_inited = 1;
 }
