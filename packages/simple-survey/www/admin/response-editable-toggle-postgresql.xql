<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="survsimp_response_editable_toggle">      
      <querytext>
      update survsimp_surveys set single_editable_p = util__logical_negation(single_editable_p)
where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
