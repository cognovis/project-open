<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_widget">      
      <querytext>
      
	  begin
	  cm_form_widget.register_attribute_widget(
              content_type   => :content_type,
              attribute_name => :attribute_name,
              widget         => :widget,
              is_required    => :is_required
          );
	  end;
      </querytext>
</fullquery>

 
<fullquery name="update_widgets">      
      <querytext>
      
	  update cm_attribute_widgets
            set is_required = case when is_required = 't' then 'f' else 't' end
            where attribute_id = :attribute_id
            and widget = :widget
      </querytext>
</fullquery>

</queryset>
