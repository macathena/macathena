diff --git a/afs/acl.py b/afs/acl.py
index 20a416f..65ec595 100644
--- a/afs/acl.py
+++ b/afs/acl.py
@@ -11,7 +11,7 @@ _canonical = {
     "none": "",
 }
 
-_reverseCanonical = dict((y, x) for (x, y) in _canonical.iteritems())
+_reverseCanonical = dict((y, x) for (x, y) in _canonical.items())
 
 _charBitAssoc = [
     ('r', READ),
@@ -119,7 +119,7 @@ class ACL(object):
     def set(self, user, bitmask, negative=False):
         """Set the bitmask for a given user"""
         if bitmask < 0 or bitmask > max(_char2bit.values()):
-            raise ValueError, "Invalid bitmask"
+            raise ValueError("Invalid bitmask")
         if negative:
             self.neg[user] = bitmask
         else:
