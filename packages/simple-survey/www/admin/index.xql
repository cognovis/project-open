<?xml version="1.0"?>
<queryset>

<fullquery name="survsimp_surveys">      
      <querytext>
      select survey_id, name, enabled_p
from survsimp_surveys
where package_id= :package_id
order by enabled_p desc, upper(name)
      </querytext>
</fullquery>

 
</queryset>
