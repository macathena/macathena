#!/usr/bin/env python

import gzip
import tarfile
import os
from os.path import basename
import time
import shutil

mtime = 0

def _write_gzip_header(self):
	self.fileobj.write('\037\213')             # magic header
	self.fileobj.write('\010')                 # compression method
	fname = self.filename[:-3]
	flags = 0
	if fname:
		flags = gzip.FNAME
	self.fileobj.write(chr(flags))
	gzip.write32u(self.fileobj, long(mtime))
	self.fileobj.write('\002')
	self.fileobj.write('\377')
	if fname:
		self.fileobj.write(fname + '\000')

gzip.GzipFile._write_gzip_header = _write_gzip_header

class MyTarFile(tarfile.TarFile):
	def gettarinfo(self, name=None, arcname=None, fileobj=None):
		info = tarfile.TarFile.gettarinfo(self, name, arcname, fileobj)
		info.uid = info.gid = 0
		info.uname = "root"
		info.gname = "wheel"
		
		info.mtime = mtime
		
		return info

def packageSvn(module, svnModule, extras=[], svnroot='file:///afs/dev.mit.edu/source/svn-repos', revision='HEAD'):
	global mtime
	
	os.system('attach macathena >/dev/null 2>/dev/null')
	os.chdir('/mit/macathena/build')
	
	os.system('svn export -r %s %s/%s %s >/dev/null 2>&1' % (revision, svnroot, svnModule, module))
	
	if extras:
		for extra in extras:
			os.system('svn export -r %s %s/%s >/dev/null 2>&1' % (revision, svnroot, extra))
			os.system('mv %s %s' % (basename(extra), module))
	
	version_info = os.popen('svn info -r %s %s/%s' % (revision, svnroot, svnModule)).readlines()
	for line in version_info:
		if line.startswith('Last Changed Date: '):
			time_string = line.strip().split(': ')[1][0:19]
		elif line.startswith('Last Changed Rev: '):
			revision = line.strip().split(': ')[1]
	
	mtime = int(time.strftime("%s", time.strptime(time_string, "%Y-%m-%d %H:%M:%S")))
	
	tarball = "%s-svn%s" % (module, revision)
	os.rename(module, tarball)
	
	tar = MyTarFile.open('%s.tar.gz' % tarball, 'w:gz')
	tar.add(tarball)
	tar.close()
	
	shutil.move('%s.tar.gz' % tarball, '/mit/macathena/dist/')
	shutil.rmtree('/mit/macathena/build/%s' % tarball)
	
	print 'Created /mit/macathena/dist/%s.tar.gz' % tarball

def packageCvs(module, cvsModule, extras=['packs/build/autoconf'], cvsroot='/afs/dev.mit.edu/source/repository', date='tomorrow'):
	global mtime
	
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
	
	mtime = int(time.strftime('%s', time.localtime(stamp)))
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

svnModules = {'athdir': ['trunk/athena/bin/athdir'],
	'attachandrun': ['trunk/athena/bin/attachandrun'],
	'athrun': ['trunk/athena/bin/athrun'],
	'athinfo': ['trunk/athena/bin/athinfo'],
	'delete': ['trunk/athena/bin/delete', ['attic/packs/build/aclocal.m4']],
	'discuss': ['trunk/athena/bin/discuss', ['attic/packs/build/aclocal.m4']],
	'getcluster': ['trunk/athena/bin/getcluster', ['attic/packs/build/aclocal.m4']],
	'just': ['trunk/athena/bin/just'],
	'libathdir': ['trunk/athena/lib/athdir'],
	'libgms': ['trunk/athena/lib/gms'],
	'libxj': ['trunk/athena/lib/Xj'],
	'machtype': ['trunk/athena/bin/machtype'],
	'tellme': ['trunk/debathena/config/tellme'],
	'xcluster': ['trunk/athena/bin/xcluster', ['attic/packs/build/aclocal.m4']],
# Our packages:
	'add': ['trunk/source/add', False, 'https://macathena.mit.edu/svn'],
	'afs-conf-patch': ['trunk/source/afs-conf-patch', False, 'https://macathena.mit.edu/svn'],
	'afs-config': ['trunk/source/afs-config', False, 'https://macathena.mit.edu/svn'],
	'attach': ['trunk/source/attach', False, 'https://macathena.mit.edu/svn'],
	'base': ['trunk/source/base', False, 'https://macathena.mit.edu/svn'],
	'config-common': ['trunk/source/config-common', False, 'https://macathena.mit.edu/svn'],
	'hes': ['trunk/source/hes', False, 'https://macathena.mit.edu/svn'],
	'pyhesiodfs': ['trunk/source/pyhesiodfs', False, 'https://macathena.mit.edu/svn'],
	'update': ['trunk/source/update', False, 'https://macathena.mit.edu/svn'],
	'ssl-certificates': ['trunk/source/ssl-certificates', False, 'https://macathena.mit.edu/svn']
}

if __name__ == '__main__':
	import sys
	
	if sys.argv[1] == "all":
		build = cvsModules.keys() + svnModules.keys()
	else:
		build = sys.argv[1:]
	
	for arg in build:
		if svnModules.has_key(arg):
			print "Building %s" % arg
			apply(packageSvn, [arg] + svnModules[arg])
		elif cvsModules.has_key(arg):
			print "Building %s" % arg
			apply(packageCvs, [arg] + cvsModules[arg])
		else:
			print "Sorry - I don't know about the module %s" % arg
