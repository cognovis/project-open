--
-- /packages/monitoring/sql/postgresql/monitoring-drop.sql
--
-- Description: Definition for general system monitoring
--
-- @author Vinod Kurup (vinod@kurup.com) PG Port only
-- @creation-date 2002-08-17
-- @cvs-id $Id: monitoring-create.sql,v 1.2 2006/10/30 12:51:21 alessandrol Exp $
--
-- Just doing a straight port right now. I'm not sure how much of this
-- stuff is Oracle-specific and thus useless for PG.


-- simple table to gather stats from top
-- where top's output looks like this (from dev0103-001:/usr/local/bin/top): 

-- load averages:  0.21,  0.18,  0.23                   21:52:56
-- 322 processes: 316 sleeping, 3 zombie, 1 stopped, 2 on cpu
-- CPU states:  3.7% idle,  9.2% user,  7.1% kernel, 80.0% iowait,  0.0% swap
-- Memory: 1152M real, 17M free, 593M swap in use, 1432M swap free
--
--   PID USERNAME THR PRI NICE  SIZE   RES STATE   TIME    CPU COMMAND
-- 17312 oracle     1  33    0  222M  189M sleep  17:54  0.95% oracle
--  9834 root       1  33    0 2136K 1528K sleep   0:00  0.43% sshd1


create sequence ad_monitoring_top_top_id start 1;

create table ad_monitoring_top (
    top_id                      integer
                                constraint ad_mntr_top_id_pk primary key,
    timestamp                   timestamptz default current_timestamp,
    -- denormalization: an indexable column for fast time comparisons.
    timehour                    numeric(2),
    -- the three load averages taken from uptime/top
    load_avg_1                  numeric,
    load_avg_5                  numeric,
    load_avg_15                 numeric,
    -- basic stats on current memory usage
    memory_real                 numeric,
    memory_free                 numeric,
    memory_swap_free            numeric,
    memory_swap_in_use          numeric,
    -- basic stats on the number of running procedures
    procs_total                 integer,
    procs_sleeping              integer,
    procs_zombie                integer,
    procs_stopped               integer,
    procs_on_cpu                integer,
    -- basic stats on cpu usage
    cpu_idle                    numeric,
    cpu_user                    numeric,
    cpu_kernel                  numeric,
    cpu_iowait                  numeric,
    cpu_swap                    numeric
);


-- this table stores information about each of the top 10 or so
-- processes running. Every time we take a snapshot, we record
-- this basic information to help track down stray or greedy 
-- processes
create sequence ad_monitoring_top_proc_proc_id start 1;
create table ad_monitoring_top_proc (
    proc_id                     integer 
                                constraint ad_mntr_top_proc_pk primary key,
    top_id                      integer not null 
                                constraint ad_mntr_top_proc_top_id_fk 
                                references ad_monitoring_top,
    pid                         integer not null,      -- the process id  
    username                    varchar(10) not null,  -- user running this command
    threads                     integer,   -- the # of threads this proc is running
    priority                    integer,  
    nice                        integer,   -- the value of nice for this process
    proc_size                   varchar(10),
    resident_memory             varchar(10),
    state                       varchar(10),
    cpu_total_time              varchar(10),   -- total cpu time used to date
    cpu_pct                     varchar(10),   -- percentage of cpu currently used
    -- the command this process is running
    command                     varchar(30) not null 
);

-- the following table is lifted from the Oracle version, but is likely
-- not useful here. 2002-08-19 vinodk

-- Begin Estimation module datamodel.
-- the following table lists tables which are to be estimated.  
-- A scheduled proc runs 
-- analyze table <table_name> estimate statistics sample <percent_estimating>
-- where table-name is pulled from the table as is percent_estimating

create table ad_monitoring_tables_estimated (
    table_entry_id              integer 
                                constraint ad_mntr_table_estim_pk primary key,
    -- This is a table name, but we don't want it to 
    -- reference user_tables since then deleting a table
    -- would be problematic, since this would reference it
    -- Instead, in the proc we use to run this (a scheduled
    -- proc, we check to make sure the table exists.
    table_name                  varchar(40) 
                                constraint amte_table_name_nn not null,
    -- The percent of the table we estimate, defaults to 20%
    percent_estimating          integer default 20,
    last_percent_estimated      integer,
    --Do we actually want to run this?
    enabled_p                   boolean,
    last_estimated              timestamptz
); 

--Sequence for above table
create sequence ad_monitoring_tab_est_seq start 1000;


-- ad_monitoring_db

-- DROP TABLE ad_monitoring_db;

CREATE TABLE ad_monitoring_db
(
  db_id int4 NOT NULL,
  "timestamp" timestamptz DEFAULT ('now'::text)::timestamp(6) with time zone,
  timehour numeric(2),
  db_size numeric,
  size_content_repository numeric,
  CONSTRAINT ad_mntr_db_id_pk PRIMARY KEY (db_id)
) 
WITH OIDS;


-- Adicionar sequencia

CREATE SEQUENCE ad_monitoring_db_db_id  START 58;

\i df-create.sql
