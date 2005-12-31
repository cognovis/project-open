<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="survsimp_reponse_toggle">      
      <querytext>
      update survsimp_surveys 
set single_response_p = util__logical_negation(single_response_p)
where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
