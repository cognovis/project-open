-- upgrade-3.2.11.0.0-3.2.12.0.0.sql


alter table im_categories add sort_order integer;
alter table im_categories alter column sort_order set default 0;
update im_categories set sort_order = category_id;

