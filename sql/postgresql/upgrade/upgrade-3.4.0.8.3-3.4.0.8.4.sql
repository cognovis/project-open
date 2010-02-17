--  upgrade-3.4.0.8.3-3.4.0.8.4.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.3-3.4.0.8.4.sql','');


-- Replace the hardcoded workflows stages by information
-- in the aux_string1 field of translation tasks.

update im_categories set aux_string1 = 'trans edit'	where category_id = 87;
update im_categories set aux_string1 = 'edit'		where category_id = 88;
update im_categories set aux_string1 = 'trans edit proof' where category_id = 89;
update im_categories set aux_string1 = 'other'		where category_id = 90;
update im_categories set aux_string1 = 'other'		where category_id = 91;
update im_categories set aux_string1 = 'other'		where category_id = 92;
update im_categories set aux_string1 = 'trans'		where category_id = 93;
update im_categories set aux_string1 = 'trans edit'	where category_id = 94;
update im_categories set aux_string1 = 'proof'		where category_id = 95;
update im_categories set aux_string1 = 'other'		where category_id = 96;

