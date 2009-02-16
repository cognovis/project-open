-- upgrade-3.2.2.0.0-3.2.3.0.0.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.2.2.0.0-3.2.3.0.0.sql','');


create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as '
declare
	p_object_id     alias for $1;
	p_object_type   alias for $2;
	p_biz_object_id alias for $3;
	p_text	  alias for $4;

	v_object_type_id	integer;
	v_exists_p	      integer;
begin
	select  object_type_id
	into    v_object_type_id
	from    im_search_object_types
	where   object_type = p_object_type;

	select  count(*)
	into    v_exists_p
	from    im_search_objects
	where   object_id = p_object_id
		and object_type_id = v_object_type_id;

	if v_exists_p = 1 then
		update im_search_objects set
			object_type_id  = v_object_type_id,
			biz_object_id   = p_biz_object_id,
			fti	     = to_tsvector(''default'', norm_text(p_text))
		where
			object_id       = p_object_id
			and object_type_id = v_object_type_id;
	else
		insert into im_search_objects (
			object_id,
			object_type_id,
			biz_object_id,
			fti
		) values (
			p_object_id,
			v_object_type_id,
			p_biz_object_id,
			to_tsvector(''default'', p_text)
		);
	end if;

	return 0;
end;' language 'plpgsql';



-- Relative weight of the object type.
-- Highly relevant types with few objectys
-- (companies, users) should get a very high
-- weight (max. 10), while files should have
-- low weights (min. 0.1)


create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select  count(*) into v_count from user_tab_columns
	where   lower(table_name) = ''im_search_object_types''
		and lower(column_name) = ''rel_weight'';
	if v_count = 1 then return 0;end if;

	alter table im_search_object_types add rel_weight numeric(5,2);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-- Set relative weights of objects
-- according to the number of objects available.
-- 
update im_search_object_types set rel_weight = 2 where object_type = 'im_project';
update im_search_object_types set rel_weight = 5 where object_type = 'user';
update im_search_object_types set rel_weight = 0.3 where object_type = 'im_forum_topic';
update im_search_object_types set rel_weight = 10 where object_type = 'im_company';
update im_search_object_types set rel_weight = 1 where object_type = 'im_invoice';
-- update im_search_object_types set rel_weight = 0.2 where object_type = '<email>';
update im_search_object_types set rel_weight = 0.1 where object_type = 'im_fs_file';

