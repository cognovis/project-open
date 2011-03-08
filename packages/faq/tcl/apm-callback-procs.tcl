ad_library {

    Procedures to do a new impl and aliases in the acs-sc.
    @creation date 2004-04-06
    @autor Gerardo Morales Cadoret (gmorales@galileo.edu)
}

namespace eval faq::apm_callback {}

ad_proc -private faq::apm_callback::package_install { 
} {
    Does the integration whith the notifications package. 
} {
    db_transaction {

	# Create the impl and aliases for one faq Q&A
	set impl_id [create_one_faq_qa_impl]

	# Create the notification type for one specific FAQ
	set type_id [create_one_faq_type $impl_id]

	# Enable the delivery intervals and delivery methods for a specific FAQ
	enable_intervals_and_methods $type_id

	# Create the impl and aliases for all faqs Q&A
	set impl_id [create_all_faq_qa_impl]

	# Create the notification type for all FAQs
	set type_id [create_all_faq_type $impl_id]

	# Enable the delivery intervals and delivery methods for all FAQs
	enable_intervals_and_methods $type_id
    }
}

ad_proc -private faq::apm_callback::package_uninstall {
} {
    Remove the integration whith the notification package
} {

    db_transaction {

        # Delete the type_id for a specific FAQ
        notification::type::delete -short_name one_faq_qa_notif

        # Delete the implementation for the notification of a new Q&A of one specific FAQ
        delete_one_faq_impl

        # Delete the type_id foe all FAQs
        notification::type::delete -short_name all_faq_qa_notif

        # Delete the implementation for the notification of a new Q&A all Faqs
	delete_all_faq_impl

    }
}


ad_proc -public faq::apm_callback::delete_one_faq_impl {} {
    Unregister the NotificationType implementation for one_faq_qa_notif_type.
} {
    acs_sc::impl::delete \
        -contract_name "NotificationType" \
        -impl_name one_faq_qa_notif_type
}


ad_proc -public faq::apm_callback::delete_all_faq_impl {} {
    Unregister the NotificationType implementation for one_faq_qa_notif_type.
} {
    acs_sc::impl::delete \
        -contract_name "NotificationType" \
        -impl_name all_faq_qa_notif_type
}

ad_proc -public faq::apm_callback::create_one_faq_qa_impl {} {
    Register the service contract implementation and return the impl_id
    @return impl_id of the created implementation 
} {
         return [acs_sc::impl::new_from_spec -spec {
	    name one_faq_qa_notif_type
	    contract_name NotificationType
	    owner faq
	    aliases {
		GetURL faq::notification::get_url
		ProcessReply faq::notification::process_reply
	    }
	 }]
}

ad_proc -public faq::apm_callback::create_one_faq_type {impl_id} {
    Create the notification type for one specific FAQ Q&A
    @return the type_id of the created type
} {
    return [notification::type::new \
		-sc_impl_id $impl_id \
		-short_name one_faq_qa_notif \
		-pretty_name "One FAQ Q&A" \
		-description "Notification of a new Q&A of one specific faq"]
}

ad_proc -public faq::apm_callback::enable_intervals_and_methods {type_id} {
    Enable the intervals and delivery methods of a specific type
} {
    # Enable the various intervals and delivery method
    notification::type::interval_enable \
	-type_id $type_id \
	-interval_id [notification::interval::get_id_from_name -name instant]

    notification::type::interval_enable \
	-type_id $type_id \
	-interval_id [notification::interval::get_id_from_name -name hourly]

    notification::type::interval_enable \
	-type_id $type_id \
	-interval_id [notification::interval::get_id_from_name -name daily]

    # Enable the delivery methods
    notification::type::delivery_method_enable \
	-type_id $type_id \
	-delivery_method_id [notification::delivery::get_id -short_name email]
}


ad_proc -public faq::apm_callback::create_all_faq_qa_impl {} {
    Register the service contract implementation and return the impl_id
    @retern impl_id of the created implementation 
} {
    return \
	[acs_sc::impl::new_from_spec -spec {
	    name all_faq_qa_notif_type
	    contract_name NotificationType
	    owner faq
	    aliases {
		GetURL faq::notification::get_url
		ProcessReply faq::notification::process_reply
	    }
	}]

}

ad_proc -public faq::apm_callback::create_all_faq_type {impl_id} {
    Create the notification type for one specific FAQ Q&A
    @return the type_id of the created type
} {
    set type_id [notification::type::new \
		     -sc_impl_id $impl_id \
		     -short_name all_faq_qa_notif \
		     -pretty_name "FAQ Q&A" \
		     -description "Notification of a new Q&A of any faq"]
}
