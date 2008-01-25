from distutils.core import setup
setup(name='macathena-add',
      version='1.0',
      author='SIPB MacAthena Project',
      author_email='sipb-macathena@mit.edu',
      scripts=['attach-add.py'],
      data_files=[('@FINKPREFIX@/etc/profile.d', ('macathena-add.sh','macathena-add.csh'))])
