<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_survey_scores_summary">      
      <querytext>
      select variable_name, to_char(avg(sum_score), '9999.9') as mean_score,
                                          min(sum_score) as min_score,
                                          max(sum_score) as max_score,
                                          count(sum_score) as count_score,
                                          coalesce(to_char(stddev_samp(sum_score), '9999.9'), '0.0') as sd_score                                           
                                          from
                                          (select variable_name, sum(score) as sum_score
	                                    from survsimp_choice_scores, survsimp_question_responses, survsimp_variables,
                                            survsimp_responses
                                            where survsimp_choice_scores.choice_id = survsimp_question_responses.choice_id
                                            and survsimp_choice_scores.variable_id = survsimp_variables.variable_id
                                            and survsimp_responses.response_id = survsimp_question_responses.response_id
                                            and survey_id = :local_survey_id
                                            group by survsimp_responses.response_id, variable_name)
                                          group by variable_name
      </querytext>
</fullquery>

 
</queryset>
