#!/usr/bin/env python

def packageCvs(module, cvsModule, cvsroot='/afs/dev.mit.edu/source/repository', getAutoconf='packs/build/autoconf', date='tomorrow'):
	import os
	import time
	import tarfile
	import shutil
	
	os.system('attach macathena >/dev/null 2>/dev/null')
	os.chdir('/mit/macathena/build')
	
	os.environ['CVSROOT'] = cvsroot
	os.system('cvs -R export -D %s %s >/dev/null 2>/dev/null' % (date, cvsModule))
	
	if getAutoconf:
		os.system('cvs -R export -r HEAD -d %s %s >/dev/null 2>/dev/null' % (cvsModule, getAutoconf))
	
	stamp = 0
	for root, dirs, files in os.walk(cvsModule):
		if len(files) > 0:
			stamp = max(stamp, max(os.stat('%s/%s' % (root, file))[8] for file in files))
	
	tarball_time = time.strftime('%Y%m%d', time.localtime(stamp))
	tarball = '%s-%s' % (module, tarball_time)
	os.rename(cvsModule, tarball)
	
	tar = tarfile.open('%s.tar.gz' % tarball, 'w:gz')
	tar.add(tarball)
	tar.close()
	
	shutil.move('%s.tar.gz' % tarball, '/mit/macathena/dist/')
	shutil.rmtree('/mit/macathena/build/%s' % tarball)
	
	print 'Created /mit/macathena/dist/%s.tar.gz' % tarball

modules = {'moira': ['moira', '/afs/athena.mit.edu/astaff/project/moiradev/repository', False],
	'libathdir': ['athena/lib/athdir'],
	'athdir': ['athena/bin/athdir'],
	'machtype': ['athena/bin/machtype']}

if __name__ == '__main__':
	import sys
	
	for arg in sys.argv[1:]:
		if modules.has_key(arg):
			apply(packageCvs, [arg] + modules[arg])
		else:
			print "Sorry - I don't know about the module %s" % arg