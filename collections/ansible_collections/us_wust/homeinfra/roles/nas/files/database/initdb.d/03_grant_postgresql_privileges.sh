#!/bin/sh
#
# shell script to grant privileges to the bacula database
#
# Copyright (C) 2000-2022 Kern Sibbald
# License: BSD 2-Clause; see file LICENSE-FOSS
#
db_user=${db_user:-bacula}
bindir=/usr/lib/postgresql/15/bin
PATH="$PATH:$bindir"
db_name=${db_name:-bacula}
db_password=`cat /run/secrets/postgres-bacula-password`
if [ "$db_password" != "" ]; then
   pass="password '$db_password'"
fi


psql -f - -d ${db_name} $* <<END-OF-DATA

create user ${db_user} ${pass};

-- for the database
alter database ${db_name} owner to ${db_user} ;

-- for tables
grant all on TagJob       to ${db_user};
grant all on TagClient    to ${db_user};
grant all on TagMedia     to ${db_user};
grant all on TagObject    to ${db_user};
grant all on Object       to ${db_user};
grant all on Events       to ${db_user};
grant all on unsavedfiles to ${db_user};
grant all on basefiles	  to ${db_user};
grant all on jobmedia	  to ${db_user};
grant all on filemedia	  to ${db_user};
grant all on file	  to ${db_user};
grant all on job	  to ${db_user};
grant all on media	  to ${db_user};
grant all on client	  to ${db_user};
grant all on pool	  to ${db_user};
grant all on fileset	  to ${db_user};
grant all on path	  to ${db_user};
grant all on counters	  to ${db_user};
grant all on version	  to ${db_user};
grant all on cdimages	  to ${db_user};
grant all on mediatype	  to ${db_user};
grant all on storage	  to ${db_user};
grant all on device	  to ${db_user};
grant all on status	  to ${db_user};
grant all on location	  to ${db_user};
grant all on locationlog  to ${db_user};
grant all on log	  to ${db_user};
grant all on jobhisto	  to ${db_user};
grant all on PathHierarchy  to ${db_user};
grant all on PathVisibility to ${db_user};
grant all on RestoreObject to ${db_user};
grant all on Snapshot to ${db_user};
-- for sequences on those tables

grant select, update on events_eventsid_seq 	   to ${db_user};
grant select, update on path_pathid_seq 	   to ${db_user};
grant select, update on fileset_filesetid_seq	   to ${db_user};
grant select, update on pool_poolid_seq 	   to ${db_user};
grant select, update on client_clientid_seq	   to ${db_user};
grant select, update on media_mediaid_seq	   to ${db_user};
grant select, update on job_jobid_seq		   to ${db_user};
grant select, update on file_fileid_seq 	   to ${db_user};
grant select, update on jobmedia_jobmediaid_seq    to ${db_user};
grant select, update on basefiles_baseid_seq	   to ${db_user};
grant select, update on storage_storageid_seq	   to ${db_user};
grant select, update on mediatype_mediatypeid_seq  to ${db_user};
grant select, update on device_deviceid_seq	   to ${db_user};
grant select, update on location_locationid_seq    to ${db_user};
grant select, update on locationlog_loclogid_seq   to ${db_user};
grant select, update on log_logid_seq		   to ${db_user};
grant select, update on restoreobject_restoreobjectid_seq to ${db_user};
grant select, update on object_objectid_seq to ${db_user};
grant select, update on snapshot_snapshotid_seq to ${db_user};
END-OF-DATA
if [ $? -eq 0 ]
then
   echo "Privileges for user ${db_user} granted on database ${db_name}."
   exit 0
else
   echo "Error creating privileges."
   exit 1
fi
