add_flags=
add () { eval "$( @FINKPREFIX@/bin/attach-add.py -b $add_flags "$@" )" ; }