--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--


-- This should eventually be added to the acs-service-contract installation files

declare
    v_id	integer;
begin
    v_id :=  acs_sc_contract.new(
	    contract_name => 'AcsObject',
	    contract_desc => 'Acs Object Id Handler'
    );
    v_id := acs_sc_msg_type.new(
	    msg_type_name => 'AcsObject.PageUrl.InputType',
	    msg_type_spec => 'object_id:integer'
    );
    v_id := acs_sc_msg_type.new(
	    msg_type_name => 'AcsObject.PageUrl.OutputType',
	    msg_type_spec => 'page_url:string'
    );
    v_id := acs_sc_operation.new(
	    contract_name => 'AcsObject',
	    operation_name => 'PageUrl',
	    operation_desc => 'Returns the package specific url to a page that displays an object',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'AcsObject.PageUrl.InputType',
	    operation_outputtype => 'AcsObject.PageUrl.OutputType'
    );
end;
/
show errors

-- there should be an implementation of this contract
-- for apm_package, user, group and other object types


-- this should eventually be added to acs-kernel

create table acs_named_objects (
	object_id	integer not null
			constraint acs_named_objs_object_id_fk
			references acs_objects(object_id) on delete cascade,
	locale		varchar2(5)
			constraint acs_named_objs_locale_fk
			references ad_locales,
	object_name	varchar2(200),
	creation_date	date default sysdate not null,
	package_id	integer
			constraint acs_named_objs_package_id_fk
			references apm_packages(package_id) on delete cascade,
	constraint acs_named_objs_pk
	primary key (object_id, locale)
);

create index acs_named_objs_name_ix on acs_named_objects (substr(upper(object_name),1,1));
create index acs_named_objs_package_ix on acs_named_objects(package_id);

begin
        acs_object_type.create_type (
                supertype       =>      'acs_object',
                object_type     =>      'acs_named_object',
                pretty_name     =>      'Named Object',
                pretty_plural   =>      'Named Objects',
                table_name      =>      'acs_named_objects',
                id_column       =>      'object_id'
        );
end;
/
show errors
