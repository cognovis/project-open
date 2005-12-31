<?xml version="1.0"?>
<queryset>

    <fullquery name="select_respondents">      
        <querytext>
            select persons.first_names || ' ' || persons.last_name as name,
                   acs_objects.creation_user as user_id,
                   parties.email
            from survsimp_responses,
                 persons,
                 parties,
                 acs_objects
            where survsimp_responses.survey_id = :survey_id
            and survsimp_responses.response_id = acs_objects.object_id
            and acs_objects.creation_user = persons.person_id
            and persons.person_id = parties.party_id
            group by acs_objects.creation_user,
                     parties.email,
                     persons.first_names,
                     persons.last_name
            order by persons.last_name
        </querytext>
    </fullquery>

    <fullquery name="select_survey_name">      
        <querytext>
            select name
            from survsimp_surveys
            where survey_id = :survey_id
        </querytext>
    </fullquery>
 
</queryset>
