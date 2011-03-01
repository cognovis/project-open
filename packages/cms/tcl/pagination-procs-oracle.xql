<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="pagination::paginate_query.pg_paginate_query">
	<querytext>

      select *
      from
        (
          select 
            x.*, rownum as row_id
	  from
	    ($sql) x
        ) ordered_sql_query_with_row_id
      where
        row_id between $start_row and $start_row + $rows_per_page - 1

	</querytext>
</partialquery>

</queryset>
