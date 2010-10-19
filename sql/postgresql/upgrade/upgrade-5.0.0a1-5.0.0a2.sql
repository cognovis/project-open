--
-- Upgrade script for acs-kernel
-- 
-- Changes wrong unique constraint on auth_driver_params table to a primary key on authority_id, impl_id, key.
--
--
-- @author Vinod Kurup (vinod@kurup.org)
--
-- @creation-date 2004-01-15
--
-- @cvs-id $Id: upgrade-5.0.0a1-5.0.0a2.sql,v 1.2 2010/10/19 20:11:43 po34demo Exp $
--

alter table auth_driver_params drop constraint auth_driver_params_authority_id_key;
alter table auth_driver_params add constraint auth_driver_params_pk primary key (authority_id,impl_id,key);
