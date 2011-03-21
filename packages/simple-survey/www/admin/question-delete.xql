<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_id_from_qeustion_id">      
      <querytext>
      select survey_id from survsimp_questions where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_number_responses">      
      <querytext>
      select count(*)
from survsimp_question_responses
where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_choices_score_delete">      
      <querytext>

      delete from survsimp_choice_scores 
      where choice_id in (select choice_id from survsimp_question_choices
          where question_id = :question_id)

      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_choices_delete">      
      <querytext>
      delete from survsimp_question_choices where
         question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>
