<?xml version="1.0"?>
<queryset>

<fullquery name="renumber_sort_keys">      
      <querytext>
      update survsimp_questions
                                   set sort_key = sort_key + 1
                                   where survey_id = :survey_id
                                   and sort_key > :after
      </querytext>
</fullquery>

 
<fullquery name="add_question_text">      
      <querytext>
      
	    update survsimp_questions
	    set question_text = :question_text
	    where question_id = :question_id
	
      </querytext>
</fullquery>

 
<fullquery name="insert_survsimp_question_choice">      
      <querytext>
      insert into survsimp_question_choices
      (choice_id, question_id, label, sort_order)
      values
      (:choice_id, :question_id, :trimmed_response, :count)
      </querytext>
</fullquery>

 
<fullquery name="insert_survsimp_scores">      
      <querytext>
      insert into survsimp_choice_scores
      (choice_id, variable_id, score)
      values
      (:choice_id, :variable_id, :score)
      </querytext>
</fullquery>

 
<fullquery name="renumber_sort_keys">      
      <querytext>
      update survsimp_questions
                                   set sort_key = sort_key + 1
                                   where survey_id = :survey_id
                                   and sort_key > :after
      </querytext>
</fullquery>

 
<fullquery name="already_inserted_p">
      <querytext>

      select case when count(*) = 0 then 0 else 1 end from survsimp_questions where question_id = :question_id

      </querytext>
</fullquery>

 
</queryset>
