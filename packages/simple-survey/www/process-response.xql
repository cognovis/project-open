<?xml version="1.0"?>
<queryset>

<fullquery name="survey_exists">      
      <querytext>
      
	    select 1 from survsimp_surveys where survey_id = :survey_id
	
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_info_list">      
      <querytext>
      
	    select question_id, question_text, abstract_data_type, presentation_type, required_p
	    from survsimp_questions
	    where survey_id = :survey_id
	    and active_p = 't'
	    order by sort_key
	
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_info_list">      
      <querytext>
      
	    select question_id, question_text, abstract_data_type, presentation_type, required_p
	    from survsimp_questions
	    where survey_id = :survey_id
	    and active_p = 't'
	    order by sort_key
	
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_response_checkbox_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_response_choice_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, choice_id)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_choice_shorttext_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, varchar_answer)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_response_boolean_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, boolean_answer)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_response_integer_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, number_answer)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="survsimp_question_response_date_insert">      
      <querytext>
      insert into survsimp_question_responses (response_id, question_id, date_answer)
 values (:response_id, :question_id, :response_value)
      </querytext>
</fullquery>

 
<fullquery name="get_type">      
      <querytext>
      select type from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_name_from_id">      
      <querytext>
      select name from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="get_score">      
      <querytext>
      select variable_name, sum(score) as sum_of_scores
                           from survsimp_choice_scores, survsimp_question_responses, survsimp_variables
                           where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
                           and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
                           and survsimp_question_responses.response_id = :response_id
                           group by variable_name
      </querytext>
</fullquery>

 
<fullquery name="get_logic">      
      <querytext>
      select logic from survsimp_logic, survsimp_logic_surveys_map
          where survsimp_logic.logic_id = survsimp_logic_surveys_map.logic_id
          and survey_id = :survey_id
      </querytext>
</fullquery>


<fullquery name="survsimp_question_response_blob_insert">
      <querytext>

      insert into survsimp_question_responses
      (response_id, question_id, item_id,
      content_length,
      attachment_file_name, attachment_file_type,
      attachment_file_extension)
      values
      (:response_id, :question_id, :item_id,
      :content_length,
      :response_value, :guessed_file_type,
      :file_extension)

      </querytext>
</fullquery>

</queryset>
