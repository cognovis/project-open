# packages/contacts/lib/email.tcl
# Template for email inclusion
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-14
# @arch-tag: 48fe00a8-a527-4848-b5de-0f76dfb60291
# @cvs-id $Id$

foreach required_param {party_ids recipients} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {return_url} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set message_type "label"
set label_options [callback contact::label -request "ad_form_option"]

ad_form -action message \
    -name label \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons [list [list "[_ intranet-contacts.create_label] [_ intranet-contacts.lt_this_may_take_a_bit]" print]] \
    -export {party_ids return_url title message_type} \
    -form {
	message_id:key
	{recipients:text(inform) {label "[_ intranet-contacts.Contacts_to_Export]"}}
	{label_type:text(select),optional
	    {label "[_ intranet-contacts.Type]"}
	    {options $label_options}
	}
    } -on_request {
    } -on_submit {
    }


if { [template::form::is_valid label] || [llength $label_options] == "1" } {
    if { [llength $label_options] == "1" } {
	# we only have one envelope time to the user has to select it
	set label_type [lindex [lindex $label_options 0] 1]
    }


    # display the progress bar
    
    ad_progress_bar_begin \
	-title [_ intranet-contacts.Generating_PDF] \
	-message_1 [_ intranet-contacts.lt_Generating_the_labels_] \
	-message_2 [_ intranet-contacts.lt_Once_finished_you_get]
    
    set labels [list]
    foreach party_id $party_ids {

	set mailing_address [contact::message::mailing_address -party_id $party_id -format "text/plain" -with_name]
	if {[empty_string_p $mailing_address]} {
	    ad_return_error [_ intranet-contacts.Error] [_ intranet-contacts.lt_there_was_an_error_processing_this_request]
	    break
	}
	
	set mailing_address [openreport::clean_string_for_rml -string ${mailing_address}]
	
	set one "<para style=\"header\">Wieners+Wieners GmbH - Postfach 1803 - 22908 Ahrensburg (bei Hamburg)</para>
<xpre style=\"address\">
${mailing_address}
</xpre>
"
	lappend labels [string trim $one]
    }
    
    set rml "<?xml version=\"1.0\" encoding=\"iso-8859-1\" standalone=\"no\" ?>
<!DOCTYPE document SYSTEM \"rml_1_0.dtd\"><document filename=\"filename.pdf\">"
    append rml [lindex [callback contact::label -request "template" -for $label_type] 0]
    append rml "<story>"
    append rml [join $labels "<nextFrame /><condPageBreak height=\"0in\" />"]
    append rml "</story></document>"
    
    # Gerneate the pdf
    set filename "contacts_labels_[ad_conn user_id]_[dt_systime -format {%Y%m%d-%H%M%S}]_[ad_generate_random_string].pdf"
    set pdf_filename [openreport::trml2pdf -rml $rml -filename $filename]
    set pdf_url "[ad_conn package_url]pdfs/${filename}"
    util_user_message -html -message [_ intranet-contacts.lt_The_pdf_you_requested_-pdf_url-]
    
    if { [exists_and_not_null return_url] } {
	ad_progress_bar_end -url ${return_url}
	ad_script_abort
    } else {
	ad_progress_bar_end -url [ad_conn package_url]
	ad_script_abort
    }
    
}
