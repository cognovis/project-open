ad_library {

    Faq Library - Reply Handling
    @creation-date 2004-04-02
    @Author Gerardo Morales <gmorales@galileo.edu>
}


namespace eval faq::notification_delivery {

    ad_proc -public do_notification {
    question 
    answer 
    entry_id 
    faq_id
    user_id
    } { 

	db_1row  select_faq_name {*SQL*}
        db_1row select_user_name {*SQL*}
	set q_a_text ""
	append q_a_text "Question: $question
Answer: $answer"
	set text_version ""
	set faq_url [faq::notification::get_url $entry_id]
	
	append text_version "Faq: $faq_name
Author: $name ($email)\n\n"
         append text_version [wrap_string $q_a_text]
     append text_version "\n\n-- 
To view the entire FAQ go to: 
$faq_url
"
    set new_content $text_version
    set package_id [ad_conn package_id]

    # Notifies the users that requested notification for the specific FAQ

    notification::new \
        -type_id [notification::type::get_type_id \
        -short_name one_faq_qa_notif] \
        -object_id $faq_id \
        -response_id $entry_id \
        -notif_subject "New Q&A of $faq_name" \
         -notif_text $new_content


    # Notifies the users that requested notification for all FAQ's

    notification::new \
        -type_id [notification::type::get_type_id \
        -short_name all_faq_qa_notif] \
        -object_id $package_id \
        -response_id $entry_id \
        -notif_subject "New Q&A of $faq_name" \
         -notif_text $new_content



    }
}
