#!/usr/bin/env python

from __future__ import absolute_import, division, print_function, unicode_literals
import os
import sys
import getopt

usage = """Usage: add [-vfrpwbq] [-P $athena_path] [-a attachflags] [lockername ...]
       add [-dfrb] [-P $athena_path] pathname ...
"""

if '-a' in sys.argv[1:]:
	(add_options, attach_options) = sys.argv[1:].split('-a')
else:
	add_options = sys.argv[1:]
	attach_options = []

try:
	optlist, args = getopt.getopt(add_options, 'frwpP:abqh');
except getopt.GetoptError:
	sys.stderr.write(usage)
	sys.exit(1)

front = False
remove_locker = False
shell = 'csh'
for o, a in optlist:
	if o == '-f': front = True
	if o == '-r': remove_locker = True
	if o == '-b': shell = 'bash'

if 'PATH' in os.environ:
	path = os.environ['PATH'].split(':')
else: path = []

if 'MANPATH' in os.environ:
	manpath = os.environ['MANPATH'].split(':')
else: manpath = []

if 'INFOPATH' in os.environ:
	infopath = os.environ['INFOPATH'].split(':')
else: infopath = []

for arg in args:
	if '/' == arg[0] or '.' == arg[0]:
		if remove_locker: path.remove(arg)
		elif front: path = [arg] + path
		else: path.append(arg)
	else:
		locker = '/mit/%s' % arg
		
		bin_pipe = os.popen('@FINKPREFIX@/bin/athdir %s bin' % locker)
		new_bin = bin_pipe.read().strip()
		if bin_pipe.close() != None:
			if not os.access(locker, os.F_OK):
				sys.stderr.write("%s: Locker unknown\n" % arg)
			continue
		if new_bin in path:
			path.remove(new_bin)
		if front: path.insert(0, new_bin)
		elif not remove_locker: path.append(new_bin)
		
		man_pipe = os.popen('@FINKPREFIX@/bin/athdir %s man' % locker)
		new_man = man_pipe.read().strip()
		if man_pipe.close() == None:
			if new_man in manpath:
				manpath.remove(new_man)
			if front: manpath.insert(0, new_man)
			elif not remove_locker: manpath.append(new_man)
		
		info_pipe = os.popen('@FINKPREFIX@/bin/athdir %s info' % locker)
		new_info = info_pipe.read().strip()
		if info_pipe.close() == None:
			if new_info in infopath:
				infopath.remove(new_info)
			if front: infopath.insert(0, new_info)
			elif not remove_locker: infopath.append(new_info)

if shell == 'bash':
	print('PATH="%s"; export PATH; MANPATH="%s"; export MANPATH; INFOPATH="%s"; export INFOPATH' % (':'.join(path), ':'.join(manpath), ':'.join(infopath)))
elif shell == 'csh':
	print('setenv PATH "%s"; setenv MANPATH "%s"; setenv INFOPATH "%s"' % (':'.join(path), ':'.join(manpath), ':'.join(infopath)))
