/* cms-widgets.sql - metadata for form widgets */



/* insert form widgets and params */
create or replace function inline_0 ()
returns integer as '
begin

  -- insert the standard form widgets
  insert into cm_form_widgets (widget) values (''text'');
  insert into cm_form_widgets (widget) values (''textarea'');
  insert into cm_form_widgets (widget) values (''radio'');
  insert into cm_form_widgets (widget) values (''checkbox'');
  insert into cm_form_widgets (widget) values (''select'');
  insert into cm_form_widgets (widget) values (''multiselect'');
  insert into cm_form_widgets (widget) values (''date'');


  -- insert the standard form widget params and ATS form element params
  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (10, ''text'', ''size'', ''f'', ''t'', ''30'');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (20, ''textarea'', ''rows'', ''f'', ''t'', ''6'');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (30, ''textarea'', ''cols'', ''f'', ''t'', ''60'');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (31, ''textarea'', ''wrap'', ''f'', ''t'', ''physical'');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (40, ''radio'', ''options'', ''t'', ''f'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (50, ''checkbox'', ''options'', ''t'', ''f'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (60, ''select'', ''options'', ''t'', ''f'', ''{ -- {} }'');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (61, ''select'', ''values'', ''f'', ''f'', ''{}'');


  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (70, ''select'', ''size'', ''f'', ''t'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (80, ''multiselect'', ''options'', ''t'', ''f'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (90, ''multiselect'', ''size'', ''f'', ''t'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (100, ''date'', ''format'', ''f'', ''f'', ''DD/MONTH/YYYY'');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (110, ''date'', ''year_interval'', ''f'', ''f'', ''2000 2005 1'');

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

create or replace function inline_1 ()
returns integer as '
begin

  /* search widget and params */
  raise notice ''Inserting search widget metadata...'';

  insert into cm_form_widgets (widget) values (''search'');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (120, ''search'', ''search_query'', ''t'', ''f'',  null);

  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors






create or replace function inline_2 ()
returns integer as '
begin

  /* new widget params 11-31-00 */
  raise notice ''Inserting new widget metadata...'';

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (11, ''text'', ''maxlength'', ''f'', ''t'',  null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (12, ''text'', ''validate'', ''f'', ''f'',  null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (32, ''textarea'', ''validate'', ''f'', ''f'',  null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (41, ''radio'', ''values'', ''f'', ''f'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (51, ''checkbox'', ''values'', ''f'', ''f'', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (91, ''multiselect'', ''values'', ''f'', ''f'', null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (121, ''search'', ''result_datatype'', ''f'', ''f'', ''search'');

  return 0;
end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();


-- show errors












/* Register attribute widgets for content_revision and image */

create or replace function inline_3 ()
returns integer as '
begin
  -- register form widgetes for content revision attributes

  PERFORM cm_form_widget__register_attribute_widget(
      ''content_revision'', 
      ''title'', 
      ''text'', 
      ''t''
  );

  PERFORM cm_form_widget__register_attribute_widget(
      ''content_revision'', 
      ''description'', 
      ''textarea'',
      ''f''
  );

  PERFORM cm_form_widget__set_attribute_param_value(
      ''content_revision'', 
      ''description'', 
      ''cols'', 
      40,
      ''onevalue'', 
      ''literal''
  );

  PERFORM cm_form_widget__register_attribute_widget(
      ''content_revision'', 
      ''mime_type'', 
      ''select'',
      ''t''
  );
  
  PERFORM cm_form_widget__set_attribute_param_value(
      ''content_revision'', 
      ''mime_type'', 
      ''options'', 
      ''select 
          label, map.mime_type as value 
        from 
	  cr_mime_types types, 
	  cr_content_mime_type_map map 
	where 
	  types.mime_type = map.mime_type 
	and 
	  content_type = :content_type 
	order by 
	  label'',
      ''multilist'', 
      ''query''
  );

  PERFORM cm_form_widget__set_attribute_param_value(
      ''content_revision'', 
      ''mime_type'', 
      ''values'', 
      ''select 
          mime_type
	from
	  cr_revisions
	where
	  revision_id = content_item__get_latest_revision(:item_id)'',
      ''onevalue'', 
      ''query''
  );

  -- register for widgets for image attributes

  PERFORM cm_form_widget__register_attribute_widget(
      ''image'', 
      ''width'', 
      ''text'',
      ''f''
  );

  PERFORM cm_form_widget__register_attribute_widget(
      ''image'', 
      ''height'', 
      ''text'',
      ''f''
  ); 
  
  PERFORM cm_form_widget__set_attribute_param_value(
      ''image'', 
      ''width'', 
      ''size'', 
      5,
      ''onevalue'',
      ''literal''
  );

  PERFORM cm_form_widget__set_attribute_param_value(
      ''image'', 
      ''height'', 
      ''size'', 
      5,
      ''onevalue'', 
      ''literal'' 
  );

  return 0;
end;' language 'plpgsql';

select inline_3 ();

drop function inline_3 ();


-- show errors



create or replace function inline_4 ()
returns integer as '
begin

  /* new widget params 11-31-00 */

  PERFORM cm_form_widget__set_attribute_param_value(
      ''content_revision'', 
      ''title'', 
      ''maxlength'', 
      1000,
      ''onevalue'', 
      ''literal''
  );

  PERFORM cm_form_widget__set_attribute_param_value (
      ''content_revision'',
      ''description'',
      ''validate'',
      ''description_4k_max { cm_widget::validate_description $value } {  Description length cannot exceed 4000 bytes. }'',
      ''onevalue'',
      ''literal''
  );

  return 0;
end;' language 'plpgsql';

select inline_4 ();

drop function inline_4 ();


-- show errors
