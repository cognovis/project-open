<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="within_clause">      
      <querytext>

        ${the_or}%[string tolower $word]% within \\$field

      </querytext>
</partialquery>

<partialquery name="contains_clause">      
      <querytext>

       $the_or contains($column_name, '$search_clause', $label) > 0 

      </querytext>
</partialquery>

<partialquery name="score_expr">      
      <querytext>

        $the_plus score($label)

      </querytext>
</partialquery>

<partialquery name="sql_query">      
      <querytext>

    select 
      i.item_id, content_item__get_path(i.item_id,null) as item_path,
      r.revision_id,
      t.pretty_name as pretty_type, t.object_type,
      r.title, to_char(r.publish_date,'YYYY-MM-DD') as pretty_date,
      coalesce(coalesce(m.label, r.mime_type), 'unknown') as pretty_mime_type,
      1 as row_index,
      1 as search_score
    from
      cr_items i[ad_decode $live_p 1 " LEFT OUTER JOIN" ,] 
      cr_revisions r[ad_decode $live_p 1 " ON i.live_revision = r.revision_id" ""]
        LEFT OUTER JOIN 
      cr_mime_types m using (mime_type), 
      acs_object_types t
    where
      t.object_type = i.content_type
    and
      r.revision_id in ([join [content_search__search_ids $keywords] ,])

      </querytext>
</partialquery>

<partialquery name="live_revision">      
      <querytext>

      

      </querytext>
</partialquery>

</queryset>
