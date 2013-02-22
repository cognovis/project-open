-- create.role.ad_cassandracle.sql
-- 1999-12-09
-- David Ambercrobie: abe@arsdigita.com
--
-- Cassandracle normally connects as a user with DBA privleges,
-- but we can also grant select privledges to a role, then 
-- grant this role to normal database users. This allows a 
-- normal ACS Oracle user to be able to use Cassandracle
-- using the normal driver without worrying about DBA role
-- users running amok.
--
-- More privliges will be added to this role as Cassandracle evolves.
--
-- You might need to restart the server after granting this
-- role to an ACS Oracle user: granting a new role to a 
-- user seems to have no effect on currently logged in users.

-- To use:
-- 1) Log into Oracle via sqlplus
-- 2) connect internal 
-- 3) load the sql commands below
-- 4) grant role to username


create role ad_cassandracle;

-- http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch3.htm
grant select on v_$license to ad_cassandracle;
grant select on v_$parameter to ad_cassandracle;
grant select on v_$process to ad_cassandracle;
grant select on v_$sess_io to ad_cassandracle;
grant select on v_$session to ad_cassandracle; 
grant select on v_$sql to ad_cassandracle;
grant select on v_$sysstat to ad_cassandracle;
grant select on v_$waitstat to ad_cassandracle;
grant select on v_$sqltext to ad_cassandracle;
grant select on v_$session_wait to ad_cassandracle;  

-- http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#745
grant select on dba_col_comments to ad_cassandracle;
grant select on dba_cons_columns to ad_cassandracle;
grant select on dba_constraints to ad_cassandracle;
grant select on dba_data_files to ad_cassandracle;
grant select on dba_free_space to ad_cassandracle;
grant select on dba_ind_columns to ad_cassandracle;
grant select on dba_indexes to ad_cassandracle;
grant select on dba_objects to ad_cassandracle;
grant select on dba_tab_columns to ad_cassandracle;
grant select on dba_tab_comments to ad_cassandracle;
grant select on dba_source to ad_cassandracle;

-- http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#88786
-- Oracle suggests using dba_data_files instead
grant select on sys.filext$ to ad_cassandracle;

-- http://oradoc.photo.net/ora81/DOC/server.815/a67779/ch4e.htm#8578
grant comment any table to ad_cassandracle;

-- end of create.role.ad_cassandracle.sql
