<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_survey_properties">      
      <querytext>
      select name, description, type
    from survsimp_surveys
    where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="count_variable_names">      
      <querytext>
      select count(variable_name) as n_variables
	from survsimp_variables, survsimp_variables_surveys_map
        where survsimp_variables.variable_id = survsimp_variables_surveys_map.variable_id
        and survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
