<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_update_description">      
      <querytext>
      update survsimp_surveys 
      set description = :description,
          description_html_p = :desc_html
          where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
