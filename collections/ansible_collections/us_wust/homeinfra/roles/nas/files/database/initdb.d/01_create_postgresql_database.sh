#!/bin/sh
#
# Copyright (C) 2000-2022 Kern Sibbald
# License: BSD 2-Clause; see file LICENSE-FOSS
#
# shell script to create Bacula database(s)
#

PATH="/usr/lib/postgresql/15/bin:$PATH"
db_name=${db_name:-bacula}

#
# use SQL_ASCII to be able to put any filename into
#  the database even those created with unusual character sets

PSQLVERSION=`psql -d template1 -c 'select version()' $* | awk '/PostgreSQL/ {print $2}' | cut -d '.' -f 1,2`

#
# Note, LC_COLLATE and LC_TYPE are needed on 8.4 and beyond, but are
#   not implemented in 8.3 or below.
#
case ${PSQLVERSION} in
   6.* | 7.* | 8.[0123])
	ENCODING="ENCODING 'SQL_ASCII'"
   ;;
   *)
	ENCODING="ENCODING 'SQL_ASCII' LC_COLLATE 'C' LC_CTYPE 'C'"
   ;;
esac



#
# Please note: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  We do not recommend that you use ENCODING 'SQL_UTF8'
#  It can result in creating filenames in the database that
#  cannot be seen or restored.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
if psql -f - -d template1 $* <<END-OF-DATA
\set ON_ERROR_STOP on
CREATE DATABASE ${db_name} $ENCODING TEMPLATE template0;
ALTER DATABASE ${db_name} SET datestyle TO 'ISO, YMD';
END-OF-DATA
then
   echo "Creation of ${db_name} database succeeded."
else
   echo " "
   echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
   echo "!!!! Creation of ${db_name} database failed. !!!!"
   echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
   exit 1
fi
if psql -l $* | grep " ${db_name}.*SQL_ASCII" >/dev/null; then 
   echo "Database encoding OK"
else
   echo " "
   echo "Database encoding bad. Do not use this database"
   echo " "
   exit 1
fi
