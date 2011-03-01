<?xml version="1.0"?>
<queryset>

<fullquery name="get_survey_type">      
      <querytext>
      select type from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="set_survey_name">      
      <querytext>
      select name from survsimp_surveys where survey_id = :survey_id
      </querytext>
</fullquery>

 
<fullquery name="get_logic">      
      <querytext>
      select logic, survsimp_logic.logic_id from survsimp_logic, survsimp_logic_surveys_map
where survsimp_logic.logic_id = survsimp_logic_surveys_map.logic_id
and survey_id = :survey_id
      </querytext>
</fullquery>

 
</queryset>
