<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<partialquery name="within_clause">      
      <querytext>

        ${the_or}%[string tolower $word]% within \$field

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
      i.item_id, content_item.get_path(i.item_id) item_path,
      r.revision_id,
      t.pretty_name as pretty_type, t.object_type,
      r.title, to_char(r.publish_date) as pretty_date,
      NVL(NVL(m.label, r.mime_type), 'unknown') as pretty_mime_type,
      rownum as row_index,
      ($score_expr) as search_score
    from
      cr_items i, cr_revisions r, 
      cr_mime_types m, acs_object_types t $attrs_table
    where
      m.mime_type(+) = r.mime_type
    and
      t.object_type = i.content_type $attrs_where
    and
      ($contains_clause)

      </querytext>
</partialquery>

<partialquery name="live_revision">      
      <querytext>

           and r.revision_id(+) = i.live_revision 

      </querytext>
</partialquery>

</queryset>
