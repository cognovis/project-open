# /packages/intranet-freelance-invoices/tcl/intranet-freelance-invoices-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to creating Provider Purchase Orders

    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}

ad_proc -private im_package_freelance_invoices_id {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-freelance-invoices'
    } -default 0]
}

