# /packages/intranet-reporting-openoffice/www/report-list.tcl
#
# Copyright (c) 1998-2012 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@ticket-open.com
} {
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# ---------------------------------------------------------------
# Title
# ---------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-reporting-openoffice.Report_List "Report List"]
set context_bar [im_context_bar $page_title]


