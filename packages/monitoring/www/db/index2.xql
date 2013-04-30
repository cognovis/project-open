<?xml version="1.0"?>

<queryset>

<fullquery name="select_db_itens">
      <querytext>
          select  db_id,
                  to_char(timestamp,'DD/MM/YY HH24:MI') as timestamp,
                  timehour,
                  db_size,
                  size_content_repository
         from     ad_monitoring_db
	 order by db_id
        
      </querytext>
</fullquery> 




</queryset>
