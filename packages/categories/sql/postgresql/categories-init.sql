--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--


-- This should eventually be added to the acs-service-contract installation files
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from acs_sc_contracts
	where  contract_name = 'AcsObject';
	IF v_count > 0 THEN return 1; END IF;

	select acs_sc_contract__new(
	    'AcsObject',                -- contract_name
	    'Acs Object Id Handler'     -- contract_desc
	);
	select acs_sc_msg_type__new(
	    'AcsObject.PageUrl.InputType',      -- msg_type_name
	    'object_id:integer'                 -- msg_type_spec
	);
	select acs_sc_msg_type__new(
	    'AcsObject.PageUrl.OutputType',     -- msg_type_name
	    'page_url:string'                   -- msg_type_spec
	);
	select acs_sc_operation__new(
	    'AcsObject',                        -- contract_name
	    'PageUrl',                          -- operation_name
	    'Returns the package specific url to a page that displays an object', -- operation_desc
	    'f',                                -- operation_iscachable_p
	    1,                                  -- operation_nargs
	    'AcsObject.PageUrl.InputType',      -- operation_inputtype
	    'AcsObject.PageUrl.OutputType'      -- operation_outputtype
	);

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();



-- there should be an implementation of this contract
-- for apm_package, user, group and other object types


-- this should eventually be added to acs-kernel
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  table_name = 'ACS_NAMED_OBJECTS';
	IF v_count > 0 THEN return 1; END IF;

	create table acs_named_objects (
		object_id	integer not null
				constraint acs_named_objs_pk primary key
				constraint acs_named_objs_object_id_fk
				references acs_objects(object_id) on delete cascade,
		object_name	varchar(200),
		package_id	integer
				constraint acs_named_objs_package_id_fk
				references apm_packages(package_id) on delete cascade
	);
	
	create index acs_named_objs_name_ix on acs_named_objects(object_name);
	create index acs_named_objs_package_ix on acs_named_objects(package_id);

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();



create function inline_0 ()
returns integer as '
begin
	    PERFORM acs_object_type__create_type (
	            ''acs_named_object'',     -- object_type
	            ''Named Object'',         -- pretty_name
	            ''Named Objects'',        -- pretty_plural
	            ''acs_object'',           -- supertype
	            ''acs_named_objects'',    -- table_name
	            ''object_id'',            -- id_column
	            null,                     -- name_method
	            ''f'',
	            null,
	            null
	    );
	   return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
