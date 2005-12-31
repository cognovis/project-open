<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_survey_id_from_question_id">      
      <querytext>
      select survey_id from survsimp_questions where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_responses_delete">      
      <querytext>
      delete from survsimp_question_responses where question_id = :question_id
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
      delete from survsimp_question_choices where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_questions_delete">      
      <querytext>
      delete from survsimp_questions where question_id = :question_id
      </querytext>
</fullquery>

 
</queryset>
