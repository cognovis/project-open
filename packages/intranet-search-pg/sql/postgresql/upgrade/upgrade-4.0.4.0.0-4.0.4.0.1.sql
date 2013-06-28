-- upgrade-4.0.4.0.0-4.0.4.0.1.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-4.0.4.0.0-4.0.4.0.1.sql','');


-----------------------------------------------------------
-- Configuration Item

create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	select	count(*) into v_count from im_search_object_types
	where	object_type = 'im_conf_item';
	if v_count = 1 then return 1; end if;

	insert into im_search_object_types values (9,'im_conf_item',0.8);

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-----------------------------------------------------------
-- Full-Text Search for Conf Items
-----------------------------------------------------------


create or replace function im_conf_items_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select	coalesce(c.conf_item_code, '''') || '' '' ||
		coalesce(c.conf_item_name, '''') || '' '' ||
		coalesce(c.conf_item_nr, '''') || '' '' ||
		coalesce(c.conf_item_version, '''') || '' '' ||
		coalesce(c.description, '''') || '' '' ||
		coalesce(c.ip_address, '''') || '' '' ||
		coalesce(c.note, '''') || '' '' ||
		coalesce(c.ocs_deviceid, '''') || '' '' ||
		coalesce(c.ocs_id, '''') || '' '' ||
		coalesce(c.ocs_username, '''') || '' '' ||
		coalesce(c.os_comments, '''') || '' '' ||
		coalesce(c.os_name, '''') || '' '' ||
		coalesce(c.os_version, '''') || '' '' ||
		coalesce(c.processor_text, '''') || '' '' ||
		coalesce(c.win_company, '''') || '' '' ||
		coalesce(c.win_owner, '''') || '' '' ||
		coalesce(c.win_product_id, '''') || '' '' ||
		coalesce(c.win_product_key, '''') || '' '' ||
		coalesce(c.win_userdomain, '''') || '' '' ||
		coalesce(c.win_workgroup, '''')
	into    v_string
	from    im_conf_items c
	where   c.conf_item_id = new.conf_item_id;

	perform im_search_update(new.conf_item_id, ''im_conf_item'', new.conf_item_id, v_string);

	return new;
end;' language 'plpgsql';



create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	select	count(*) into v_count from pg_trigger
	where	lower(tgname) = 'im_conf_items_tsearch_tr';
	IF v_count = 1 THEN return 1; END IF;

	CREATE TRIGGER im_conf_items_tsearch_tr
	AFTER INSERT or UPDATE
	ON im_conf_items
	FOR EACH ROW
	EXECUTE PROCEDURE im_conf_items_tsearch();

	update im_conf_items set conf_item_name = conf_item_name;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function content_item__name (integer) returns varchar as '
DECLARE
	v_content_item_id alias for $1;
	v_name varchar;
BEGIN
	select	name into v_name
	from	cr_items 
	where	item_id = v_content_item_id;

	return v_name;
end;' language 'plpgsql';


