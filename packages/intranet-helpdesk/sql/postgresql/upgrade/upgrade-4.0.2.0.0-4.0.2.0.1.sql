-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');


-- New action
SELECT im_category_new(30532, 'Re-Open &amp; notify', 'Intranet Ticket Action');



create or replace function im_ticket__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer 
) returns integer as '
DECLARE
	p_ticket_id		alias for $1;		-- ticket_id default null
	p_object_type		alias for $2;		-- object_type default im_ticket
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_ticket_name		alias for $7;		-- ticket_name
	p_ticket_nr		alias for $8;		-- ticket_name
	p_ticket_customer_id	alias for $9;
	p_ticket_type_id	alias for $10;		
	p_ticket_status_id	alias for $11;
	v_ticket_id		integer;
BEGIN
	v_ticket_id := im_project__new (
		p_ticket_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		p_ticket_name,
		p_ticket_nr::varchar,
		p_ticket_nr::varchar,
		null,			-- parent_id
		p_ticket_customer_id,
		101,			-- p_ticket_type_id
		76			-- p_ticket_status_id	
	);

	update im_projects set
		start_date = now()
	where project_id = v_ticket_id;

	insert into im_tickets (
		ticket_id, ticket_status_id, ticket_type_id, ticket_creation_date
	) values (
		v_ticket_id, p_ticket_status_id, p_ticket_type_id, now()
	);

	return v_ticket_id;
END;' language 'plpgsql';



create or replace function im_ticket__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, integer, integer, integer 
) returns integer as '
DECLARE
	p_ticket_id		alias for $1;		-- ticket_id default null
	p_object_type		alias for $2;		-- object_type default im_ticket
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_ticket_name		alias for $7;		-- ticket_name
	p_ticket_customer_id	alias for $8;
	p_ticket_type_id	alias for $9;		
	p_ticket_status_id	alias for $10;
	v_ticket_nr		integer;
BEGIN
	select nextval(''im_ticket_seq'') into v_ticket_nr;

	return im_ticket__new (
		p_ticket_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id,
		p_ticket_name,
		v_ticket_nr,
		p_ticket_customer_id,
		p_ticket_type_id,
		p_ticket_status_id	
	);

END;' language 'plpgsql';

