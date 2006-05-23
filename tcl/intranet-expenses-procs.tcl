# /packages/intranet-expenses/tcl/intranet-expenses-procs.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures to implement travel expenses
    @author frank.bergmann@project-open.com
}



ad_proc -public im_expense_payment_type_cash {} { return 4100 }
ad_proc -public im_expense_payment_type_visa1 {} { return 4101 }
ad_proc -public im_expense_payment_type_paypal {} { return 4102 }

# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_package_expenses_id {} {
    Returns the package id of the intranet-expenses module
} {
    return [util_memoize "im_package_expenses_id_helper"]
}

ad_proc -private im_package_expenses_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-expenses'
    } -default 0]
}


ad_proc -public im_cost_type_expense_item {} { return 3720 }
ad_proc -public im_cost_type_expense_report {} { return 3722 }


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------


