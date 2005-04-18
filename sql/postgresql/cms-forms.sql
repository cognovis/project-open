
-- Metadata for generating data entry forms

create table cm_form_widgets (
  widget           varchar(100)
                   constraint cm_form_widgets_pk
		   primary key
);

comment on table cm_form_widgets is '
  Canonical list of all widgets defined in the system
';

create sequence t_cm_form_widget_param_seq;
create view cm_form_widget_param_seq as
select nextval('t_cm_form_widget_param_seq') as nextval;

create table cm_form_widget_params (
  param_id         integer
                   constraint cm_form_widget_params_pk
		   primary key,
  widget           varchar(100)
                   constraint cm_widget_params_fk
                   references cm_form_widgets,
  param            varchar(100)
                   constraint cm_widget_param_nil
                   not null,
  is_required      boolean,
  is_html          boolean,
  default_value    varchar(1000)
);

comment on table cm_form_widget_params is '
  Parameters that are specific to a particular type of form widget.
';


create table cm_attribute_widgets (
  attribute_id     integer
                   constraint cm_attribute_widgets_pk
                   primary key
                   constraint cm_attr_widget_fk
                   references acs_attributes,
  widget	   varchar(100)
                   constraint cm_attr_widget_widget_fk
                   references cm_form_widgets
                   constraint cm_attr_widget_nil
                   not null,
  is_required      boolean
);

create table cm_attribute_widget_params (
  attribute_id     integer
                   constraint cm_attr_widg_param_attr_fk
                   references acs_attributes,
  param_id         integer
                   constraint cm_attr_widget_param_fk
                   references cm_form_widget_params,
  param_type       varchar(100) default 'onevalue'
                   constraint cm_attr_widget_param_type_nil
                   not null
                   constraint cm_attr_widget_param_type_ck
                   check (param_type in ('onevalue', 'onelist', 'multilist')),
  param_source     varchar(100) default 'literal'
                   constraint cm_attr_widget_param_src_nil
                   not null,
                   constraint cm_attr_widget_param_src_ck 
                   check (param_source in ('literal', 'query', 'eval')),
  value		   text,
  constraint cm_attr_widget_param_pk
  primary key(attribute_id, param_id)
);

comment on table cm_attribute_widget_params is '
  Parameter values for specific attribute widgets.
';

-- Get all the parameters for a attribute form widget

create view cm_attribute_widget_param_ext as
  select
    widget_params.*, at.attribute_name, at.object_type, at.pretty_name,
    at.datatype, at.sort_order
  from
    acs_attributes at,
    (select
      widgets.attribute_id, widgets.is_required as widget_is_required, 
      widgets.widget, params.param_id, params.param_type, params.param_source,
      coalesce(params.value,params.default_value) as value, 
      params.param, params.param_is_required,
      params.is_html, params.default_value
    from 
      cm_attribute_widgets widgets LEFT OUTER JOIN
      (select
	awp.attribute_id, awp.param_id, awp.param_type, 
	awp.param_source, awp.value, 
	fwp.param, fwp.is_required as param_is_required,
	fwp.is_html, fwp.default_value
      from
	cm_form_widget_params fwp, cm_attribute_widget_params awp
      where
	fwp.param_id = awp.param_id
      UNION
      select
        aw.attribute_id, fwp.param_id, 
	'onevalue' as param_type, 'literal' as param_source,
	default_value as value, fwp.param, fwp.is_required as param_is_required,
	fwp.is_html, fwp.default_value
      from
        cm_form_widget_params fwp, cm_attribute_widgets aw
      where
        aw.widget = fwp.widget
      and
        not exists (select 1 from cm_attribute_widget_params
                    where param_id = fwp.param_id 
		    and attribute_id = aw.attribute_id)
        ) params using (attribute_id)) widget_params
  where
    widget_params.attribute_id = at.attribute_id
  order by
    object_type, sort_order;


create or replace function cm_form_widget__register_attribute_widget (varchar,varchar,varchar,boolean)
returns integer as '
declare
  p_content_type        alias for $1;  
  p_attribute_name      alias for $2;  
  p_widget              alias for $3;  
  p_is_required         alias for $4;  -- default ''f''
  v_attr_id             acs_attributes.attribute_id%TYPE;
  v_prev_widget         integer;       
begin
  
    -- Look for the attribute
    
    select attribute_id into v_attr_id 
      from acs_attributes
     where attribute_name = p_attribute_name
       and object_type = p_content_type;

    if NOT FOUND then

        raise EXCEPTION ''-20000: Attribute %: % does not exist in cm_form_widget.register_attribute_widget'', p_content_type, p_attribute_name;
    end if;

    -- Determine if a previous value exists
    select count(1) into v_prev_widget 
      from dual 
     where exists (select 1 
                     from cm_attribute_widgets
                    where attribute_id = v_attr_id);

    if v_prev_widget > 0 then 
      -- Old widget exists: erase parameters, update widget
      delete 
        from cm_attribute_widget_params 
      where
        attribute_id = v_attr_id 
      and 
        param_id in (select param_id 
                       from cm_form_widgets
                      where widget = p_widget);

      update cm_attribute_widgets set
        widget = p_widget,
        is_required = p_is_required
      where attribute_id = v_attr_id;

    else
      -- No previous widget registered
      -- Insert a new row 
      insert into cm_attribute_widgets
	(attribute_id, widget, is_required)
      values
	(v_attr_id, p_widget, p_is_required);
    end if;

    return 0; 
end;' language 'plpgsql';


-- procedure set_attribute_order
create or replace function cm_form_widget__set_attribute_order (varchar,varchar,integer)
returns integer as '
declare
  p_content_type        alias for $1;  
  p_attribute_name      alias for $2;  
  p_sort_order          alias for $3;  
                                        
begin

    update 
      acs_attributes    
    set
      sort_order = p_sort_order
    where
      object_type = p_content_type
    and
      attribute_name = p_attribute_name;
        
    return 0; 
end;' language 'plpgsql';


-- procedure unregister_attribute_widget
create or replace function cm_form_widget__unregister_attribute_widget (varchar,varchar)
returns integer as '
declare
  p_content_type        alias for $1;  
  p_attribute_name      alias for $2;  
  v_attr_id             acs_attributes.attribute_id%TYPE;
  v_widget              cm_form_widgets.widget%TYPE;
begin
  
    -- Look for the attribute
    
    select attribute_id into v_attr_id from acs_attributes
     where attribute_name = p_attribute_name
       and object_type = p_content_type;

    if NOT FOUND then
        raise EXCEPTION ''-20000: Attribute %: % does not exist in cm_form_widget.unregister_attribute_widget'', p_content_type, p_attribute_name;
    end if;   

    -- Look for the widget; if no widget is registered, just return
    
    select widget into v_widget from cm_attribute_widgets
     where attribute_id = v_attr_id;

    if NOT FOUND then
       return null;
    end if;
  
    -- Delete the param values and the widget assignment
    delete from cm_attribute_widget_params 
      where attribute_id = v_attr_id 
      and param_id in (select param_id from cm_form_widgets
                         where widget = v_widget);

    delete from cm_attribute_widgets 
      where attribute_id = v_attr_id;

    return 0; 
end;' language 'plpgsql';


-- procedure set_attribute_param_value
create or replace function cm_form_widget__set_attribute_param_value (varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  p_content_type        alias for $1;  
  p_attribute_name      alias for $2;  
  p_param               alias for $3;  
  p_value               alias for $4;  
  p_param_type          alias for $5;  -- default ''one_value''
  p_param_source        alias for $6;  -- default ''literal''
  v_attr_id             acs_attributes.attribute_id%TYPE;
  v_widget              cm_form_widgets.widget%TYPE;
  v_param_id            cm_form_widget_params.param_id%TYPE;
  v_prev_value          integer;       
begin

    -- Get the attribute id and the widget 
    select 
	a.attribute_id, aw.widget into v_attr_id, v_widget 
    from 
        acs_attributes a, cm_attribute_widgets aw
    where 
	a.attribute_name = p_attribute_name
    and 
	a.object_type = p_content_type
    and
	aw.attribute_id = a.attribute_id;

    if NOT FOUND then
      raise EXCEPTION ''-20000: No widget is registered for attribute %.% in cm_form_widget.set_attribute_param_value'', p_content_type, p_attribute_name;
    end if;

    -- Get the param id
    select param_id into v_param_id from cm_form_widget_params
     where widget = v_widget 
       and param = p_param;

    if NOT FOUND then
      raise EXCEPTION ''-20000: No parameter named % exists for the widget % in cm_form_widget.set_attribute_param_value'', p_param, v_widget;
    end if;  

    -- Check if an old value exists
    -- Determine if a previous value exists
    select count(1) into v_prev_value from dual 
      where exists (select 1 from cm_attribute_widget_params
                    where attribute_id = v_attr_id
                    and param_id = v_param_id);
    
    if v_prev_value > 0 then
      -- Update the value
      update cm_attribute_widget_params set
        param_type = p_param_type,
        param_source = p_param_source,
        value = p_value
      where
        attribute_id = v_attr_id
      and
        param_id = v_param_id;
    else
      -- Insert a new value
      insert into cm_attribute_widget_params
        (attribute_id, param_id, param_type, param_source, value)
      values
        (v_attr_id, v_param_id, p_param_type, p_param_source, p_value);
    end if;

    return 0; 
end;' language 'plpgsql';


create or replace function cm_form_widget__set_attribute_param_value (varchar,varchar,varchar,integer,varchar,varchar)
returns integer as '
begin
    return cm_form_widget__set_attribute_param_value($1, $2, $3, cast ($4 as varchar), $5, $6); 
end;' language 'plpgsql';


\i cms-widgets.sql
