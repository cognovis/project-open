<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="survey_select">      
      <querytext>
      
    select survey_id, name
    from survsimp_surveys, acs_objects
    where object_id = survey_id
    and context_id = :package_id
    and acs_permission__permission_p(object_id, :user_id, 'survsimp_take_survey') = 't'
    and enabled_p = 't'
    order by upper(name)

      </querytext>
</fullquery>

 
</queryset>
