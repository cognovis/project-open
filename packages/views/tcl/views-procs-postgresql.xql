<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="views::record_view.record_view">      
	<querytext>
	select views__record_view(:object_id, :viewer_id)
	</querytext>
</fullquery>

<fullquery name="views::record_view.record_view_by_type">      
	<querytext>
	select views_by_type__record_view(:object_id, :viewer_id, :type)
	</querytext>
</fullquery>


</queryset>