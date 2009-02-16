-- upgrade-3.2.9.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.2.9.0.0-3.3.0.0.0.sql','');

create or replace function persons_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select  coalesce(pa.email, '''') || '' '' ||
		coalesce(pa.url, '''') || '' '' ||
		coalesce(pe.first_names, '''') || '' '' ||
		coalesce(pe.last_name, '''') || '' '' ||
		coalesce(u.username, '''') || '' '' ||
		coalesce(u.screen_name, '''') || '' '' ||

		coalesce(home_phone, '''') || '' '' ||
		coalesce(work_phone, '''') || '' '' ||
		coalesce(cell_phone, '''') || '' '' ||
		coalesce(pager, '''') || '' '' ||
		coalesce(fax, '''') || '' '' ||
		coalesce(aim_screen_name, '''') || '' '' ||
		coalesce(msn_screen_name, '''') || '' '' ||
		coalesce(icq_number, '''') || '' '' ||

		coalesce(ha_line1, '''') || '' '' ||
		coalesce(ha_line2, '''') || '' '' ||
		coalesce(ha_city, '''') || '' '' ||
		coalesce(ha_state, '''') || '' '' ||
		coalesce(ha_postal_code, '''') || '' '' ||

		coalesce(wa_line1, '''') || '' '' ||
		coalesce(wa_line2, '''') || '' '' ||
		coalesce(wa_city, '''') || '' '' ||
		coalesce(wa_state, '''') || '' '' ||
		coalesce(wa_postal_code, '''') || '' '' ||

		coalesce(note, '''') || '' '' ||
		coalesce(current_information, '''') || '' '' ||

		coalesce(ha_cc.country_name, '''') || '' '' ||
		coalesce(wa_cc.country_name, '''') || '' '' ||

		coalesce(im_cost_center_name_from_id(department_id), '''') || '' '' ||
		coalesce(job_title, '''') || '' '' ||
		coalesce(job_description, '''') || '' '' ||
		coalesce(skills, '''') || '' '' ||
		coalesce(educational_history, '''') || '' '' ||
		coalesce(last_degree_completed, '''') || '' '' ||
		coalesce(termination_reason, '''')

	into	v_string
	from
		parties pa,
		persons pe
		LEFT OUTER JOIN users u ON (pe.person_id = u.user_id)
		LEFT OUTER JOIN users_contact uc ON (pe.person_id = uc.user_id)
		LEFT OUTER JOIN im_employees e ON (pe.person_id = e.employee_id)
		LEFT OUTER JOIN country_codes ha_cc ON (uc.ha_country_code = ha_cc.iso)
		LEFT OUTER JOIN country_codes wa_cc ON (uc.wa_country_code = wa_cc.iso)
	where
		pe.person_id  = new.person_id
		and pe.person_id = pa.party_id;

	perform im_search_update(new.person_id, ''user'', new.person_id, v_string);
	return new;
end;' language 'plpgsql';




-----------------------------------------------------------
-- wiki / bt

create or replace function inline_0 ()
returns integer as '
declare
	v_count			integer;
begin
	select	count(*) into v_count from im_search_object_types
	where	object_type = ''content_item'';
	IF v_count > 0 THEN return 0; END IF;

	insert into im_search_object_types values (7,''content_item'',0.5);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();



create or replace function content_item_tsearch ()
returns trigger as '
declare
	v_string varchar;
	v_string2 varchar;
begin
	select  coalesce(name, '''') || '' '' ||
		coalesce(content, '''')
	into	v_string
	from	cr_items, cr_revisions
	where	cr_items.latest_revision=cr_revisions.revision_id
		and cr_items.item_id=new.item_id;

	perform im_search_update(new.item_id, ''content_item'', new.item_id, v_string);

	return new;
end;' language 'plpgsql';

--
-- trigger disabled at the moment
--

-- CREATE TRIGGER cr_items_tsearch_tr
-- BEFORE INSERT or UPDATE
-- ON cr_items
-- FOR EACH ROW
-- EXECUTE PROCEDURE content_item_tsearch();


create or replace function content_item__name (integer) returns varchar as '
DECLARE
	v_content_item_id alias for $1;
	v_name varchar;
BEGIN
	select name into v_name from cr_items where item_id = v_content_item_id;
	 return v_name;
end;' language 'plpgsql';

update cr_items set name=name;

