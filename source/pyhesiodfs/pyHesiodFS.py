#!/usr/bin/python2.5

#    pyHesiodFS:
#    Copyright (C) 2007  Quentin Smith <quentin@mit.edu>
#    "Hello World" pyFUSE example:
#    Copyright (C) 2006  Andrew Straw  <strawman@astraw.com>
#
#    This program can be distributed under the terms of the GNU LGPL.
#    See the file COPYING.
#

import sys, os, stat, errno, time
from syslog import *
import fuse
from fuse import Fuse

import hesiod

try:
    from collections import defaultdict
except ImportError:
    class defaultdict(dict):
        """
        A dictionary that automatically will fill in keys that don't exist
        with the result from some default value factory
        
        Based on the collections.defaultdict object in Python 2.5
        """
        
        def __init__(self, default_factory):
            self.default_factory = default_factory
            super(defaultdict, self).__init__()
        
        def __getitem__(self, y):
            if y not in self:
                self[y] = self.default_factory()
            return super(defaultdict, self).__getitem__(y)
        
        def __str__(self):
            return 'defaultdict(%s, %s)' % (self.default_factory, 
                                            super(defaultdict, self).__str__())

class negcache(dict):
    """
    A set-like object that automatically expunges entries after
    they're been there for a certain amount of time.
    
    This only supports add, remove, and __contains__
    """
    
    def __init__(self, cache_time=0.5):
        self.cache_time = cache_time
    
    def add(self, obj):
        self[obj] = time.time()
    
    def remove(self, obj):
        try:
            del self[obj]
        except KeyError:
            pass
    
    def __contains__(self, k):
        if super(negcache, self).__contains__(k):
            if self[k] + self.cache_time > time.time():
                return True
            else:
                del self[k]
        return False

new_fuse = hasattr(fuse, '__version__')

fuse.fuse_python_api = (0, 2)

hello_path = '/README.txt'
hello_str = """This is the pyhesiodfs FUSE autmounter. To access a Hesiod filsys, just access
%(mountpoint)s/name.

If you're using the Finder, try pressing Cmd+Shift+G and then entering
%(mountpoint)s/name"""

if not hasattr(fuse, 'Stat'):
    fuse.Stat = object

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

    def toTuple(self):
        return (self.st_mode, self.st_ino, self.st_dev, self.st_nlink,
                self.st_uid, self.st_gid, self.st_size, self.st_atime,
                self.st_mtime, self.st_ctime)

class PyHesiodFS(Fuse):

    def __init__(self, *args, **kwargs):
        Fuse.__init__(self, *args, **kwargs)
        
        openlog('pyhesiodfs', 0, LOG_DAEMON)
        
        try:
            self.fuse_args.add("allow_other", True)
        except AttributeError:
            self.allow_other = 1

        if sys.platform == 'darwin':
            self.fuse_args.add("noappledouble", True)
            self.fuse_args.add("noapplexattr", True)
            self.fuse_args.add("volname", "MIT")
            self.fuse_args.add("fsname", "pyHesiodFS")
        self.mounts = defaultdict(dict)
        
        # Cache deletions for half a second - should give `ln -nsf`
        # enough time to make a new symlink
        self.negcache = defaultdict(negcache)
    
    def _uid(self):
        return fuse.FuseGetContext()['uid']
    
    def _gid(self):
        return fuse.FuseGetContext()['gid']
    
    def _pid(self):
        return fuse.FuseGetContext()['pid']
    
    def getattr(self, path):
        st = MyStat()
        if path == '/':
            st.st_mode = stat.S_IFDIR | 0755
            st.st_gid = self._gid()
            st.st_nlink = 2
        elif path == hello_path:
            st.st_mode = stat.S_IFREG | 0444
            st.st_nlink = 1
            st.st_size = len(hello_str)
        elif '/' not in path[1:]:
            if path[1:] not in self.negcache[self._uid()] and self.findLocker(path[1:]):
                st.st_mode = stat.S_IFLNK | 0777
                st.st_uid = self._uid()
                st.st_nlink = 1
                st.st_size = len(self.findLocker(path[1:]))
            else:
                return -errno.ENOENT
        else:
            return -errno.ENOENT
        if new_fuse:
            return st
        else:
            return st.toTuple()

    def getCachedLockers(self):
        return self.mounts[self._uid()].keys()

    def findLocker(self, name):
        """Lookup a locker in hesiod and return its path"""
        if name in self.mounts[self._uid()]:
            return self.mounts[self._uid()][name]
        else:
            try:
                filsys = hesiod.FilsysLookup(name)
            except IOError, e:
                if e.errno in (errno.ENOENT, errno.EMSGSIZE):
                    raise IOError(errno.ENOENT, os.strerror(errno.ENOENT))
                else:
                    raise IOError(errno.EIO, os.strerror(errno.EIO))
            # FIXME check if the first locker is valid
            if len(filsys.filsys) >= 1:
                pointers = filsys.filsys
                pointer = pointers[0]
                if pointer['type'] != 'AFS' and pointer['type'] != 'LOC':
                    syslog(LOG_NOTICE, "Unknown locker type "+pointer['type']+" for locker "+name+" ("+repr(pointer)+" )")
                    return None
                else:
                    self.mounts[self._uid()][name] = pointer['location']
                    syslog(LOG_INFO, "Mounting "+name+" on "+pointer['location'])
                    return pointer['location']
            else:
                syslog(LOG_WARNING, "Couldn't find filsys for "+name)
                return None

    def getdir(self, path):
        return [(i, 0) for i in (['.', '..', hello_path[1:]] + self.getCachedLockers())]

    def readdir(self, path, offset):
        for (r, zero) in self.getdir(path):
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
    
    def symlink(self, src, path):
        if path == '/' or path == hello_path:
            return -errno.EPERM
        elif '/' not in path[1:]:
            self.mounts[self._uid()][path[1:]] = src
            self.negcache[self._uid()].remove(path[1:])
        else:
            return -errno.EPERM
    
    def unlink(self, path):
        if path == '/' or path == hello_path:
            return -errno.EPERM
        elif '/' not in path[1:]:
            del self.mounts[self._uid()][path[1:]]
            self.negcache[self._uid()].add(path[1:])
        else:
            return -errno.EPERM

def main():
    global hello_str
    try:
        usage = Fuse.fusage
        server = PyHesiodFS(version="%prog " + fuse.__version__,
                            usage=usage,
                            dash_s_do='setsingle')
        server.parse(errex=1)
    except AttributeError:
        usage="""
pyHesiodFS [mountpath] [options]

"""
        if sys.argv[1] == '-f':
            sys.argv.pop(1)
        server = PyHesiodFS()

    hello_str = hello_str % {'mountpoint': server.parse(errex=1).mountpoint}
    server.main()

if __name__ == '__main__':
    main()
