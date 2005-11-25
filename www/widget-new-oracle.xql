<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_widget">
  <querytext>
BEGIN
	:1 := im_dynfield_widget.new (
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

</queryset>
