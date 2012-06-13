ad_library {
    Calendar service contract bindings

    @creation-date 2004-04-01
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id$
}

namespace eval calendar::fts {}

ad_proc -private calendar::fts::datasource { cal_item_id } {
    returns a datasource for a calendar event to 
    be indexed by the full text search engine.

    @param cal_item_id

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    calendar::item::get -cal_item_id $cal_item_id -array row

    # build a text content 
    foreach key {description pretty_day_of_week start_time end_time full_start_date start_date_ansi} {
        if {[string eq $key start_time]} { 
            append content "from "
        }
        if {[string eq $key end_time]} { 
            append content "to "
        }
        append content "$row($key) "

    }

    return [list object_id $cal_item_id \
                title $row(name) \
                content $content \
                keywords {} \
                storage_type text \
                mime text/plain ]
}

ad_proc -private calendar::fts::url { cal_item_id } {
    returns a url for an event to the search package

    @author davis@xarg.net
    @creation_date 2004-04-01
} {
    calendar::item::get -cal_item_id $cal_item_id -array row
    return "[ad_url][apm_package_url_from_id $row(calendar_package_id)]cal-item-view?cal_item_id=$cal_item_id"
}

namespace eval calendar::sc {}

ad_proc -private calendar::sc::register_implementations {} {
    Register the cal_item content type fts contract
} {
    db_transaction {
        calendar::sc::register_cal_item_fts_impl
        calendar::sc::register_acs_event_fts_impl
    }
}

ad_proc -private calendar::sc::unregister_implementations {} {
    db_transaction { 
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name cal_item
        acs_sc::impl::delete -contract_name FtsContentProvider -impl_name acs_event
    }
}

ad_proc -private calendar::sc::register_cal_item_fts_impl {} {
    set spec {
        name "cal_item"
        aliases {
            datasource calendar::fts::datasource
            url calendar::fts::url
        }
        contract_name FtsContentProvider
        owner calendar
    }

    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private calendar::sc::register_acs_event_fts_impl {} {
   set spec {
      name "acs_event"
      aliases {
         datasource calendar::fts::datasource
         url calendar::fts::url
      }
      contract_name FtsContentProvider
      owner calendar
   }

   acs_sc::impl::new_from_spec -spec $spec
}
