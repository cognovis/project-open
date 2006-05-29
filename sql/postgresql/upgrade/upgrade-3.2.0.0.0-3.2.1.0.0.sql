-------------------------------------------------------------
-- upgrade-3.2.0.0.0-3.2.1.0.0.sql
-------------------------------------------------------------




-------------------------------------------------------------
-- Extend im_categories with "aux" fields

alter table im_categories add
aux_int1 integer;

alter table im_categories add
aux_int2 integer;

alter table im_categories add
aux_string1 varchar(1000);

alter table im_categories add
aux_string2 varchar(1000);

update im_categories
set aux_string1 = category_description;
