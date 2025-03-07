#!/bin/sh
#
# shell script to create Bacula PostgreSQL tables
#
# Copyright (C) 2000-2022 Kern Sibbald
# License: BSD 2-Clause; see file LICENSE-FOSS
#
# Important note: 
#   You won't get any support for performance issue if you changed the default
#   schema.
#
bindir=/usr/lib/postgresql/15/bin
PATH="$bindir:$PATH"
db_name=${db_name:-bacula}

psql -f - -d ${db_name} $* <<END-OF-DATA

CREATE TABLE TagJob
(
   JobId integer not null,
   Tag   text    not null,
   primary key (JobId, Tag)
);

CREATE TABLE TagClient
(
   ClientId integer not null,
   Tag      text    not null,
   primary key (ClientId, Tag)
);

CREATE TABLE TagMedia
(
   MediaId integer not null,
   Tag      text    not null,
   primary key (MediaId, Tag)
);

CREATE TABLE TagObject
(
   ObjectId integer not null,
   Tag      text    not null,
   primary key (ObjectId, Tag)
);

CREATE TABLE Object
(
   ObjectId     bigserial  not null,

   JobId        integer  not null,
   Path         text     not null,
   Filename     text     not null,
   PluginName   text     not null,

   ObjectCategory  text     not null,
   ObjectType      text     not null,
   ObjectName      text     not null,
   ObjectSource    text     not null,
   ObjectUUID      text     not null,
   ObjectSize      bigint   not null,
   ObjectStatus	 char(1)	 not null default 'U',
   ObjectCount     integer  not null default 1,
   primary key (ObjectId)
);

create index object_jobid_idx on Object (JobId);
create index object_category_idx on Object (ObjectCategory);
create index object_type_idx on Object  (ObjectType);
create index object_name_idx on Object  (ObjectName);
create index object_source_idx on Object  (ObjectSource);
create index object_status_idx on Object  (ObjectStatus);

CREATE TABLE Events
(
    EventsId          serial	  not null,
    EventsCode        text        not null,
    EventsType	      text	  not null,
    EventsTime	      timestamp   without time zone,
    EventsInsertTime  timestamp   without time zone DEFAULT NOW(),
    EventsDaemon        text        default '',
    EventsSource      text        default '',
    EventsRef         text        default '',
    EventsText	      text	  not null,
    primary key (EventsId)
);
create index events_time_idx on Events (EventsTime);

CREATE TABLE Path
(
    PathId	      serial	  not null,
    Path	      text	  not null,
    primary key (PathId)
);

ALTER TABLE Path ALTER COLUMN Path SET STATISTICS 1000;
CREATE UNIQUE INDEX path_name_idx on Path (Path text_pattern_ops);

-- We strongly recommend to avoid the temptation to add new indexes.
-- In general, these will cause very significant performance
-- problems in other areas.  A better approch is to carefully check
-- that all your memory configuation parameters are
-- suitable for the size of your installation.	If you backup
-- millions of files, you need to adapt the database memory
-- configuration parameters concerning sorting, joining and global
-- memory.  By default, sort and join parameters are very small
-- (sometimes 8Kb), and having sufficient memory specified by those
-- parameters is extremely important to run fast.  

-- In File table
-- FileIndex can be 0 for FT_DELETED files
-- FileName can be '' for directories
CREATE TABLE File
(
    FileId	      bigserial   not null,
    FileIndex	      integer	  not null  default 0,
    JobId	      integer	  not null,
    PathId	      integer	  not null,
    Filename	      text	  not null  default '',
    DeltaSeq	      smallint	  not null  default 0,
    MarkId	      integer	  not null  default 0,
    LStat	      text	  not null,
    Md5 	      text	  not null,
    primary key (FileId)
);

CREATE INDEX file_jpfid_idx on File (JobId, PathId, Filename text_pattern_ops);

--
-- Add this if you have a good number of job
-- that run at the same time
-- ALTER SEQUENCE file_fileid_seq CACHE 10;

--
-- Possibly add one or more of the following indexes
--  if your Verifies are too slow, but they can slow down
--  backups.
--
-- CREATE INDEX file_pathid_idx on file(PathId);
-- CREATE INDEX file_filename_idx on file(Filename);

CREATE TABLE RestoreObject (
   RestoreObjectId SERIAL NOT NULL,
   ObjectName TEXT NOT NULL,
   RestoreObject BYTEA NOT NULL,
   PluginName TEXT NOT NULL,
   ObjectLength INTEGER DEFAULT 0,
   ObjectFullLength INTEGER DEFAULT 0,
   ObjectIndex INTEGER DEFAULT 0,
   ObjectType INTEGER DEFAULT 0,
   FileIndex INTEGER DEFAULT 0,
   JobId INTEGER,
   ObjectCompression INTEGER DEFAULT 0,
   PRIMARY KEY(RestoreObjectId)
   );
CREATE INDEX restore_jobid_idx on RestoreObject(JobId);


CREATE TABLE Job
(
    JobId	      serial	  not null,
    Job 	      text	  not null,
    Name	      text	  not null,
    Type	      char(1)	  not null,
    Level	      char(1)	  not null,
    ClientId	      integer	  default 0,
    JobStatus	      char(1)	  not null,
    SchedTime	      timestamp   without time zone,
    StartTime	      timestamp   without time zone,
    EndTime	      timestamp   without time zone,
    RealEndTime       timestamp   without time zone,
    JobTDate	      bigint	  default 0,
    VolSessionId      integer	  default 0,
    VolSessionTime    integer	  default 0,
    JobFiles	      integer	  default 0,
    JobBytes	      bigint	  default 0,
    ReadBytes	      bigint	  default 0,
    JobErrors	      integer	  default 0,
    JobMissingFiles   integer	  default 0,
    PoolId	      integer	  default 0,
    FilesetId	      integer	  default 0,
    PriorJobid	      integer	  default 0,
    PriorJob          text        default '',
    PurgedFiles       smallint	  default 0,
    HasBase	      smallint	  default 0,
    HasCache	      smallint	  default 0,
    Reviewed	      smallint	  default 0,
    Comment	      text,
    FileTable	      text	  default 'File',
    primary key (jobid)
);

CREATE INDEX job_name_idx on job (name text_pattern_ops);

-- Create a table like Job for long term statistics 
CREATE TABLE JobHisto (LIKE Job);
CREATE INDEX jobhisto_idx ON JobHisto ( StartTime );


CREATE TABLE Location (
   LocationId	      serial	  not null,
   Location	      text	  not null,
   Cost 	      integer	  default 0,
   Enabled	      smallint,
   primary key (LocationId)
);


CREATE TABLE fileset
(
    filesetid	      serial	  not null,
    fileset	      text	  not null,
    md5 	      text	  not null,
    createtime	      timestamp without time zone not null,
    primary key (filesetid)
);

CREATE INDEX fileset_name_idx on fileset (fileset text_pattern_ops);

CREATE TABLE jobmedia
(
    jobmediaid	      serial	  not null,
    jobid	      integer	  not null,
    mediaid	      integer	  not null,
    firstindex	      integer	  default 0,
    lastindex	      integer	  default 0,
    startfile	      integer	  default 0,
    endfile	      integer	  default 0,
    startblock	      bigint	  default 0,
    endblock	      bigint	  default 0,
    volindex	      integer	  default 0,
    primary key (jobmediaid)
);

CREATE INDEX job_media_job_id_media_id_idx on jobmedia (jobid, mediaid);
CREATE INDEX job_media_media_id_idx on jobmedia (mediaid);

CREATE TABLE FileMedia
(
    JobId	      integer	  not null,
    FileIndex	      integer	  not null,
    MediaId	      integer	  not null,
    BlockAddress      bigint	  default 0,
    RecordNo	      integer	  default 0,
    FileOffset	      bigint	  default 0
);
CREATE INDEX file_media_idx on FileMedia (JobId, FileIndex);

CREATE TABLE media
(
    mediaid	      serial	  not null,
    volumename	      text	  not null,
    slot	      integer	  default 0,
    poolid	      integer	  default 0,
    mediatype	      text	  not null,
    mediatypeid       integer	  default 0,
    labeltype	      integer	  default 0,
    firstwritten      timestamp   without time zone,
    lastwritten       timestamp   without time zone,
    labeldate	      timestamp   without time zone,
    voljobs	      integer	  default 0,
    volfiles	      integer	  default 0,
    volblocks	      integer	  default 0,
    volparts	      integer	  default 0,
    volcloudparts     integer	  default 0,
    volmounts	      integer	  default 0,
    volbytes	      bigint	  default 0,
    volabytes	      bigint	  default 0,
    volapadding       bigint	  default 0,
    volholebytes      bigint	  default 0,
    volholes	      integer	  default 0,
    voltype	      integer	  default 0,
    volerrors	      integer	  default 0,
    volwrites	      bigint	  default 0,
    volcapacitybytes  bigint	  default 0,
    lastpartbytes     bigint	  default 0,
    volstatus	      text	  not null
	check (volstatus in ('Full','Archive','Append',
	      'Recycle','Purged','Read-Only','Disabled',
	      'Error','Busy','Used','Cleaning','Scratch')),
    enabled	      smallint	  default 1,
    recycle	      smallint	  default 0,
    ActionOnPurge     smallint	  default 0,
    cacheretention    bigint      default 0,
    volretention      bigint	  default 0,
    voluseduration    bigint	  default 0,
    maxvoljobs	      integer	  default 0,
    maxvolfiles       integer	  default 0,
    maxvolbytes       bigint	  default 0,
    inchanger	      smallint	  default 0,
    StorageId	      integer	  default 0,
    DeviceId	      integer	  default 0,
    mediaaddressing   smallint	  default 0,
    volreadtime       bigint	  default 0,
    volwritetime      bigint	  default 0,
    endfile	      integer	  default 0,
    endblock	      bigint	  default 0,
    LocationId	      integer	  default 0,
    recyclecount      integer	  default 0,
    initialwrite      timestamp   without time zone,
    scratchpoolid     integer	  default 0,
    recyclepoolid     integer	  default 0,
    comment	      text,
    primary key (mediaid)
);

CREATE UNIQUE INDEX media_volumename_id ON Media (VolumeName text_pattern_ops);
CREATE INDEX media_poolid_idx ON Media (PoolId);
CREATE INDEX media_storageid_idx ON Media (StorageId);
 
CREATE TABLE MediaType (
   MediaTypeId SERIAL,
   MediaType TEXT NOT NULL,
   ReadOnly INTEGER DEFAULT 0,
   PRIMARY KEY(MediaTypeId)
   );

CREATE TABLE Storage (
   StorageId SERIAL,
   Name TEXT NOT NULL,
   AutoChanger INTEGER DEFAULT 0,
   PRIMARY KEY(StorageId)
   );

CREATE TABLE Device (
   DeviceId SERIAL,
   Name TEXT NOT NULL,
   MediaTypeId INTEGER NOT NULL,
   StorageId INTEGER NOT NULL,
   DevMounts INTEGER NOT NULL DEFAULT 0,
   DevReadBytes BIGINT NOT NULL DEFAULT 0,
   DevWriteBytes BIGINT NOT NULL DEFAULT 0,
   DevReadBytesSinceCleaning BIGINT NOT NULL DEFAULT 0,
   DevWriteBytesSinceCleaning BIGINT NOT NULL DEFAULT 0,
   DevReadTime BIGINT NOT NULL DEFAULT 0,
   DevWriteTime BIGINT NOT NULL DEFAULT 0,
   DevReadTimeSinceCleaning BIGINT NOT NULL DEFAULT 0,
   DevWriteTimeSinceCleaning BIGINT NOT NULL DEFAULT 0,
   CleaningDate timestamp without time zone,
   CleaningPeriod BIGINT NOT NULL DEFAULT 0,
   PRIMARY KEY(DeviceId)
   );


CREATE TABLE pool
(
    poolid	      serial	  not null,
    name	      text	  not null,
    numvols	      integer	  default 0,
    maxvols	      integer	  default 0,
    useonce	      smallint	  default 0,
    usecatalog	      smallint	  default 0,
    acceptanyvolume   smallint	  default 0,
    volretention      bigint	  default 0,
    cacheretention    bigint	  default 0,
    voluseduration    bigint	  default 0,
    maxvoljobs	      integer	  default 0,
    maxvolfiles       integer	  default 0,
    maxvolbytes       bigint	  default 0,
    maxpoolbytes      bigint      default 0,
    autoprune	      smallint	  default 0,
    recycle	      smallint	  default 0,
    ActionOnPurge     smallint	  default 0,
    pooltype	      text			    
      check (pooltype in ('Backup','Copy','Cloned','Archive','Migration','Scratch')),
    labeltype	      integer	  default 0,
    labelformat       text	  not null,
    enabled	      smallint	  default 1,
    scratchpoolid     integer	  default 0,
    recyclepoolid     integer	  default 0,
    NextPoolId	      integer	  default 0,
    MigrationHighBytes BIGINT	  DEFAULT 0,
    MigrationLowBytes  BIGINT	  DEFAULT 0,
    MigrationTime      BIGINT	  DEFAULT 0,
    primary key (poolid)
);

CREATE INDEX pool_name_idx on pool (name text_pattern_ops);

CREATE TABLE client
(
    clientid	      serial	  not null,
    name	      text	  not null,
    uname	      text	  not null,
    autoprune	      smallint	  default 0,
    fileretention     bigint	  default 0,
    jobretention      bigint	  default 0,
    primary key (clientid)
);

create unique index client_name_idx on client (name text_pattern_ops);

CREATE TABLE Log
(
    LogId	      serial	  not null,
    JobId	      integer	  not null,
    Time	      timestamp   without time zone,
    LogText	      text	  not null,
    primary key (LogId)
);
create index log_name_idx on Log (JobId);

CREATE TABLE LocationLog (
   LocLogId SERIAL NOT NULL,
   Date timestamp   without time zone,
   Comment TEXT NOT NULL,
   MediaId INTEGER DEFAULT 0,
   LocationId INTEGER DEFAULT 0,
   newvolstatus text not null
	check (newvolstatus in ('Full','Archive','Append',
	      'Recycle','Purged','Read-Only','Disabled',
	      'Error','Busy','Used','Cleaning','Scratch')),
   newenabled smallint,
   PRIMARY KEY(LocLogId)
);



CREATE TABLE counters
(
    counter	      text	  not null,
    minvalue	      integer	  default 0,
    maxvalue	      integer	  default 0,
    currentvalue      integer	  default 0,
    wrapcounter       text	  not null,
    primary key (counter)
);



CREATE TABLE basefiles
(
    baseid	      bigserial		    not null,
    jobid	      integer		    not null,
    fileid	      bigint		    not null,
    fileindex	      integer		   default 0,
    basejobid	      integer			    ,
    primary key (baseid)
);

CREATE INDEX basefiles_jobid_idx ON BaseFiles ( JobId );

CREATE TABLE unsavedfiles
(
    UnsavedId	      integer		    not null,
    jobid	      integer		    not null,
    pathid	      integer		    not null,
    filename	      text		    not null,
    primary key (UnsavedId)
);

CREATE TABLE CDImages 
(
   MediaId integer not null,
   LastBurn timestamp without time zone not null,
   primary key (MediaId)
);


CREATE TABLE PathHierarchy
(
     PathId integer NOT NULL,
     PPathId integer NOT NULL,
     CONSTRAINT pathhierarchy_pkey PRIMARY KEY (PathId)
);

CREATE INDEX pathhierarchy_ppathid 
	  ON PathHierarchy (PPathId);

CREATE TABLE PathVisibility
(
      PathId integer NOT NULL,
      JobId integer NOT NULL,
      Size int8 DEFAULT 0,
      Files int4 DEFAULT 0,
      CONSTRAINT pathvisibility_pkey PRIMARY KEY (JobId, PathId)
);
CREATE INDEX pathvisibility_jobid
	     ON PathVisibility (JobId);

CREATE TABLE version
(
    versionid	      integer		    not null
);

CREATE TABLE Status (
   JobStatus CHAR(1) NOT NULL,
   JobStatusLong TEXT,
   Severity int,
   PRIMARY KEY (JobStatus)
   );

INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('C', 'Created, not yet running',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('R', 'Running',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('B', 'Blocked',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('T', 'Completed successfully', 10);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('E', 'Terminated with errors', 25);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('e', 'Non-fatal error',20);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('f', 'Fatal error',100);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('D', 'Verify found differences',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('A', 'Canceled by user',90);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('F', 'Waiting for Client',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('S', 'Waiting for Storage daemon',15);
INSERT INTO Status (JobStatus,JobStatusLong) VALUES
   ('m', 'Waiting for new media');
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('M', 'Waiting for media mount',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('s', 'Waiting for storage resource',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('j', 'Waiting for job resource',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('c', 'Waiting for client resource',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('d', 'Waiting on maximum jobs',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('t', 'Waiting on start time',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('p', 'Waiting on higher priority jobs',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('a', 'SD despooling attributes',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('i', 'Doing batch insert file records',15);
INSERT INTO Status (JobStatus,JobStatusLong,Severity) VALUES
   ('I', 'Incomplete Job',25);

CREATE TABLE Snapshot (
  SnapshotId	  serial,
  Name		  text not null,
  JobId 	  integer default 0,
  FileSetId	  integer default 0,
  CreateTDate	  bigint default 0,
  CreateDate	  timestamp without time zone not null,
  ClientId	  int default 0,
  Volume	  text not null,
  Device	  text not null,
  Type		  text not null,
  Retention	  integer default 0,
  Comment	  text,
  primary key (SnapshotId)
);

CREATE UNIQUE INDEX snapshot_idx ON Snapshot (Device text_pattern_ops, 
					      Volume text_pattern_ops,
					      Name text_pattern_ops);

INSERT INTO Version (VersionId) VALUES (1024);

-- Make sure we have appropriate permissions


END-OF-DATA
pstat=$?
if test $pstat = 0; 
then
   echo "Creation of Bacula PostgreSQL tables succeeded."
else
   echo "Creation of Bacula PostgreSQL tables failed."
fi
exit $pstat
