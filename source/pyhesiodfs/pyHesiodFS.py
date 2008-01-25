#!/usr/bin/python2.5

#    pyHesiodFS:
#    Copyright (C) 2007  Quentin Smith <quentin@mit.edu>
#    "Hello World" pyFUSE example:
#    Copyright (C) 2006  Andrew Straw  <strawman@astraw.com>
#
#    This program can be distributed under the terms of the GNU LGPL.
#    See the file COPYING.
#

import sys, os, stat, errno
import fuse
from fuse import Fuse

import hesiod

if not hasattr(fuse, '__version__'):
    raise RuntimeError, \
        "your fuse-py doesn't know of fuse.__version__, probably it's too old."

fuse.fuse_python_api = (0, 2)

hello_path = '/README.txt'
hello_str = """This is the pyhesiodfs FUSE autmounter. To access a Hesiod filsys, just access
%(mountpoint)s/name.

If you're using the Finder, try pressing Cmd+Shift+G and then entering
%(mountpoint)s/name"""

class MyStat(fuse.Stat):
    def __init__(self):
        self.st_mode = 0
        self.st_ino = 0
        self.st_dev = 0
        self.st_nlink = 0
        self.st_uid = 0
        self.st_gid = 0
        self.st_size = 0
        self.st_atime = 0
        self.st_mtime = 0
        self.st_ctime = 0

class PyHesiodFS(Fuse):

    def __init__(self, *args, **kwargs):
        Fuse.__init__(self, *args, **kwargs)
        self.fuse_args.add("allow_other", True)
        self.fuse_args.add("noappledouble", True)
        self.fuse_args.add("noapplexattr", True)
        self.fuse_args.add("fsname", "pyHesiodFS")
        self.fuse_args.add("volname", "MIT")
        self.mounts = {}
    
    def getattr(self, path):
        st = MyStat()
        if path == '/':
            st.st_mode = stat.S_IFDIR | 0755
            st.st_nlink = 2
        elif path == hello_path:
            st.st_mode = stat.S_IFREG | 0444
            st.st_nlink = 1
            st.st_size = len(hello_str)
        elif '/' not in path[1:]:
            if self.findLocker(path[1:]):
                st.st_mode = stat.S_IFLNK | 0777
                st.st_nlink = 1
                st.st_size = len(self.findLocker(path[1:]))
            else:
                return -errno.ENOENT
        else:
            return -errno.ENOENT
        return st

    def getCachedLockers(self):
        return self.mounts.keys()

    def findLocker(self, name):
        """Lookup a locker in hesiod and return its path"""
        if name in self.mounts:
            return self.mounts[name]
        else:
            filsys = hesiod.FilsysLookup(name)
            # FIXME check if the first locker is valid
            if len(filsys.getFilsys()) >= 1:
                pointers = filsys.getFilsys()
                pointer = pointers[0]
                if pointer['type'] != 'AFS' and pointer['type'] != 'LOC':
                    print >>sys.stderr, "Unknown locker type "+pointer.type+" for locker "+name+" ("+repr(pointer)+" )"
                    return None
                else:
                    self.mounts[name] = pointer['location']
                    print >>sys.stderr, "Mounting "+name+" on "+pointer['location']
                    return pointer['location']
            else:
                print >>sys.stderr, "Couldn't find filsys for "+name
                return None

    def readdir(self, path, offset):
        for r in  ['.', '..', hello_path[1:]]+self.getCachedLockers():
            yield fuse.Direntry(r)
            
    def readlink(self, path):
        return self.findLocker(path[1:])

    def open(self, path, flags):
        if path != hello_path:
            return -errno.ENOENT
        accmode = os.O_RDONLY | os.O_WRONLY | os.O_RDWR
        if (flags & accmode) != os.O_RDONLY:
            return -errno.EACCES

    def read(self, path, size, offset):
        if path != hello_path:
            return -errno.ENOENT
        slen = len(hello_str)
        if offset < slen:
            if offset + size > slen:
                size = slen - offset
            buf = hello_str[offset:offset+size]
        else:
            buf = ''
        return buf

def main():
    global hello_str
    usage="""
pyHesiodFS

""" + Fuse.fusage
    server = PyHesiodFS(version="%prog " + fuse.__version__,
                     usage=usage,
                     dash_s_do='setsingle')

    server.parse(errex=1)
    hello_str = hello_str % {'mountpoint': server.parse(errex=1).mountpoint}
    server.main()

if __name__ == '__main__':
    main()
