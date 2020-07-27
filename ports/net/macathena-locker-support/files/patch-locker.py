diff --git a/locker.py b/locker.py
index 6a95377..cf90034 100644
--- a/locker.py
+++ b/locker.py
@@ -390,7 +390,9 @@ def resolve(name):
     if name.startswith('.'):
         raise LockerError("Invalid locker name: " + name)
     try:
-        filesystems = hesiod.FilsysLookup(name, parseFilsysTypes=False).filsys
+        filesystems = hesiod.FilsysLookup(name).filsys
+        for f in filesystems:
+            f['data'] = f['location'] + ' ' + f['mode'] + ' ' + f['mountpoint']
     except IOError as e:
         if e.errno == errno.ENOENT:
             raise LockerNotFoundError(name)
