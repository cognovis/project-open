<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_views">
    <querytext>
	select 	r.report_id,
		r.report_name,
		c.category as report_type,
		c2.category as report_status,
		v.view_name as view_name 
	from im_reports r,
	     im_views v,
	     im_categories c,
	     im_categories c2
	where r.view_id = v.view_id
	and   r.report_type_id = c.category_id
	and   r.report_status_id = c2.category_id
	order by r.report_name	
    </querytext>
</fullquery>

</queryset>
