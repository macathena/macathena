#!/usr/bin/env python

import tarfile
import os
import time
import shutil

class MyTarFile(tarfile.TarFile):
	def gettarinfo(self, name=None, arcname=None, fileobj=None):
		info = tarfile.TarFile.gettarinfo(self, name, arcname, fileobj)
		info.uid = info.gid = 0
		info.uname = "root"
		info.gname = "wheel"
		
		if info.isdir():
			info.mtime = 0
		
		return info

def packageCvs(module, cvsModule, extras=['packs/build/autoconf'], cvsroot='/afs/dev.mit.edu/source/repository', date='tomorrow'):
	os.system('attach macathena >/dev/null 2>/dev/null')
	os.chdir('/mit/macathena/build')
	
	os.environ['CVSROOT'] = cvsroot
	os.system('cvs -R export -D %s %s >/dev/null 2>/dev/null' % (date, cvsModule))
	
	if extras:
		for extra in extras:
			os.system('cvs -R export -D %s -d %s %s >/dev/null 2>/dev/null' % (date, cvsModule, extra))
	
	stamp = 0
	for root, dirs, files in os.walk(cvsModule):
		if len(files) > 0:
			stamp = max(stamp, max(os.stat('%s/%s' % (root, file))[8] for file in files))
	
	tarball_time = time.strftime('%Y%m%d', time.localtime(stamp))
	tarball = '%s-%s' % (module, tarball_time)
	os.rename(cvsModule, tarball)
	
	tar = MyTarFile.open('%s.tar.gz' % tarball, 'w:gz')
	tar.add(tarball)
	tar.close()
	
	shutil.move('%s.tar.gz' % tarball, '/mit/macathena/dist/')
	shutil.rmtree('/mit/macathena/build/%s' % tarball)
	
	print 'Created /mit/macathena/dist/%s.tar.gz' % tarball

modules = {'moira': ['moira', False, '/afs/athena.mit.edu/astaff/project/moiradev/repository'],
	'libathdir': ['athena/lib/athdir'],
	'athdir': ['athena/bin/athdir'],
	'machtype': ['athena/bin/machtype'],
	'attachandrun': ['athena/bin/attachandrun'],
	'athrun': ['athena/bin/athrun'],
	'athinfo': ['athena/bin/athinfo'],
	'getcluster': ['athena/bin/getcluster', ['packs/build/autoconf', 'packs/build/aclocal.m4']],
	'libxj': ['athena/lib/Xj'],
	'libss': ['athena/lib/ss', ['packs/build/autoconf', 'packs/build/aclocal.m4', 'packs/build/libtool']],
	'xcluster': ['athena/bin/xcluster', ['packs/build/autoconf', 'packs/build/aclocal.m4']],
	'discuss': ['athena/bin/discuss']}

if __name__ == '__main__':
	import sys
	
	if sys.argv[1] == "all":
		build = modules.keys()
	else:
		build = sys.argv[1:]
	
	for arg in build:
		if modules.has_key(arg):
			apply(packageCvs, [arg] + modules[arg])
		else:
			print "Sorry - I don't know about the module %s" % arg
