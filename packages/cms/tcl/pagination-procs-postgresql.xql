<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="pagination::paginate_query.pg_paginate_query">
	<querytext>

      select *
      from
        (
	   $sql
        ) ordered_sql_query_with_row_id
      LIMIT
        $rows_per_page
      OFFSET
        $start_row

	</querytext>
</partialquery>


</queryset>
