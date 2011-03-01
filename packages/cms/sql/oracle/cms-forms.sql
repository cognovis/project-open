-- Metadata for generating data entry forms

create table cm_form_widgets (
  widget           varchar2(100)
                   constraint cm_form_widgets_pk
		   primary key
);

comment on table cm_form_widgets is '
  Canonical list of all widgets defined in the system
';

create sequence cm_form_widget_param_seq start with 500;

create table cm_form_widget_params (
  param_id         integer
                   constraint cm_form_widget_params_pk
		   primary key,
  widget           varchar2(100)
                   constraint cm_widget_params_fk
                   references cm_form_widgets,
  param            varchar2(100)
                   constraint cm_widget_param_nil
                   not null,
  is_required      char(1)
                   constraint cm_widget_param_req_chk
                   check (is_required in ('t', 'f')),
  is_html          char(1)
                   constraint cm_widget_param_html_chk
                   check (is_html in ('t', 'f')),
  default_value    varchar2(1000)
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
  widget	   varchar2(100)
                   constraint cm_attr_widget_widget_fk
                   references cm_form_widgets
                   constraint cm_attr_widget_nil
                   not null,
  is_required      char(1) 
                   constraint cm_attribute_widgets_opt_ck
                   check(is_required in ('t', 'f'))
);

create table cm_attribute_widget_params (
  attribute_id     integer
                   constraint cm_attr_widg_param_attr_fk
                   references acs_attributes,
  param_id         integer
                   constraint cm_attr_widget_param_fk
                   references cm_form_widget_params,
  param_type       varchar2(100) default 'onevalue'
                   constraint cm_attr_widget_param_type_nil
                   not null
                   constraint cm_attr_widget_param_type_ck
                   check (param_type in ('onevalue', 'onelist', 'multilist')),
  param_source     varchar2(100) default 'literal'
                   constraint cm_attr_widget_param_src_nil
                   not null,
                   constraint cm_attr_widget_param_src_ck 
                   check (param_source in ('literal', 'query', 'eval')),
  value		   varchar2(4000),
  constraint cm_attr_widget_param_pk
  primary key(attribute_id, param_id)
);

comment on table cm_attribute_widget_params is '
  Parameter values for specific attribute widgets.
';

-- Get all the parameters for a attribute form widget

create or replace view cm_attribute_widget_param_ext as
  select
    widget_params.*, at.attribute_name, at.object_type, at.pretty_name,
    at.datatype, at.sort_order
  from
    acs_attributes at,
    (select
      widgets.attribute_id, widgets.is_required widget_is_required, 
      widgets.widget, params.param_id, params.param_type, params.param_source,
      nvl(params.value,params.default_value) value, 
      params.param, params.param_is_required,
      params.is_html, params.default_value
    from 
      cm_attribute_widgets widgets, 
      (select
	awp.attribute_id, awp.param_id, awp.param_type, 
	awp.param_source, awp.value, 
	fwp.param, fwp.is_required param_is_required,
	fwp.is_html, fwp.default_value
      from
	cm_form_widget_params fwp, cm_attribute_widget_params awp
      where
	fwp.param_id = awp.param_id
      UNION
      select
        aw.attribute_id, fwp.param_id, 
	'onevalue' as param_type, 'literal' as param_source,
	default_value as value, fwp.param, fwp.is_required param_is_required,
	fwp.is_html, fwp.default_value
      from
        cm_form_widget_params fwp, cm_attribute_widgets aw
      where
        aw.widget = fwp.widget
      and
        not exists (select 1 from cm_attribute_widget_params
                    where param_id = fwp.param_id 
		    and attribute_id = aw.attribute_id)
        ) params
    where
      widgets.attribute_id = params.attribute_id (+)) widget_params
  where
    widget_params.attribute_id = at.attribute_id
  order by
    object_type, sort_order;

create or replace package cm_form_widget 
is

procedure set_attribute_order (
  --/** Update the sort_order column of acs_attributes.
  --    @author Karl Goldstein
  --    @param content_type   The name of the content type
  --    @param attribute_name The name of the attribute
  --    @param sort_order     The sort order.
  --*/
  content_type   in acs_attributes.object_type%TYPE,
  attribute_name in acs_attributes.attribute_name%TYPE,
  sort_order     in acs_attributes.sort_order%TYPE
);

procedure register_attribute_widget (
  --/** Register a form widget to a content type attribute.  The form widget
  --    uses the default values if none are set. If there is already a widget
  --    registered to the attribute, the new widget replaces the old widget,
  --    and all parameters are set to their default values.
  --    @author Karl Goldstein, Stanislav Freidin
  --    @param content_type   The name of the content type
  --    @param attribute_name The name of the attribute
  --	@param widget	      The name of the form widget to use in metadata
  --			      forms
  --	@param is_required    Whether this form widget requires a value, 
  --			      defaults to 'f'
  --    @see <a href="">/ats/form-procs.tcl/element_create</a>,
  --         {cm_form_widget.set_attribute_param_value},
  --         {cm_form_widget.unregister_attribute_widget}
  --*/
  content_type   in acs_attributes.object_type%TYPE,
  attribute_name in acs_attributes.attribute_name%TYPE,
  widget         in cm_form_widgets.widget%TYPE,
  is_required    in cm_attribute_widgets.is_required%TYPE default 'f'
);

procedure unregister_attribute_widget (
  --/** Unregister a form widget from a content type attribute. 
  --    The attribute will no longer show up on the dynamic revision
  --    upload form.<p>If no widget is registered to the attribute,
  --    the procedure does nothing.
  --    @author Karl Goldstein, Stanislav Freidin 
  --    @param content_type   The name of the content type
  --    @param attribute_name The name of the attribute for which to
  --                          unregister the widget
  --    @see {cm_form_widget.register_attribute_widget}
  --*/
  content_type   in acs_attributes.object_type%TYPE,
  attribute_name in acs_attributes.attribute_name%TYPE
);

procedure set_attribute_param_value (
  --/** Sets custom values for the param tag of a form widget that is 
  --    registered to a content type attribute. Unless this procedure is
  --    called, the default form widget param values are used.<p>
  --    If the parameter already has a value associated with it, the old
  --    value is overwritten.
  --    @author Karl Goldstein, Stanislav Freidin
  --    @param content_type   The name of the content type
  --    @param attribute_name The name of the attribute
  --    @param param	      The name of the form widget parameter.
  --			      Can be an ATS 'element create' flag or an
  --			      HTML form widget tag
  --    @param param_type     The type of value the param tag expects.
  --			      Can be 'onevalue','onelist', or 'multilist',
  --			      defaults to 'onevalue'
  --    @param param_source   How the param value is to be acquired, either
  --			      'literal', 'eval', or 'query', defaults to
  --			      'literal'
  --    @param value	      The value(s) or means or obtaining the value(s)
  --			      for the param tag
  --    @see <a href="">/ats/form-procs.tcl/element_create</a>,
  --         {cm_form_widget.register_attribute_widget}
  --*/
  content_type   in acs_attributes.object_type%TYPE,
  attribute_name in acs_attributes.attribute_name%TYPE,
  param          in cm_form_widget_params.param%TYPE,
  value          in cm_attribute_widget_params.value%TYPE,
  param_type     in cm_attribute_widget_params.param_type%TYPE 
                    default 'onevalue',
  param_source   in cm_attribute_widget_params.param_source%TYPE
                    default 'literal'
);

end cm_form_widget;
/
show errors


create or replace package body cm_form_widget 
is

  procedure register_attribute_widget (
    content_type   in acs_attributes.object_type%TYPE,
    attribute_name in acs_attributes.attribute_name%TYPE,
    widget         in cm_form_widgets.widget%TYPE,
    is_required    in cm_attribute_widgets.is_required%TYPE default 'f'
  )
  is
    v_attr_id          acs_attributes.attribute_id%TYPE;
    v_prev_widget integer;
  begin
  
    -- Look for the attribute
    begin
      select attribute_id into v_attr_id from acs_attributes
        where attribute_name=register_attribute_widget.attribute_name
        and object_type=register_attribute_widget.content_type;

      exception when no_data_found then
        raise_application_error(-20000, 'Attribute ' || content_type ||
          ':' || attribute_name || 
          ' does not exist in cm_form_widget.register_attribute_widget'
        );
    end;

    -- Determine if a previous value exists
    select count(1) into v_prev_widget from dual 
      where exists (select 1 from cm_attribute_widgets
                    where attribute_id = v_attr_id);

    if v_prev_widget > 0 then 
      -- Old widget exists: erase parameters, update widget
      delete 
        from cm_attribute_widget_params 
      where
        attribute_id = v_attr_id 
      and 
        param_id in (select param_id from cm_form_widgets
                     where widget = register_attribute_widget.widget);

      update cm_attribute_widgets set
        widget = register_attribute_widget.widget,
        is_required = register_attribute_widget.is_required
      where attribute_id = v_attr_id;

    else
      -- No previous widget registered
      -- Insert a new row 
      insert into cm_attribute_widgets
	(attribute_id, widget, is_required)
      values
	(v_attr_id, widget, is_required);
    end if;

  end register_attribute_widget;

  procedure set_attribute_order (
    content_type   in acs_attributes.object_type%TYPE,
    attribute_name in acs_attributes.attribute_name%TYPE,
    sort_order     in acs_attributes.sort_order%TYPE
  ) is

  begin

    update 
      acs_attributes    
    set
      sort_order = set_attribute_order.sort_order
    where
      object_type = set_attribute_order.content_type
    and
      attribute_name = set_attribute_order.attribute_name;
        
  end set_attribute_order;

  procedure unregister_attribute_widget (
    content_type   in acs_attributes.object_type%TYPE,
    attribute_name in acs_attributes.attribute_name%TYPE
  )
  is
    v_attr_id  acs_attributes.attribute_id%TYPE;
    v_widget   cm_form_widgets.widget%TYPE;
  begin
  
    -- Look for the attribute
    begin
      select attribute_id into v_attr_id from acs_attributes
        where attribute_name = unregister_attribute_widget.attribute_name
        and object_type = unregister_attribute_widget.content_type;

    exception when no_data_found then
        raise_application_error(-20000, 'Attribute ' || content_type ||
          ':' || attribute_name || 
          ' does not exist in cm_form_widget.unregister_attribute_widget'
        );
    end;   

    -- Look for the widget; if no widget is registered, just return
    begin
      select widget into v_widget from cm_attribute_widgets
        where attribute_id = v_attr_id;
    exception when no_data_found then
      return;
    end;  
  
    -- Delete the param values and the widget assignment
    delete from cm_attribute_widget_params 
      where attribute_id = v_attr_id 
      and param_id in (select param_id from cm_form_widgets
                         where widget = v_widget);

    delete from cm_attribute_widgets 
      where attribute_id = v_attr_id;

  end unregister_attribute_widget;  

  procedure set_attribute_param_value (
    content_type   in acs_attributes.object_type%TYPE,
    attribute_name in acs_attributes.attribute_name%TYPE,
    param          in cm_form_widget_params.param%TYPE,
    value          in cm_attribute_widget_params.value%TYPE,
    param_type     in cm_attribute_widget_params.param_type%TYPE 
                      default 'onevalue',
    param_source   in cm_attribute_widget_params.param_source%TYPE
                      default 'literal'
  )
  is
    v_attr_id    acs_attributes.attribute_id%TYPE;
    v_widget     cm_form_widgets.widget%TYPE;
    v_param_id   cm_form_widget_params.param_id%TYPE;
    v_prev_value integer;
  begin

    -- Get the attribute id and the widget 
    begin
      select 
	a.attribute_id, aw.widget into v_attr_id, v_widget 
      from 
	acs_attributes a, cm_attribute_widgets aw
      where 
	a.attribute_name = set_attribute_param_value.attribute_name
      and 
	a.object_type=set_attribute_param_value.content_type
      and
	aw.attribute_id = a.attribute_id;
    exception when no_data_found then
      raise_application_error(-20000, 
        'No widget is registered for attribute ' ||
        content_type || '.' || attribute_name || 
        ' in cm_form_widget.set_attribute_param_value');
    end;

    -- Get the param id
    begin
      select param_id into v_param_id from cm_form_widget_params
	where widget = v_widget 
	and param = set_attribute_param_value.param;
    exception when no_data_found then
      raise_application_error(-20000, 
        'No parameter named ' || param || 
        ' exists for the widget ' || v_widget ||
        ' in cm_form_widget.set_attribute_param_value');
    end;  

    -- Check if an old value exists
    -- Determine if a previous value exists
    select count(1) into v_prev_value from dual 
      where exists (select 1 from cm_attribute_widget_params
                    where attribute_id = v_attr_id
                    and param_id = v_param_id);
    
    if v_prev_value > 0 then
      -- Update the value
      update cm_attribute_widget_params set
        param_type = set_attribute_param_value.param_type,
        param_source = set_attribute_param_value.param_source,
        value = set_attribute_param_value.value
      where
        attribute_id = v_attr_id
      and
        param_id = v_param_id;
    else
      -- Insert a new value
      insert into cm_attribute_widget_params
        (attribute_id, param_id, param_type, param_source, value)
      values
        (v_attr_id, v_param_id, param_type, param_source, value);
    end if;
  end set_attribute_param_value;

end cm_form_widget;
/
show errors


@@cms-widgets
