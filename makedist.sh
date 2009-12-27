#!/bin/bash
#
# makedist.sh: script to make rottlog release tarball.
# Copyright 2002, 2003, 2004 Stefano Falsetto <falsetto@gnu.org>
# Copyright 2008 David Egan Evans <sinuhe@gnu.org>
#
# This program is free software.  You can redistribute it, or modify it,
# or both, under the terms of the GNU General Public License version 3
# (or any later version) as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses>.
#

# Declare default variables
MAINPRG="rottlog"
MAINDIR="src/"
VER="ver"
EDIT="src/virottrc"
source ./VERSION
VER_FILE="$MAINPRG-$(date "+%d-%m-%Y-%H.%M.%S")"
MAIL="[sinuhe@gnu\.org]"

# Make temp directories for build environment.
mkdir -p tmp
mkdir -p ver/src
mkdir -p tar

# Modify rottlog to match declared variables.
cp -v $MAINDIR/$MAINPRG $VER/$VER_FILE
echo "Updating variables:"
echo "VERSION=$VERSION"
echo "MAINDIR=@MAINDIR"
echo "MAINRC=\$MAINDIR/rc"
echo "STATDIR=/var/run/rottlog"
echo "DEBUG="
echo
echo -n "rottlog, "
sed -e "s/^VERSION=.*/VERSION=\"$VERSION\"/"  \
    -e 's/^MAINDIR=.*/MAINDIR=\"\@MAINDIR\"/' \
    -e 's/^MAINRC=.*/MAINRC=\"\$MAINDIR\/rc\"/' \
    -e 's/^STATDIR=.*/STATDIR=\"\@STATDIR\"/' \
    -e 's/^LOCK=.*/LOCK=\"@LOCKFILE\"/' \
    -e 's/^DEBUG=.*/DEBUG=/' $MAINDIR/$MAINPRG >tmp/newrottlog
if [ ! -s tmp/newrottlog ]; then
	echo "ERROR EXECUTING SED!!"
	echo "PLEASE CHECK WHAT HAPPENED!!"
	exit 3
fi

# Modify virottrc to integrate declared variables.
echo -n "virottrc, "
chmod 0700 $MAINDIR/$MAINPRG
sed -e 's/^MAINDIR=.*/MAINDIR=\"\@MAINDIR\"/' $EDIT >tmp/virottrc
if [ ! -s tmp/virottrc ]; then
	echo "ERROR EXECUTING SED!!"
	echo "PLEASE CHECK WHAT HAPPENED!!"
	exit 4
fi
cp -v $EDIT $VER/$EDIT-$(date "+%d-%m-%Y-%H.%M.%S")
#mv tmp/virottrc $EDIT
chmod 0700 $EDIT
  
# Update configure script to integrate declared variables,
# and prepare for build environment.
echo -n "configure.ac, "
sed -e s/\@VERSION/$VERSION/ \
    -e "s/AC_INIT.*/AC_INIT(rottlog,$VERSION,$MAIL)/" \
    configure.ac >tmp/configure.ac
if [ ! -s tmp/configure.ac ]; then
	echo "ERROR EXECUTING SED!!"
	echo "PLEASE CHECK WHAT HAPPENED!!"
	exit 5
fi
cp tmp/configure.ac configure.ac
aclocal
automake --add-missing
autoconf
./configure

# Assemble package tree structure and integrate files.
mkdir -p tmp/$MAINPRG-$VERSION
mkdir -p tmp/$MAINPRG-$VERSION/src
mkdir -p tmp/$MAINPRG-$VERSION/rc
mkdir -p tmp/$MAINPRG-$VERSION/doc

cat -s FILES |grep -v  "^#"|while read i; do
cp -rv ./$i tmp/$MAINPRG-$VERSION/$i
done
cp -v tmp/newrottlog tmp/$MAINPRG-$VERSION/src/rottlog
cp -v tmp/virottrc tmp/$MAINPRG-$VERSION/src/virottrc
cp -v tmp/configure.ac tmp/$MAINPRG-$VERSION/configure.ac

# Get rid of Arch cruft.
echo "Poof to Arch cruft? (Press Enter to create tarball):"
read i
if [ "$i" = "" ]; then
	cd tmp
	find $MAINPRG-$VERSION -name '{arch}' -type d -exec rm -Rf {} \;
fi

# Make the archive
tar cfvz ../tar/$MAINPRG-$VERSION.tar.gz $MAINPRG-$VERSION
if [ $? -ne 0 ]; then
	echo "An error occurred while assembling the tar ball."
	exit 2;
fi
rm -Rf $MAINPRG-$VERSION
cd ..

# Check for gpg2 (requires gpg-agent)
echo "GPG signing tarball..."
if [ -x /usr/bin/gpg ]; then
	gpg -b tar/$MAINPRG-$VERSION.tar.gz
	gpg --clearsign tar/$MAINPRG-$VERSION.tar.gz
elif [ -x /usr/local/bin/gpg ]; then
	gpg -b tar/$MAINPRG-$VERSION.tar.gz
	gpg --clearsign tar/$MAINPRG-$VERSION.tar.gz
else
	gpg2 -b tar/$MAINPRG-$VERSION.tar.gz
	gpg2 --clearsign tar/$MAINPRG-$VERSION.tar.gz
fi

[ ! -z "$1" ] && exit

