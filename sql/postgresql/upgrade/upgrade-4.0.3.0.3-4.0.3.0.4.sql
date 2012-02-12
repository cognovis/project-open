-- upgrade-4.0.3.0.3-4.0.3.0.4.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');


-- Fix a very strange XoWiki issue due to 
-- more then one entry in the cr_text table

alter table cr_text disable trigger cr_text_tr;
delete from cr_text;
insert into cr_text (text_data) values (NULL);
alter table cr_text enable trigger cr_text_tr;

