<?xml version="1.0"?>
<queryset>

<fullquery name="short_name_uniqueness_check">      
      <querytext>
      
select count(short_name)
from survsimp_surveys
where lower(short_name) = lower(:short_name)
      </querytext>
</fullquery>

 
<fullquery name="add_variable_name">      
      <querytext>
      insert into survsimp_variables
                  (variable_id, variable_name)
                  values
                  (:variable_id, :variable_name)
      </querytext>
</fullquery>

 
<fullquery name="map_variable_name">      
      <querytext>
      insert into survsimp_variables_surveys_map
                  (variable_id, survey_id)
                  values
                  (:variable_id, :survey_id)
      </querytext>
</fullquery>

 
<fullquery name="map_logic">      
      <querytext>
      insert into survsimp_logic_surveys_map
              (logic_id, survey_id)
              values
              (:logic_id, :survey_id)
      </querytext>
</fullquery>

 
</queryset>
