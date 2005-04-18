<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="widget::process_param.pp_proces_param">      
      <querytext>
      
      begin
      cm_form_widget.set_attribute_param_value (
          content_type   => :content_type,
          attribute_name => :attribute_name,
          param          => :param_$order,
          param_type     => :param_type_$order,
          param_source   => :param_source_$order,
          value          => :param_value_$order
      );
      end;
      </querytext>
</fullquery>

 
</queryset>
