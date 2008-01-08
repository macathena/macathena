#!/usr/bin/env python

import sys
import hashlib

for arg in sys.argv[1:]:
	print "%s:" % arg
	f = open(arg).read()
	print "checksums\t\tmd5 %s \\" % hashlib.md5(f).hexdigest()
	print "\t\t\t\tsha1 %s \\" % hashlib.sha1(f).hexdigest()
	print "\t\t\t\trmd160 %s" % hashlib.new('rmd160', f).hexdigest()
