# /packages/intranet-mail-import/www/get-mail-list.tcl
#
# Copyright (C) 2003 - 2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {

    @author klaus.hofeditz@project-open.com
    @creation-date July 2010
} {
    { callback "" }
}

#-- -------------------------
#   Defaults and Security 
#-- -------------------------

set user_id [ad_maybe_redirect_for_registration]

set view_mails_all_p [im_permission $user_id view_mails_all]
if { [im_is_user_site_wide_or_intranet_admin $user_id] } { set view_mails_all_p 1 }

#-- -------------------------
#   Label l10n 
#-- -------------------------

set search_title  [lang::message::lookup "" intranet-mail-import.Title_Search "Bulk Assignment"]
set title_defered_mails  [lang::message::lookup "" intranet-mail-import.Title_Defered_Mails "Defered mails"]
set message_name [lang::message::lookup "" intranet-mail-import.Message_Name "Name"]
set from [lang::message::lookup "" intranet-mail-import.From "From"]
set to [lang::message::lookup "" intranet-mail-import.To "To"]
set subject_header [lang::message::lookup "" intranet-mail-import.Mail_Subject "Subject"]
set date_email [lang::message::lookup "" intranet-mail-import.Mail_Date "Date"]
set hint_search [lang::message::lookup "" intranet-mail-import.Hint_Type_And_Find "Search for object to assign check items to (minimum 4 chars.):"]
set hint_checkbox [lang::message::lookup "" intranet-mail-import.Hint_Type_And_Find "I intent to make assignments to more than one object, do not remove mail from box."]
set delete_button [lang::message::lookup "" intranet-mail-import.Delete_Button "Delete"]
set delete_button_tooltip [lang::message::lookup "" intranet-mail-import.Delete_Button_Tooltip "Delete checked mails"]
set close_button [lang::message::lookup "" intranet-mail-import.Close_Button "Close"]

#-- -------------------------
#   Load ExtJS grey theme 
#-- -------------------------

template::head::add_css -href "/intranet-sencha/css/ext-all-grey.css" -media "screen" -order 9999

