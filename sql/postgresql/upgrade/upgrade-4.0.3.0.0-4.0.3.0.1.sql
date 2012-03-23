-- upgrade-4.0.3.0.0-4.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');


-----------------------------------------------------------
-- wiki / bt

create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	select	count(*) into v_count from im_search_object_types
	where	object_type = 'content_item';
	if v_count = 1 then return 1; end if;

	insert into im_search_object_types values (7,'content_item',0.5);

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function content_item_tsearch ()
returns trigger as '
declare
	v_string varchar;
	v_string2 varchar;
begin
	select	coalesce(name, '''') || '' '' || coalesce(content, '''')
	into	v_string
	from	cr_items, cr_revisions 
	where	cr_items.latest_revision=cr_revisions.revision_id
		and cr_items.item_id=new.item_id;

	perform im_search_update(new.item_id, ''content_item'', new.item_id, v_string);

	return new;
end;' language 'plpgsql';



create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	select	count(*) into v_count from pg_trigger
	where	lower(tgname) = 'cr_items_tsearch_tr';
	IF v_count = 1 THEN return 1; END IF;

	CREATE TRIGGER cr_items_tsearch_tr
	BEFORE INSERT or UPDATE
	ON cr_items
	FOR EACH ROW 
	EXECUTE PROCEDURE content_item_tsearch();

	update cr_items set locale = locale;

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

