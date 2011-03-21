<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="widget::process_param.pp_proces_param">      
      <querytext>

	select cm_form_widget__set_attribute_param_value (:content_type, :attribute_name, :param_$order, :param_value_$order, :param_type_$order, :param_source_$order)

      </querytext>
</fullquery>

 
</queryset>
