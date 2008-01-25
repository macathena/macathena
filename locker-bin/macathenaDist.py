#!/usr/bin/env python

import tarfile
import os
from os.path import basename
import time
import shutil

mtime = 0

class MyTarFile(tarfile.TarFile):
	def gettarinfo(self, name=None, arcname=None, fileobj=None):
		info = tarfile.TarFile.gettarinfo(self, name, arcname, fileobj)
		info.uid = info.gid = 0
		info.uname = "root"
		info.gname = "wheel"
		
		if info.isdir():
			info.mtime = mtime
		
		return info

def packageSvn(module, svnModule, extras=[], svnroot='/afs/dev.mit.edu/source/svn-repos', revision='HEAD'):
	os.system('attach macathena >/dev/null 2>/dev/null')
	os.chdir('/mit/macathena/build')
	
	os.system('svn export -r %s file://%s/%s %s >/dev/null 2>&1' % (revision, svnroot, svnModule, module))
	
	for extra in extras:
		os.system('svn export -r %s file://%s/%s >/dev/null 2>&1' % (revision, svnroot, extra))
		os.system('mv %s %s' % (basename(extra), module))
	
	version_info = os.popen('svn info -r %s file://%s/%s' % (revision, svnroot, svnModule)).readlines()
	for line in version_info:
		if line.startswith('Last Changed Date: '):
			time_string = line.strip().split(': ')[1][0:19]
		elif line.startswith('Last Changed Rev: '):
			revision = line.strip().split(': ')[1]
	
	mtime = int(time.strftime("%s", time.strptime(time_string, "%Y-%m-%d %H:%M:%S")))
	
	tarball = "%s-%s" % (module, revision)
	os.rename(module, tarball)
	
	tar = MyTarFile.open('%s.tar.gz' % tarball, 'w:gz')
	tar.add(tarball)
	tar.close()
	
	shutil.move('%s.tar.gz' % tarball, '/mit/macathena/dist/')
	shutil.rmtree('/mit/macathena/build/%s' % tarball)
	
	print 'Created /mit/macathena/dist/%s.tar.gz' % tarball

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

cvsModules = {'moira': ['moira', False, '/afs/athena.mit.edu/astaff/project/moiradev/repository']}

svnModules = {'libathdir': ['trunk/athena/lib/athdir'],
	'athdir': ['trunk/athena/bin/athdir'],
	'machtype': ['trunk/athena/bin/machtype'],
	'attachandrun': ['trunk/athena/bin/attachandrun'],
	'athrun': ['trunk/athena/bin/athrun'],
	'athinfo': ['trunk/athena/bin/athinfo'],
	'getcluster': ['trunk/athena/bin/getcluster', ['attic/packs/build/aclocal.m4']],
	'libxj': ['trunk/athena/lib/Xj'],
	'xcluster': ['trunk/athena/bin/xcluster', ['attic/packs/build/aclocal.m4']],
	'discuss': ['trunk/athena/bin/discuss']}

if __name__ == '__main__':
	import sys
	
	if sys.argv[1] == "all":
		build = cvsModules.keys() + svnModules.keys()
	else:
		build = sys.argv[1:]
	
	for arg in build:
		if svnModules.has_key(arg):
			apply(packageSvn, [arg] + svnModules[arg])
		elif cvsModules.has_key(arg):
			apply(packageCvs, [arg] + cvsModules[arg])
		else:
			print "Sorry - I don't know about the module %s" % arg
