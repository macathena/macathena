#
# divert_link <prefix> <suffix>
#
#   Ensures that the file <prefix><suffix> is properly diverted to
#   <prefix>.debathena-orig<suffix> by this package, and becomes a
#   symbolic link to either <prefix>.debathena<suffix> (default) or
#   <prefix>.debathena-orig<suffix>.
#
# undivert_unlink <prefix> <suffix>
#
#   Undoes the action of divert_link <prefix> <suffix> specified
#   above.
#
# Version: 3.4
#

ours=.macathena
theirs=.macathena-orig

divert_link()
{
    prefix=$1
    suffix=$2
    
    file=$prefix$suffix
    ourfile=$prefix$ours$suffix
    theirfile=$prefix$theirs$suffix

    if ! dpkg-divert --list "$package" | \
	grep -xFq "diversion of $file to $theirfile by $package"; then
	dpkg-divert --divert "$theirfile" --rename --package "$package" --add "$file"
    fi
    if [ ! -L "$file" ] && [ ! -e "$file" ]; then
	ln -s "$(basename "$ourfile")" "$file"
    elif [ ! -L "$file" ] || \
	[ "$(readlink "$file")" != "$(basename "$ourfile")" -a \
	  "$(readlink "$file")" != "$(basename "$theirfile")" ]; then
	echo "*** OMINOUS WARNING ***: $file is not linked to either $(basename "$ourfile") or $(basename "$theirfile")" >&2
    fi
}

undivert_unlink()
{
    prefix=$1
    suffix=$2

    file=$prefix$suffix
    ourfile=$prefix$ours$suffix
    theirfile=$prefix$theirs$suffix

    if [ ! -L "$file" ] || \
	[ "$(readlink "$file")" != "$(basename "$ourfile")" -a \
	  "$(readlink "$file")" != "$(basename "$theirfile")" ]; then
	echo "*** OMINOUS WARNING ***: $file is not linked to either $(basename "$ourfile") or $(basename "$theirfile")" >&2
    else
	rm -f "$file"
    fi
    if [ ! -L "$file" ] && [ ! -e "$file" ]; then
	dpkg-divert --remove --rename --package "$package" "$file"
    else
	echo "Not removing diversion of $file by $package" >&2
    fi
}

