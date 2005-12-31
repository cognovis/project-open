<?xml version="1.0"?>
<queryset>

<fullquery name="swap_sort_keys">      
      <querytext>
update survsimp_questions
set sort_key = (case when sort_key = :sort_key then :next_sort_key when sort_key = :next_sort_key then :sort_key end)
where survey_id = :survey_id
and sort_key in (:sort_key, :next_sort_key)
      </querytext>
</fullquery>

 
</queryset>
