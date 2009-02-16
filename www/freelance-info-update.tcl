# /packages/intranet-freelance/www/intranet/users/freelance-info-update.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param user_id
    @author Guillermo Belcic
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}

# ---------------------------------------------------------------
# Default & Security
# ---------------------------------------------------------------

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"
set return_url [im_url_with_query]
set current_user_id [ad_maybe_redirect_for_registration]

im_user_permissions $current_user_id $user_id view read write admin
if {!$admin} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient_2]"
    return
}

# ---------------------------------------------------------------
# Get everything about the freelance
# ---------------------------------------------------------------

# save user_id to be able to select f.*...
set org_user_id $user_id
db_0or1row freelancers_info {
select
    im_name_from_user_id(pe.person_id) as user_name,
    f.*
from 
    persons pe,
    im_freelancers f
where
    pe.person_id = :user_id
    and pe.person_id = f.user_id(+)
}

set user_id $org_user_id


# --------------- Set page design as a function of the freelance data-----

if { ![info exists user_name] || [empty_string_p $user_name]} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_We_couldnt_find_user_]"
    return
}

set page_title "$user_name"
set context_bar [im_context_bar [list /intranet/users/ "[_ intranet-freelance.Users]"] $page_title]

# ---------------------------------------------------------------
# Making body table
# ---------------------------------------------------------------



set recr_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr>
<td colspan=2 class=rowtitle align=center>
  [_ intranet-freelance.lt_Recruiting_Informatio]
</td>
</tr>
<tr>
<td>[_ intranet-freelance.Recruting_Source]</td>
<td><input type=text name=rec_source value=$rec_source></td>
</tr>
<tr>
<td>[_ intranet-freelance.Recruiting_Status]</td>
<td>[im_category_select -include_empty_p 1 -include_empty_name "" "Intranet Recruiting Status" rec_status_id $rec_status_id]</td>
</tr>
<tr>
<td>[_ intranet-freelance.Recruiting_Test_Type]</td>
<td><input type=text name=rec_test_type value=$rec_test_type></td>
</tr>
<tr>
<td>[_ intranet-freelance.lt_Recruiting_Test_Resul]</td>
<td>[im_category_select_plain "Intranet Recruiting Test Result" rec_test_result_id $rec_test_result_id]</td>
</tr>
</table><br>
"


set rates_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>[_ intranet-freelance.Rates_Information]</td></tr>
<tr><td>[_ intranet-freelance.Bank_Account]</td><td><input type=text name=bank_account value=$bank_account></td></tr>
<tr><td>[_ intranet-freelance.Bank]</td><td><input type=text name=bank value=$bank></td></tr>
<tr><td>[_ intranet-freelance.Payment_Method]</td><td>[im_category_select "Intranet Payment Type" "payment_method" "$payment_method_id"]</td></tr>
<tr><td>[_ intranet-freelance.Note]</td><td><textarea type=text cols=50 rows=5 name=note>$note</textarea></td></tr>
"

set ttt_html "
<tr><td>[_ intranet-freelance.Translation_rate]</td><td><input type=text name=translation_rate value=$translation_rate></td></tr>
<tr><td>[_ intranet-freelance.Editing_rate]</td><td><input type=text name=editing_rate value=$editing_rate></td></tr>
<tr><td>[_ intranet-freelance.Hourly_rate]</td><td><input type=text name=hourly_rate value=$hourly_rate></td></tr>
"

# don't show the "private_note" field to the user himself.
# Freelancers and other unprivileged users won't be able to see the 
# user anyway

if { $admin } {
    append rates_html "<tr><td>[_ intranet-freelance.Private_Notes]</td><td><textarea type=text cols=50 rows=5 name=private_note>$private_note</textarea></td></tr>"
}

append rates_html "
</table>
"

set page_body "
<form action=freelance-info-update-2 method=POST>
[export_form_vars user_id]
$recr_html
$rates_html
<center>
<input type=submit name=submit value=Submit>
</center>
</form>
"
ad_return_template
