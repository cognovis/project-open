<?xml version="1.0"?>
<queryset>

<fullquery name="category_insert">      
      <querytext>
      insert into categories 
  (category_id, category,category_type)
  values (:category_id, :category, 'survsimp')
      </querytext>
</fullquery>

 
<fullquery name="survey_name">      
      <querytext>
      
  select name from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
