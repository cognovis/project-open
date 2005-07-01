<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="get_views">
    <querytext>
	select 	r.report_id,
		r.report_name,
		c.category as report_type,
		c2.category as report_status,
		v.view_name as view_name 
	from im_reports r
		LEFT OUTER JOIN
	     im_views v ON r.view_id = v.view_id
		LEFT OUTER JOIN
	     im_categories c ON r.report_type_id = c.category_id
	     	LEFT OUTER JOIN
	     im_categories c2 ON r.report_status_id = c2.category_id
	order by r.report_name	     
    </querytext>
</fullquery>

</queryset>
