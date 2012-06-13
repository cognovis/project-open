-- creates the calendar object
--
-- @author Gary Jin (gjin@arsdigita.com)
-- @creation-date Nov 17, 2000
-- @cvs-id $Id$
--
-- ported by Charles Mok (mok_cl@eelab.usyd.edu.au)

------------------------------------------------------------------
-- calendar system permissions 
------------------------------------------------------------------
 
  -- creating the basic set of permissions for cal_item
  --
  -- 1  create: create an new item 
  -- 2. read: can view the cal_item
  -- 3. write: edit an existing cal_item
  -- 4. delete: can delete the cal_item
  -- 5. invite: can allow other parties to view or edit the cal_item



  select acs_privilege__create_privilege('cal_item_create', 'Add an new item', null); 
  select acs_privilege__create_privilege('cal_item_read',   'view an cal_item', null);
  select acs_privilege__create_privilege('cal_item_write',  'Edit an exsiting cal_item', null);
  select acs_privilege__create_privilege('cal_item_delete', 'Delete cal_item', null );
  select acs_privilege__create_privilege('cal_item_invite', 'Allow others to view cal_item', null); 

  select acs_privilege__add_child('create', 'cal_item_create'); 
  select acs_privilege__add_child('read', 'cal_item_read'); 
  select acs_privilege__add_child('write', 'cal_item_write'); 

  select acs_privilege__add_child('delete', 'cal_item_delete'); 
        
  select acs_privilege__create_privilege('calendar_on', 'Implies that a calendar is selected', null); 
  select acs_privilege__create_privilege('calendar_show', 'Show a calendar', null);

  select acs_privilege__add_child('read', 'calendar_on'); 
  select acs_privilege__add_child('read', 'calendar_show');         
	
  select acs_privilege__create_privilege('calendar_create', 'Create a new calendar', null);
  select acs_privilege__create_privilege('calendar_read', 'View items on an exsiting calendar', null);	
  select acs_privilege__create_privilege('calendar_write', 'Edit items of an exsiting calendar', null);
  select acs_privilege__create_privilege('calendar_delete','Delete an calendar', null);

  select acs_privilege__add_child('create', 'calendar_create');
  select acs_privilege__add_child('read', 'calendar_read');
  select acs_privilege__add_child('write', 'calendar_write');
  select acs_privilege__add_child('delete', 'calendar_delete');

  select acs_privilege__add_child('calendar_create', 'cal_item_create');
  select acs_privilege__add_child('calendar_read', 'cal_item_read');
  select acs_privilege__add_child('calendar_write', 'cal_item_write');
  select acs_privilege__add_child('calendar_delete', 'cal_item_delete');
       
  select acs_privilege__create_privilege('calendar_admin', 'calendar adminstrator', null);
  select acs_privilege__add_child('admin', 'calendar_admin');
  select acs_privilege__add_child('calendar_admin', 'calendar_read');
  select acs_privilege__add_child('calendar_admin', 'calendar_write');
  select acs_privilege__add_child('calendar_admin', 'calendar_delete');
  select acs_privilege__add_child('calendar_admin', 'calendar_create');
  select acs_privilege__add_child('calendar_admin', 'cal_item_invite');

---------------------------------------------------------- 
--  calendar_ojbect 
----------------------------------------------------------- 

CREATE FUNCTION inline_0()
RETURNS integer
AS 'declare
	attr_id acs_attributes.attribute_id%TYPE;
    begin
	PERFORM 
	    acs_object_type__create_type(
		''calendar'',	-- object_type
		''Calendar'',	-- pretty_name
		''Calendar'',	-- pretty_plural
		''acs_object'',	-- supertype
		''calendars'',	-- table_name
		''calendar_id'',-- id_column
		null,		-- package_name
		''f'',		-- abstract_p
		null,		-- type_extension_table
		null		-- name_method
	    );
		
	    attr_id := acs_attribute__create_attribute (
		''calendar'',       -- object_type
	        ''owner_id'',     -- attribute_name
        	''integer'',         -- datatype
	        ''Owner'',        -- pretty_name
        	''Owners'',       -- pretty_plural
	        null,                -- table_name (default)
	        null,                -- column_name (default)
        	null,                -- default_value (default)
	        1,                   -- min_n_values (default)
        	1,                   -- max_n_values (default)
	        null,                -- sort_order (default)
        	''type_specific'',   -- storage (default)
	        ''f''                -- static_p (default)
	    );

	    attr_id := acs_attribute__create_attribute (
		''calendar'',       -- object_type
	        ''private_p'',     -- attribute_name
        	''string'',         -- datatype
	        ''Private Calendar'',        -- pretty_name
        	''Private Calendars'',       -- pretty_plural
	        null,                -- table_name (default)
	        null,                -- column_name (default)
        	null,                -- default_value (default)
	        1,                   -- min_n_values (default)
        	1,                   -- max_n_values (default)
	        null,                -- sort_order (default)
        	''type_specific'',   -- storage (default)
	        ''f''                -- static_p (default)
	    );

	    attr_id := acs_attribute__create_attribute (
		''calendar'',       -- object_type
	        ''calendar_name'',     -- attribute_name
        	''string'',         -- datatype
	        ''Calendar Name'',        -- pretty_name
        	''Calendar Names'',       -- pretty_plural
	        null,                -- table_name (default)
	        null,                -- column_name (default)
        	null,                -- default_value (default)
	        1,                   -- min_n_values (default)
        	1,                   -- max_n_values (default)
	        null,                -- sort_order (default)
        	''type_specific'',   -- storage (default)
	        ''f''                -- static_p (default)
	    );
	    return 0;

    end;' 
LANGUAGE 'plpgsql';

SELECT inline_0();

DROP function inline_0();

-- Calendar is a collection of events. Each calendar must
-- belong to somebody (a party).
create table calendars (
          -- primary key
        calendar_id             integer         
                                constraint calendars_calendar_id_fk 
                                references acs_objects
                                constraint calendars_calendar_id_pk 
                                primary key,
          -- the name of the calendar
        calendar_name           varchar(200),
          -- the individual or party that owns the calendar        
        owner_id                integer
                                constraint calendars_calendar_owner_id_fk 
                                references parties
                                on delete cascade,
          -- keep track of package instances
        package_id              integer
                                constraint calendars_package_id_fk
                                references apm_packages(package_id)
                                on delete cascade,
          -- whether or not the calendar is a private personal calendar or a 
          -- public calendar. 
        private_p               boolean
                                default 'f'
                                constraint calendars_private_p_ck 
                                check (private_p in ( 
                                        't',
                                        'f'
                                        )
                                )       
);

comment on table calendars is '
        Table calendars maps the many to many relationship betweens
        calendar and its owners. 
';

comment on column calendars.calendar_id is '
        Primary Key
';

comment on column calendars.calendar_name is '
        the name of the calendar. This would be unique to avoid confusion
';

comment on column calendars.owner_id is '
        the individual or party that owns the calendar
';

comment on column calendars.package_id is '
        keep track of package instances
';


-- Calendar Item Types

create sequence cal_item_type_seq;

create table cal_item_types (
       item_type_id              integer not null
                                 constraint cal_item_type_id_pk
                                 primary key,
       calendar_id               integer not null
                                 constraint cal_item_type_cal_id_fk     
                                 references calendars(calendar_id),
       type                      varchar(100) not null,
       -- this constraint is obvious given that item_type_id
       -- is unique, but it's necessary to allow strong
       -- references to the pair calendar_id, item_type_id (ben)
       constraint cal_item_types_un
       unique (calendar_id, item_type_id)
);

-------------------------------------------------------------
-- Load cal_item_object
-------------------------------------------------------------
\i cal-item-create.sql
-------------------------------------------------------------
-- create package calendar
-------------------------------------------------------------

select define_function_args ('calendar__new', 'calendar_id,calendar_name,object_type;calendar,owner_id,private_p,package_id,context_id,creation_date,creation_user,creation_ip');

CREATE FUNCTION calendar__new (
       integer,            -- calendar.calendar_id%TYPE
       varchar(200),            -- calendar.calendar_name%TYPE
       varchar,            -- acs_objects.object_type%TYPE
       integer,            -- calendar.owner_id%TYPE
       boolean,            -- calendar.private_p
       integer,            -- calendar.package_id
       integer,            -- acs_objects.context_id%TYPE
       timestamptz,        -- acs_objects.creation_date%TYPE
       integer,            -- acs_objects.creation_user%TYPE
       varchar             -- acs_objects.creation_ip%TYPE
)
RETURNS integer 
AS 'declare
	v_calendar_id           calendars.calendar_id%TYPE;
	new__calendar_id	alias for $1;
	new__calendar_name	alias for $2;
	new__object_type	alias for $3;
	new__owner_id		alias for $4;
	new__private_p		alias for $5;
	new__package_id		alias for $6;
	new__context_id		alias for $7;
	new__creation_date	alias for $8;
	new__creation_user	alias for $9;
	new__creation_ip	alias for $10;

    begin
        v_calendar_id := acs_object__new(
		new__calendar_id,
		new__object_type,
		new__creation_date,
		new__creation_user,
		new__creation_ip,
		new__context_id
	);
	
	insert into     calendars
                        (calendar_id, calendar_name, owner_id, package_id, private_p)
	values          (v_calendar_id, new__calendar_name, new__owner_id, new__package_id, new__private_p);
      
	PERFORM acs_permission__grant_permission (
              v_calendar_id,
              new__owner_id,
              ''calendar_admin''
        );


	return v_calendar_id;
    end;'
LANGUAGE 'plpgsql';   

select define_function_args('calendar__delete','calendar_id');

CREATE FUNCTION calendar__delete(
       integer            -- calendar.calendar_id%TYPE
)
RETURNS integer
AS 'declare
	delete__calendar_id		alias for $1;
    begin
	delete from calendars
	where calendar_id = delete__calendar_id;

	-- Delete all privileges associate with this calendar
	
	delete from     acs_permissions 
        where           object_id = delete__calendar_id;

       delete from     acs_permissions
        where           object_id in (
				select  cal_item_id
                                from    cal_items
                                where   on_which_calendar = delete__calendar_id
			);
                         
	PERFORM acs_object__delete(delete__calendar_id);

    return 0;
    end;'
LANGUAGE 'plpgsql';
	


-----------------------------------------------------------------
-- load related sql files
-----------------------------------------------------------------
--\i cal-item-create.sql
-- 
\i cal-table-create.sql

\i calendar-notifications-init.sql
