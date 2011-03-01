<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="survsimp_question_required_toggle">      
      <querytext>
      update survsimp_questions set required_p = util__logical_negation(required_p)
where survey_id = :survey_id
and question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>
