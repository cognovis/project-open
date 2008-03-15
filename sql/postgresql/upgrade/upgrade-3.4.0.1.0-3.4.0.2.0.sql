-- upgrade-3.4.0.1.0-3.4.0.2.0.sql



-- Shortcut function
CREATE OR REPLACE FUNCTION im_dynfield_attribute_new (
	varchar, varchar, varchar, char(1), varchar, varchar
) RETURNS integer as '
DECLARE
	p_object_type		alias for $1;
	p_column_name		alias for $2;
	p_pretty_name		alias for $3;
	p_widget_name		alias for $4;
	p_datatype		alias for $5;
	p_required_p		alias for $6;

	v_dynfield_id		integer;
	v_widget_id		integer;
BEGIN
	select	widget_id into v_widget_id from im_dynfield_widgets
	where	widget_name = p_widget_name;
	IF v_widget_id is null THEN 
		RAISE NOTICE ''im_dynfield_attribute_new: Did not find widget %s.'',p_widget_name;
		return 1; 
	END IF;

-- fraber 080315: Disabled. The acs_attribute is generated later
--	select	attribute_id into v_dynfield_id from acs_attributes
--	where	attribute_name = p_column_name;
--	IF v_dynfield_id is not null THEN return 1; END IF;

	v_dynfield_id := im_dynfield_attribute__new (
		null, ''im_dynfield_attribute'', now(), 0, ''0.0.0.0'', null,
		p_object_type, p_column_name, 0, 1, null,
		p_datatype, p_pretty_name, p_pretty_name, p_widget_name,
		''f'', ''f''
	);

	RETURN v_dynfield_id;
END;' language 'plpgsql';

