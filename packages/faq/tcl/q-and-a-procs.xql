<?xml version="1.0"?>

<queryset>

    <fullquery name="faq::notification_delivery::do_notification.select_faq_name">
        <querytext>
        select faq_name from 
        faqs where faq_id = :faq_id
        </querytext>
    </fullquery>

    <fullquery name="faq::notification_delivery::do_notification.select_user_name">
        <querytext>
        select persons.first_names || ' ' || persons.last_name as name,
                                  parties.email        
                                  from persons, parties
                                  where person_id = :user_id
                                  and person_id = party_id
        </querytext>
    </fullquery>


</queryset>
