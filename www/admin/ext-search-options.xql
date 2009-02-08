<?xml version="1.0"?>
<queryset>

<fullquery name="ext_options">      
    <querytext>
	select 
		* 
	from 
		contact_extend_options 
		$extra_query
		[template::list::orderby_clause -orderby -name "ext_options"]
    </querytext>
</fullquery>      

<fullquery name="def_ext_options">      
    <querytext>
	select 
		*
	from 
		contact_extend_options 
		$def_extra_query
    </querytext>
</fullquery>      

</queryset>