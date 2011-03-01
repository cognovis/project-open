<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_widget">
  <querytext>
BEGIN
	:1 := dynfield_widget.new (
                widget_name =>          :widget_name,
                pretty_name =>          :pretty_name,
                pretty_plural =>        :pretty_plural,
                storage_type =>         :storage_type,
                acs_datatype =>         :acs_datatype,
                widget =>               :widget,
                sql_datatype =>         :sql_datatype,
                parameters =>           :parameters
        );
END;
  </querytext>
</fullquery>

<fullquery name="create_object">
  <querytext>
BEGIN
	:1 := acs_object.new (
                object_id =>		null,
                object_type =>		'dynfield_attribute',
                creation_date =>	sysdate,
                creation_user =>	'[ad_get_user_id]'
        );
END;
  </querytext>
</fullquery>

</queryset>
