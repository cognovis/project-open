ad_page_contract {

    Selection page to enter a new contact base data.

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-03-28
    @cvs-id $Id$
} {
    person_id:optional
    {form_mode "edit" }
    {return_url ""}
}

# --------------------------------------------------
# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

set title "[_ intranet-contacts.Add_a_Biz_Card]"
set context [list $title]
set current_user_id [ad_maybe_redirect_for_registration]


# --------------------------------------------------
# Environment information for the rest of the page

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]
set required_field "<font color=red size=+1><B>*</B></font>"


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set contact_options [list \
			 [list [lang::message::lookup "" intranet-core.Customer "Customer"] customer] \
			 [list [lang::message::lookup "" intranet-core.Provider "Provider"] provider] \
			 [list [lang::message::lookup "" intranet-core.Provider "Undefined"] undefined] \
			]

set form_id "contact"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action "biz-card-add-2" \
    -method GET \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {contact_type:text(select),optional {label "[lang::message::lookup {} intranet-core.Contact_Type {Contact Type}]"} {options $contact_options}}
	{first_names:text(text),optional {label "[_ intranet-core.First_names]"} {html {size 30}}}
	{last_name:text(text),optional {label "[_ intranet-core.Last_name]"} {html {size 30}}}
    	{email:text(text),optional {label "[_ intranet-core.Email]"} {html {size 30}} {help_text ""}}
	{company_name:text(text),optional {label "[lang::message::lookup {} intranet-core.Company_name {Company Name}]"} {html {size 30}}}
    }


ad_form -extend -name $form_id -new_request {

    # Nada. No actin necessary (so far?)
}
