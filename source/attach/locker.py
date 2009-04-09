class Options(object):
    __slots__ = ['verbosity', 'action', 'access', 'auth', 'zephyr']

    verbosity = 'verbose'
    """
    How much to print

    Valid values:
     - verbose
     - quiet (only print errors)
     - path (only print the source path of the filesystem)
    """
    action = True
    """
    Whether or not to actually do something. If this is False, then
    information will be printed, but nothing will actually happen
    """
    access = None
    """
    This is meaningless for AFS filesystems, but we'll track it
    anyway, just in case.

    Values:

     - None: Use the access value in Hesiod, or if none is provided,
       'w'

     - 'r': Read only

     - 'w': Read/write
    """
    auth = True
    """
    Whether and how to authenticate (or for detach, deauthenticate)
    against the filesystem

    Values:

     - True: always auth or deauth regardless of whether the
       filesystem is currently attached or not (default)

     - False: auth if the filesystem has not yet been attached, and
       deauth if the filesystem has not yet been detached

     - None: never authenticate or deauthenticate
    """
    zephyr = True
    """
    Whether or not to update Zephyr subscriptions with fileserver
    information for the specified filesystem.
    """
