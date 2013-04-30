<?xml version="1.0"?>

<queryset>

<fullquery name="select_df_itens">
      <querytext>
          select df_item_id,
                 timestamp,
	          filesystem,
	          size,
	          used,
	          avail,
	          used_percent,
	          mounted	   
	  from    ad_monitoring_top_df_item i,
                 ad_monitoring_df d
	  where i.df_id = d.df_id
         [template::list::filter_where_clauses -and -name "df_itens"]
	  [template::list::page_where_clause -and -name "df_itens" -key "df_item_id"]
	  [template::list::orderby_clause -orderby -name "df_itens"]
      </querytext>
</fullquery> 


<fullquery name="df_itens_pagination">
      <querytext>
          select df_item_id,
                 timestamp,
	          filesystem,
	          size,
	          used,
	          avail,
	          used_percent,
	          mounted	   
	  from    ad_monitoring_top_df_item i,
                 ad_monitoring_df d
	  where i.df_id = d.df_id
         [template::list::filter_where_clauses -and -name "df_itens"]
	  [template::list::orderby_clause -orderby -name "df_itens"]

      </querytext>
</fullquery> 


<fullquery name="select_lista_mounted">
      <querytext>
     
      select  count(df_item_id) as num_itens,
              mounted
       from   ad_monitoring_top_df_item
       group  by mounted
      
      </querytext>
</fullquery>






</queryset>
