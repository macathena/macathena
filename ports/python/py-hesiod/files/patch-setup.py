--- setup.py.orig	2012-02-24 01:47:58.000000000 -0500
+++ setup.py	2012-02-24 01:48:19.000000000 -0500
@@ -17,6 +17,8 @@
     ext_modules=cythonize([
         Extension("_hesiod",
                   ["_hesiod.pyx"],
+                  include_dirs=['__PREFIX__/include'],
+                  library_dirs=['__PREFIX__/lib'],
                   libraries=["hesiod"]),
     ]),
 )
