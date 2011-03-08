<?xml version="1.0"?>
<queryset>

<fullquery name="pagination::get_total_pages.gtp_get_total_pages">      
      <querytext>
      
	  select 
	    ceil(count(*) / [pagination::get_rows_per_page] )
	  from
            ($sql) x
	
      </querytext>
</fullquery>


</queryset>
