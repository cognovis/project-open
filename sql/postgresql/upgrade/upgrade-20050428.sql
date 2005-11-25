--
-- packages/intranet-dynfield/sql/oracle/upgrade-20050428.sql
--
-- @author Toni Vila toni.vila@quest.ie
-- @creation-date 2005-04-28
--
--

create or replace package body im_dynfield_attribute
is
    function new (
	attribute_id		in integer default null,
	object_type     	in varchar default 'im_dynfield_attribute',
	creation_date   	in date default sysdate,
	creation_user   	in integer default null,
	creation_ip     	in varchar default null,
	context_id		in integer default null,
	attribute_object_type	in varchar,
	attribute_name		in varchar,
        min_n_values		in integer,
        max_n_values		in integer,
        default_value		in varchar,
        datatype		in varchar,
        pretty_name		in varchar,
        pretty_plural		in varchar,
	widget_name		in varchar,
	deprecated_p		in char,
	already_existed_p	in char
    ) return integer
    is
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
    begin
	v_acs_attribute_id := acs_attribute.create_attribute (
		object_type =>		attribute_object_type,
		attribute_name =>	attribute_name,
		min_n_values =>		min_n_values,
		max_n_values =>		max_n_values,
		default_value =>	default_value,
		datatype =>		datatype,
		pretty_name =>		pretty_name,
		pretty_plural =>	pretty_plural
	);

	v_attribute_id := acs_object.new (
		object_id	=>	attribute_id,
		object_type     =>	object_type,
		creation_date   =>	creation_date,
		creation_user   =>	creation_user,
		creation_ip     =>	creation_ip,
		context_id	=>	context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, new.widget_name,
		new.deprecated_p, new.already_existed_p
	);
	return v_attribute_id;
    end new;


    -- Delete a single attribute (if we know its ID...)
    procedure del (attribute_id in integer)
    is
	v_attribute_id	 	integer;
	v_acs_attribute_id	integer;
	v_acs_attribute_name	acs_attributes.attribute_name%TYPE;
	v_object_type		acs_attributes.object_type%TYPE;
    begin
	-- get the acs_attribute_id and object_type
	select
		fa.acs_attribute_id, 
		aa.object_type,
		aa.attribute_name
	into 
		v_acs_attribute_id, 
		v_object_type,
		v_acs_attribute_name
	from
		im_dynfield_attributes fa,
		acs_attributes aa
	where
		aa.attribute_id = fa.acs_attribute_id
		and fa.attribute_id = del.attribute_id;

	-- Erase the im_dynfield_attributes item associated with the id

	delete from im_dynfield_layout
    	where attribute_id = del.attribute_id;

	-- Erase values for the im_dynfield_attribute item associated with the id

	delete from im_dynfield_attr_multi_value
	where attribute_id = del.attribute_id;

	delete from im_dynfield_attributes
	where attribute_id = del.attribute_id;

	acs_attribute.drop_attribute(v_object_type, v_acs_attribute_name);
    end del;

    -- return the name from acs_attributes
    function name (attribute_id in integer) return varchar
    is
	v_attribute_id		integer;
	v_acs_attribute_id	integer;
	v_name			acs_attributes.attribute_name%TYPE;
    begin
	-- get the acs_attribute_id
	select acs_attribute_id
	into v_acs_attribute_id
	from im_dynfield_attributes
	where attribute_id = name.attribute_id;

	select  attribute_name
	into    v_name
	from    acs_attributes
	where   attribute_id = v_acs_attribute_id;

	return v_name;
    end name;

end im_dynfield_attribute;
/
show errors;
