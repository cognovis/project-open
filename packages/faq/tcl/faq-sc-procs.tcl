ad_library {
    FAQ Fts contract bindings.

    @creation-date 2004-04-01
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id: faq-sc-procs.tcl,v 1.2 2004/04/27 12:26:05 jeffd Exp $
}

namespace eval faq::fts {}

ad_proc -private faq::fts::datasource { faq_id } {
    returns a datasource for a faq event to 
    be indexed by the full text search engine.

    @param faq_id

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    set title [db_string name {select faq_name from faqs where faq_id = :faq_id} -default "FAQ $faq_id"]
    set content {}
    db_foreach qa { select question, answer from faq_q_and_as where faq_id = :faq_id } {
        append content "Q: $question\n\nA: $answer\n\n"
    }

    return [list object_id $faq_id \
                title $title \
                content $content \
                keywords {} \
                storage_type text \
                mime text/plain ]
}

ad_proc -private faq::fts::url { faq_id } {
    returns a url for a faq to the search package

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    set faq_package_id [db_string package_id {select package_id from acs_objects where object_id = :faq_id} -default {}]

    return "[ad_url][apm_package_url_from_id $faq_package_id]one-faq?faq_id=$faq_id"
}

namespace eval faq_qanda::fts {}


ad_proc -private faq_qanda::fts::datasource { entry_id } {
    returns a datasource for a faq q/a to 
    be indexed by the full text search engine.

    @param entry_id

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    set title [db_string name {
        select f.faq_name from faqs f
        where faq_id = (select faq_id from faq_q_and_as where entry_id = :entry_id)
    } -default "FAQ $entry_id"]

    if {[db_0or1row get {select question, answer from faq_q_and_as where entry_id = :entry_id}]} { 
        append title ": $question"
        set content "Q: $question\n\nA: $answer\n\n"
    } else { 
        set content {}
    }

    return [list object_id $entry_id \
                title $title \
                content $content \
                keywords {} \
                storage_type text \
                mime text/plain ]
}

ad_proc -private faq_qanda::fts::url { entry_id } {
    returns a url for a faq to the search package

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    set faq_package_id [db_string package_id {select package_id from acs_objects where object_id = :entry_id} -default {}]

    return "[ad_url][apm_package_url_from_id $faq_package_id]one-question?entry_id=$entry_id"
}


namespace eval faq::sc {}

ad_proc -private faq::sc::register_implementations {} {
    Register the faq content type fts contract
} {
    db_transaction {
        faq::sc::register_faq_fts_impl
        faq::sc::register_faq_q_and_a_fts_impl
    }
}

ad_proc -private faq::sc::unregister_implementations {} {
    db_transaction { 
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name faq
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name faq_q_and_a
    }
}

ad_proc -private faq::sc::register_faq_fts_impl {} {
    set spec {
        name "faq"
        aliases {
            datasource faq::fts::datasource
            url faq::fts::url
        }
        contract_name FtsContentProvider
        owner faq
    }

    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private faq::sc::register_faq_q_and_a_fts_impl {} {
    set spec {
        name "faq_q_and_a"
        aliases {
            datasource faq_qanda::fts::datasource
            url faq_qanda::fts::url
        }
        contract_name FtsContentProvider
        owner faq
    }

    acs_sc::impl::new_from_spec -spec $spec
}
