# /packages/intranet-payments/tcl/intranet-payment-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Invoices

    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}

ad_proc im_payment_type_select { select_name { default "" } } {
} {
    return [im_category_select "Intranet Payment Type" $select_name $default]
}

