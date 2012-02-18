-- upgrade-0.4d-0.5d1.sql

SELECT acs_log__debug('packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.4d-0.5d1.sql','');

create or replace function im_link_from_id (integer) returns varchar as '
DECLARE
	p_object_id	alias for $1;
	v_name		varchar;
        v_url		varchar;
BEGIN
	select	im_name_from_id (p_object_id)
	into	v_name;

	select url
	into v_url
	from im_biz_object_urls ibou, acs_objects ao
	where ibou.object_type = ao.object_type
	and ao.object_id = p_object_id;

	return ''<a href='' || v_url || p_object_id || ''>'' || v_name || ''</a>'';
end;' language 'plpgsql';
