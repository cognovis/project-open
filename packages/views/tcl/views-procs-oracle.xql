<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>9.2.0</version></rdbms>

<fullquery name="views::record_view.record_view">      
	<querytext>
	begin
        :1 := views_view.record_view(p_object_id => :object_id, 
        			     p_viewer_id => :viewer_id);
    end;
	</querytext>
</fullquery>

<fullquery name="views::record_view.record_view_by_type">      
	<querytext>
	begin
        :1 := views_view_by_type.record_view(p_object_id => :object_id, 
        			     p_viewer_id => :viewer_id,
        			     p_view_type => :type);
    end;
	</querytext>
</fullquery>

</queryset>