-- upgrade-4.0.2.0.8-4.0.2.0.9.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.2.0.8-4.0.2.0.9.sql','');

-- Relax the role restriction for business object membership.
-- We now accept groups and possibly even companies as "members".
--
update acs_rel_types 
set object_type_two = 'acs_object' 
where rel_type = 'im_biz_object_member';
