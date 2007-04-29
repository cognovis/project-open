--  ================================================================================
-- Postgres SQL Script File
-- 
-- 
-- @Location: mail-tracking\sql\postgresql\acs_mail_log-drop.sql
-- 
-- @author: Nima Mazloumi
-- @creation-date: Mon May 30 17:55:50 CEST 2005
-- @cvs-id $Id$
--  ================================================================================
-- 
--

--  ======================================================
-- drop functions
--  ======================================================

drop function acs_mail_log_tr() cascade;
drop function acs_mail_log__new (integer, integer, integer, integer, varchar, varchar);
drop function acs_mail_log__delete (integer);

drop function acs_mail_tracking_request__new (integer,integer,integer);
drop function acs_mail_tracking_request__delete(integer);
drop function acs_mail_tracking_request__delete_all(integer);

--  ======================================================
--drop table
--  ======================================================

drop table acs_mail_log;
drop table acs_mail_tracking_request;