diff --git a/setup.py b/setup.py
index 378c7dc..879523a 100755
--- a/setup.py
+++ b/setup.py
@@ -17,20 +17,22 @@ import os
 for root in ['/Library/OpenAFS/Tools',
              '/usr/local',
              '/usr/afsws',
-             '/usr']:
+             '/usr',
+	     '__PREFIX__']:
     if os.path.exists('%s/include/afs/afs.h' % root):
         break
 
 include_dirs = [os.path.join(os.path.dirname(__file__), 'afs'),
-                '%s/include' % root]
+                '%s/include/afs' % root]
+os.environ['LDFLAGS'] = '-framework Kerberos'
 library_dirs = ['%s/lib' % root,
-                '%s/lib/afs' % root]
+               '%s/lib/afs' % root]
 if os.path.exists('%s/lib/libafsauthent_pic.a' % root):
     suffix = '_pic'
 else:
     suffix = ''
-libraries = ['afsauthent%s' % suffix, 'afsrpc%s' % suffix, 'resolv']
+libraries = ['afsauthent%s' % suffix, 'afsrpc%s' % suffix, 'resolv', 'afshcrypto']
 define_macros = [('AFS_PTHREAD_ENV', None)]

 def PyAFSExtension(module, *args, **kwargs):
