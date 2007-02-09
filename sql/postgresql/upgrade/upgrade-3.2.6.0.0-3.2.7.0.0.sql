-- upgrade-3.2.6.0.0-3.2.7.0.0.sql

-- include_in_search_p
alter table im_dynfield_attributes add include_in_search_p char(1);
alter table im_dynfield_attributes alter column include_in_search_p set default 'f';
update im_dynfield_attributes set include_in_search_p = 'f';
alter table im_dynfield_attributes 
	add constraint im_dynfield_attributes_search_ch 
	check (include_in_search_p in ('t','f'));


-- deref_plpgsql_function
alter table im_dynfield_widgets
add deref_plpgsql_function varchar(100);
alter table im_dynfield_widgets alter column deref_plpgsql_function set default 'im_name_from_id';
update im_dynfield_widgets set deref_plpgsql_function = 'im_name_from_id';

