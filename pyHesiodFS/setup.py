from distutils.core import setup
setup(name='pyHesiodFS',
      version='1.0',
      author='Quentin Smith',
      author_email='pyhesiodfs@mit.edu',
      py_modules=['hesiod'],
      scripts=['pyHesiodFS.py'],
      data_files=[('/Library/LaunchDaemons', ('edu.mit.sipb.mit-automounter.plist',))])
