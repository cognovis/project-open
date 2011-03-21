/* cms-widgets.sql - metadata for form widgets */



/* insert form widgets and params */
begin

  -- insert the standard form widgets
  insert into cm_form_widgets (widget) values ('text');
  insert into cm_form_widgets (widget) values ('textarea');
  insert into cm_form_widgets (widget) values ('radio');
  insert into cm_form_widgets (widget) values ('checkbox');
  insert into cm_form_widgets (widget) values ('select');
  insert into cm_form_widgets (widget) values ('multiselect');
  insert into cm_form_widgets (widget) values ('date');


  -- insert the standard form widget params and ATS form element params
  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (10, 'text', 'size', 'f', 't', '30');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (20, 'textarea', 'rows', 'f', 't', '6');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (30, 'textarea', 'cols', 'f', 't', '60');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (31, 'textarea', 'wrap', 'f', 't', 'physical');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (40, 'radio', 'options', 't', 'f', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (50, 'checkbox', 'options', 't', 'f', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (60, 'select', 'options', 't', 'f', '{ -- {} }');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (61, 'select', 'values', 'f', 'f', '{}');


  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (70, 'select', 'size', 'f', 't', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (80, 'multiselect', 'options', 't', 'f', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (90, 'multiselect', 'size', 'f', 't', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (100, 'date', 'format', 'f', 'f', 'DD/MONTH/YYYY');

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (110, 'date', 'year_interval', 'f', 'f', '2000 2005 1');

end;
/
show errors

begin

  /* search widget and params */
  dbms_output.put_line('Inserting search widget metadata...');

  insert into cm_form_widgets (widget) values ('search');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (120, 'search', 'search_query', 't', 'f',  null);

end;
/
show errors






begin

  /* new widget params 11-31-00 */
  dbms_output.put_line('Inserting new widget metadata...');

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (11, 'text', 'maxlength', 'f', 't',  null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (12, 'text', 'validate', 'f', 'f',  null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (32, 'textarea', 'validate', 'f', 'f',  null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (41, 'radio', 'values', 'f', 'f', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (51, 'checkbox', 'values', 'f', 'f', null);

  insert into cm_form_widget_params 
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (91, 'multiselect', 'values', 'f', 'f', null);

  insert into cm_form_widget_params
    (param_id, widget, param, is_required, is_html, default_value)
  values
    (121, 'search', 'result_datatype', 'f', 'f', 'search');

end;
/
show errors












/* Register attribute widgets for content_revision and image */

begin
  -- register form widgetes for content revision attributes

  cm_form_widget.register_attribute_widget(
      content_type   => 'content_revision', 
      attribute_name => 'title', 
      widget	     => 'text', 
      is_required    => 't'
  );

  cm_form_widget.register_attribute_widget(
      content_type   => 'content_revision', 
      attribute_name => 'description', 
      widget	     => 'textarea'
  );

  cm_form_widget.set_attribute_param_value(
      content_type   => 'content_revision', 
      attribute_name => 'description', 
      param	     => 'cols', 
      param_type     => 'onevalue', 
      param_source   => 'literal', 
      value	     => 40
  );

  cm_form_widget.register_attribute_widget(
      content_type   => 'content_revision', 
      attribute_name => 'mime_type', 
      widget	     => 'select',
      is_required    => 't'
  );
  
  cm_form_widget.set_attribute_param_value(
      content_type   => 'content_revision', 
      attribute_name => 'mime_type', 
      param	     => 'options', 
      param_type     => 'multilist', 
      param_source   => 'query',
      value	     => 'select 
                           label, map.mime_type as value 
                         from 
			   cr_mime_types types, 
			   cr_content_mime_type_map map 
			 where 
			   types.mime_type = map.mime_type 
			 and 
			   content_type = :content_type 
			 order by 
			   label'
  );

  cm_form_widget.set_attribute_param_value(
      content_type   => 'content_revision', 
      attribute_name => 'mime_type', 
      param	     => 'values', 
      param_type     => 'onevalue', 
      param_source   => 'query',
      value	     => 'select 
                           mime_type
			 from
			   cr_revisions
			 where
			   revision_id = content_item.get_latest_revision(:item_id)'
  );

  -- register for widgets for image attributes

  cm_form_widget.register_attribute_widget(
      content_type   => 'image', 
      attribute_name => 'width', 
      widget	     => 'text'
  );

  cm_form_widget.register_attribute_widget(
      content_type   => 'image', 
      attribute_name => 'height', 
      widget	     => 'text'
  ); 
  
  cm_form_widget.set_attribute_param_value(
      content_type   => 'image', 
      attribute_name => 'width', 
      param	     => 'size', 
      param_type     => 'onevalue',
      param_source   => 'literal', 
      value	     => 5
  );

  cm_form_widget.set_attribute_param_value(
      content_type   => 'image', 
      attribute_name => 'height', 
      param	     => 'size', 
      param_type     => 'onevalue', 
      param_source   => 'literal', 
      value	     => 5
  );

end;
/
show errors



begin

  /* new widget params 11-31-00 */
  dbms_output.put_line('Inserting new widget attributes...');

  cm_form_widget.set_attribute_param_value(
      content_type   => 'content_revision', 
      attribute_name => 'title', 
      param	     => 'maxlength', 
      param_type     => 'onevalue', 
      param_source   => 'literal', 
      value	     => 1000
  );

  cm_form_widget.set_attribute_param_value (
      content_type   => 'content_revision',
      attribute_name => 'description',
      param	     => 'validate',
      param_type     => 'onevalue',
      param_source   => 'literal',
      value          => 'description_4k_max { cm_widget::validate_description $value } {  Description length cannot exceed 4000 bytes. }'
  );

end;
/
show errors
