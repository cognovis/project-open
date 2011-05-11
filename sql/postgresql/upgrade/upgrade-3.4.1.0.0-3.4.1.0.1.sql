-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');




-- Creation Date
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_dept_id'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_dept_id			integer
					constraint im_ticket_dept_fk
					references im_cost_centers;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Creation Date
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_component_id'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_component_id			integer
					constraint im_ticket_component_fk
					references im_conf_items;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'service_level_agreements', 'Service Level Agreements', 'Service Level Agreements',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	
			p.project_id,
			p.project_name
		from 
			im_projects p
		where 
			p.project_type_id = 2502 and
			p.project_status_id in (select * from im_sub_categories(76))
		order by 
			lower(project_name) 
	}}}'
);


-----------------------------------------------------------
-- Hard coded fields
--





-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1), varchar
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;
	p_pos_y			alias for $7;
	p_also_hard_coded_p	alias for $8;
	p_table_name	 	alias for $9;

	v_dynfield_id		integer;
	v_widget_id		integer;
	v_type_category		varchar;
	row			RECORD;
	v_count			integer;
	v_min_n_value		integer;
BEGIN
	select	widget_id into v_widget_id from im_dynfield_widgets
	where	widget_name = p_widget_name;
	IF v_widget_id is null THEN return 1; END IF;

	select	count(*) from im_dynfield_attributes into v_count
	where	acs_attribute_id in (
			select	attribute_id 
			from	acs_attributes 
			where	attribute_name = p_column_name and
				object_type = p_object_type
		);
	IF v_count > 0 THEN return 1; END IF;

	v_min_n_value := 0;
	IF p_required_p = ''t'' THEN  v_min_n_value := 1; END IF;

	v_dynfield_id := im_dynfield_attribute__new (
		null, ''im_dynfield_attribute'', now(), 0, ''0.0.0.0'', null,
		p_object_type, p_column_name, v_min_n_value, 1, null,
		p_datatype, p_pretty_name, p_pretty_name, p_widget_name,
		''f'', ''f'', p_table_name
	);

	update im_dynfield_attributes set also_hard_coded_p = p_also_hard_coded_p
	where attribute_id = v_dynfield_id;

	insert into im_dynfield_layout (
		attribute_id, page_url, pos_y, label_style
	) values (
		v_dynfield_id, ''default'', p_pos_y, ''table''
	);

	-- set all im_dynfield_type_attribute_map to "edit"
	select type_category_type into v_type_category from acs_object_types
	where object_type = p_object_type;
	FOR row IN
		select	category_id
		from	im_categories
		where	category_type = v_type_category
	LOOP
		select	count(*) into v_count from im_dynfield_type_attribute_map
		where	object_type_id = row.category_id and attribute_id = v_dynfield_id;
		IF 0 = v_count THEN
			insert into im_dynfield_type_attribute_map (
				attribute_id, object_type_id, display_mode
			) values (
				v_dynfield_id, row.category_id, ''edit''
			);
		END IF;
	END LOOP;

	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Employees''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Customers''), ''write'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''read'');
	PERFORM acs_permission__grant_permission(v_dynfield_id, (select group_id from groups where group_name=''Freelancers''), ''write'');

	RETURN v_dynfield_id;
END;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1), integer, char(1)
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;
	p_pos_y			alias for $7;
	p_also_hard_coded_p	alias for $8;

	v_table_name		varchar;
BEGIN
	select table_name into v_table_name
	from acs_object_types where object_type = p_object_type;

	RETURN im_dynfield_attribute_new($1,$2,$3,$4,$5,$6,null,''f'',v_table_name);
END;' language 'plpgsql';

-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, varchar, varchar, char(1)
) RETURNS integer as '
BEGIN
	RETURN im_dynfield_attribute_new($1,$2,$3,$4,$5,$6,null,''f'');
END;' language 'plpgsql';




SELECT im_dynfield_attribute_new ('im_ticket', 'project_name', 'Name', 'textbox_medium', 'string', 'f', 00, 't', 'im_projects');

SELECT im_dynfield_attribute_new (
	'im_ticket', 'parent_id', 'Service Level Agreement', 'service_level_agreements', 
	'integer', 'f', 10, 't', 'im_projects'
);

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_status_id', 'Status', 'ticket_status', 'integer', 'f', 20, 't', 'im_tickets');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_type_id', 'Type', 'ticket_type', 'integer', 'f', 30, 't', 'im_tickets');



-----------------------------------------------------------
-- Other fields
--

SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_prio_id', 'Priority', 'ticket_priority', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_assignee_id', 'Assignee', 'ticket_assignees', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_note', 'Note', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_component_id', 'Software Component', 'ticket_po_components', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_conf_item_id', 'Hardware Component', 'conf_items_servers', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_description', 'Description', 'textarea_small', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_deadline', 'Desired Customer End Date', 'date', 'date', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quoted_days', 'Quoted Days', 'numeric', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_quote_comment', 'Quote Comment', 'textarea_small_nospell', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_request_type_id', 'Telephony Request Type', 'telephony_request_type', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_old_number', 'Old Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_telephony_new_number', 'New Number/ Location', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_customer_contact_id', 'Customer Contact', 'customer_contact', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_dept_id', 'Department', 'cost_centers', 'integer', 'f');

-----------------------------------------------------------
-- Unused fields
--

-- ticket_service_id                | integer                  |
-- ticket_hardware_id               | integer                  |
-- ticket_application_id            | integer                  |
-- ticket_queue_id                  | integer                  |
-- ticket_alarm_date                | timestamp with time zone |
-- ticket_alarm_action              | text                     |
-- ticket_creation_date             | timestamp with time zone |
-- ticket_reaction_date             | timestamp with time zone |
-- ticket_confirmation_date         | timestamp with time zone |
-- ticket_done_date                 | timestamp with time zone |
-- ticket_signoff_date              | timestamp with time zone |
-- ocs_software_id                  | integer                  |

