#!/usr/bin/env python

from __future__ import print_function

import subprocess

arch = subprocess.check_output(['arch']).strip()
darwin_ver = int(subprocess.check_output(['uname', '-r']).split(b'.')[0]) * 10

ver_list = range(darwin_ver, 70, -10)
x86_list = ["x86_darwin_%d" % ver for ver in ver_list]
ppc_list = ["ppc_darwin_%d" % ver for ver in ver_list]

if arch == b'i386' and darwin_ver >= 110:
	versions = x86_list
elif arch == b'i386':
	versions = [item for items in zip(x86_list, ppc_list) for item in items]
else:
	versions = ppc_list

versions += ['share', 'common', 'any', 'all']

print('ATHENA_SYS=%s ATHENA_SYS_COMPAT="%s"' % (versions[0], ':'.join(versions[1:])))
