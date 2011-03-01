<?xml version="1.0"?>
<queryset>

<fullquery name="survey_name">      
      <querytext>
      select type
  from survsimp_surveys
  where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_survey_question_list">      
      <querytext>
      select question_id, question_text, abstract_data_type
from survsimp_questions
where survey_id = :survey_id
order by sort_key
      </querytext>
</fullquery>

 
<fullquery name="survsimp_boolean_summary">      
      <querytext>
select count(*) as n_responses, (case when boolean_answer = 't' then 'True' when boolean_answer = 'f' then 'False' end) as boolean_answer
from $question_responses_table
where question_id = :question_id
group by boolean_answer
order by boolean_answer desc
      </querytext>
</fullquery>

 
<fullquery name="survsimp_number_summary">      
      <querytext>
      select count(*) as n_responses, number_answer
from $question_responses_table
where question_id = :question_id
group by number_answer
order by number_answer
      </querytext>
</fullquery>

 
<fullquery name="survsimp_number_average">      
      <querytext>
      select avg(number_answer) as mean, stddev(number_answer) as standard_deviation
from $question_responses_table
where question_id = :question_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_survey_question_choices">      
      <querytext>
      select count(*) as n_responses, label, qc.choice_id
from $question_responses_table qr, survsimp_question_choices qc
where qr.choice_id = qc.choice_id
  and qr.question_id = :question_id
group by label, sort_order, qc.choice_id
order by sort_order
      </querytext>
</fullquery>

 
<fullquery name="survey_name">      
      <querytext>
      select type
  from survsimp_surveys
  where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="survsimp_number_responses">      
      <querytext>
      select count(*)
from $responses_table
where survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
