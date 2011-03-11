# /tcl/intranet-security-update-client-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Checks for security update messages on a central security
    update server.

    @author frank.bergmann@project-open.com
    @creation-date  January 1st, 2006
}


# ----------------------------------------------------------------------
# Get Exchange Rate from Update Server
# ----------------------------------------------------------------------

ad_proc -public im_security_update_exchange_rate_sweeper { } {
    Checks if exchange rates haven't been updated in a certain time.
} {
    ns_log Notice "im_security_update_exchange_rate_sweeper: Starting"

    # Determine every how many days we want to update
    set max_days_since_update [parameter::get_from_package_key -package_key intranet-exchange-rate -parameter ExchangeRateDaysBeforeUpdate -default 1]

    # Check for the last update
    set last_update_julian ""
    set now_julian ""
    set last_update_sql "
	select	to_char(max(day), 'J') as last_update_julian,
		to_char(now(), 'J') as now_julian
	from	im_exchange_rates
	where	manual_p = 't'
    "
    db_0or1row last_update $last_update_sql

    if {"" == $last_update_julian} { 
	ns_log Error "im_security_update_exchange_rate_sweeper: Didn't find last exchange rate update"
	db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Did not find last exchange rate update. Please perform at least one update manually.')"
	return
    }

    set days_since_update [expr $now_julian - $last_update_julian]
    ns_log Notice "im_security_update_exchange_rate_sweeper: days_since_update=$days_since_update, max_days_since_update=$max_days_since_update"
    if {$days_since_update > $max_days_since_update} {

	set currency_update_url [im_security_update_get_currency_update_url]
	ns_log Notice "im_security_update_exchange_rate_sweeper: "

	if { [catch {
	    set update_xml [ns_httpget $currency_update_url]
	} err_msg] } {
	    ns_log Error "im_security_update_exchange_rate_sweeper: Error retreiving file: $err_msg"
	    db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Error retreiving currency file: [ns_quotehtml $err_msg].')"
	    return
	}

	# Parse the file and update exchange rates
	im_security_update_update_currencies -update_xml $update_xml

	# Write out a log message
	db_string log "select acs_log__debug('im_security_update_exchange_rate_sweeper', 'Successfully updated exchange rates')"

    }
    ns_log Notice "im_security_update_exchange_rate_sweeper: Finished"
}


# ------------------------------------------------------------
# Get the Currency Update file
# ------------------------------------------------------------

ad_proc im_security_update_get_currency_update_url { } {
    Get the URL from which we can retreive an update XML file.
} {
    set currency_update_url [parameter::get_from_package_key -package_key "intranet-exchange-rate" -parameter "ExchangeRateUpdateUrl" -default "http://www.project-open.org/intranet-asus-server/exchange-rates.xml"]

    # Construct the URL
    set system_id [im_system_id]
    set full_url [export_vars -base $currency_update_url {system_id}]

    return $full_url
}

# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
# ------------------------------------------------------------

# Sample record:
#
#<asus_reply>
#<error>ok</error>
#<error_message>Success</error_message>
#<exchange_rate iso="AUD" day="2009-04-05">0.713603</exchange_rate>
#<exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
#<exchange_rate iso="EUR" day="2009-04-05">1.342500</exchange_rate>
#</asus_reply>


ad_proc im_security_update_update_currencies { 
    -update_xml:required
} {
    Parses the XML file and updates the currency entries.
    This process is run both by a page and a background 
    sweeper process.
} {
    set html ""
    set tree [xml_parse -persist $update_xml]
    set root_node [xml_doc_get_first_node $tree]
    set root_name [xml_node_get_name $root_node]
    if {![string equal $root_name "asus_reply"] } {
	append html "Expected &lt;asus_reply&gt; as root node of update.xml file, found: '$root_name'"
	return $html
    }

    set ctr 0
    set debug ""
    set root_nodes [xml_node_get_children $root_node]
    append html "</ul><h2>Login Status</h2><ul>"

    # login_status = "ok" or "fail"
    set login_status [[$root_node selectNodes {//error}] text]
    set login_message [[$root_node selectNodes {//error_message}] text]
    append html "<li>Login Status: $login_status"
    append html "<li>Login Message: $login_message"
    append html "<br>&nbsp;<br>"
    append html "</ul><h2>Processing Data</h2><ul>"

    foreach root_node $root_nodes {
	
	set root_node_name [xml_node_get_name $root_node]
	ns_log Notice "im_security_update_update_currencies: node_name=$root_node_name"
	
	switch $root_node_name {
	    
	    # Information about the successfull/unsuccessful SystemID
	    error {
		# Ignore. Info is extracted via XPath above
	    }
	    error_message {
		# Ignore. Info is extracted via XPath above
	    }
	    exchange_rate {
		# <exchange_rate iso="CAD" day="2009-04-05">0.805626</exchange_rate>
		set currency_code [apm_attribute_value -default "" $root_node iso]
		set currency_day [apm_attribute_value -default "" $root_node day]
		set exchange_rate [xml_node_get_content $root_node]
		append html "<li>exchange_rate($currency_code,$currency_day) = $exchange_rate...\n"
		
		if {![info exists enabled_currencies_hash($currency_code)]} {
		    set fill_hole_currency_hash($currency_code) 1
		}
		
		# Insert values into the Exchange Rates table
		if {"" != $currency_code && "" != $currency_day} {
		    
		    db_dml delete_entry "
				delete  from im_exchange_rates
				where   day = :currency_day::date and
					currency = :currency_code
		    "
		
		    if {[catch {db_dml insert_rates "
				insert into im_exchange_rates (
					day,
					currency,
					rate,
					manual_p
				) values (
					:currency_day::date,
					:currency_code,
					:exchange_rate,
					't'
				)
		    "} err_msg]} {
			append html "Error adding rates to currency '$currency_code':<br><pre>$err_msg</pre>"
		    
			# Add the currency to the list of active currencies
			catch { db_dml insert_code "insert into currency_codes (iso, currency_name) values (:currency_code, :currency_code)" }
		    }
	
		    # The dollar exchange rate is always 1.000, because the dollar
		    # is the reference currency. So we kan update the dollar as "manual"
		    # to avoid messages that dollar is oudated.
		    db_dml update_dollar "
			update	im_exchange_rates
			set	manual_p = 't'
			where	currency = 'USD' and day = :currency_day::date
		    "
		    append html "Success</li>\n"
		}
	    }
	    
	    default {
		ns_log Notice "load-update-xml-2.tcl: ignoring root node '$root_node_name'"
	    }
	}
    }
    
    append html "<li>Freeing document nodes</li>\n"
    xml_doc_free $tree
 
    return $html
}


# ------------------------------------------------------------
#
# ------------------------------------------------------------

ad_proc im_security_update_package_look_up_table { } {
    Returns a look up table (LUT) mapping ]po[ package names
    into a two-letter abbreviation.
    Used to "compress" package names, because the securty-update 
    client can only deal with 2048 characters in the URL.
} {
    # Define a Look-Up-Table for package names.
    # Last code is "fr" for "intranet-trans-invoice-authorization" for ]po[ stuff
    # Last code is "xx" for "xowiki" for OpenACS stuff
    set lut_list {
	acs-admin			aa
	acs-api-browser			ab
	acs-authentication		ac
	acs-automated-testing		ad
	acs-bootstrap-installer		ae
	acs-content-repository		af
	acs-core-docs			ag
	acs-datetime			ah
	acs-developer-support		ai
	acs-events			aj
	acs-kernel			ak
	acs-lang			al
	acs-mail			am
	acs-mail-lite			an
	acs-messaging			ao
	acs-reference			ap
	acs-service-contract		aq
	acs-subsite			ar
	acs-tcl				as
	acs-templating			at
	acs-translations		au
	acs-workflow			av
	ajaxhelper			ba
	ams				bb
	attachments			fc
	auth-ldap			bc
	auth-ldap-adldapsearch		bd
	auth-ldap-openldap		fb
	batch-importer			be
	bug-tracker			bf
	bulk-mail			bg
	calendar			bh
	categories			bi
	chat				bj
	cms				bk
	contacts			bl
	diagram				bm
	ecommerce			bn
	events				bo
	faq				bq
	file-storage			fd
	general-comments		br
	intranet-amberjack		ca
	intranet-asus-server		fe
	intranet-audit			cb
	intranet-baseline		ff
	intranet-big-brother		cc
	intranet-bug-tracker		cd
	intranet-calendar		ce
	intranet-calendar-holidays	cf
	intranet-confdb			cg
	intranet-contacts		ch
	intranet-core			ci
	intranet-cost			cj
	intranet-cost-center		ck
	intranet-crm-tracking		cl
	intranet-cust-baselkb		cm
	intranet-cust-cambridge		cn
	intranet-cust-issa		co
	intranet-cust-lexcelera		cp
	intranet-cust-projop		cq
	intranet-cust-reinisch		cr
	intranet-cust-versia		fg	
	intranet-cvs-integration	cs
	intranet-dw-light		ct
	intranet-dynfield		cu
	intranet-exchange-rate		cv
	intranet-expenses		cw
	intranet-expenses-workflow	cx
	intranet-filestorage		cy
	intranet-forum			cz
	intranet-freelance		da
	intranet-freelance-invoices	db
	intranet-freelance-rfqs		dc
	intranet-freelance-translation	dd
	intranet-funambol		fh
	intranet-ganttproject		de
	intranet-gtd-dashboard		fi
	intranet-helpdesk		df
	intranet-hr			dg
	intranet-invoices		dh
	intranet-invoices-templates	di
	intranet-mail-import		dj
	intranet-material		dk
	intranet-milestone		dl
	intranet-nagios			dm
	intranet-notes			dn
	intranet-notes-tutorial		do
	intranet-ophelia		dp
	intranet-otp			dq
	intranet-payments		dr
	intranet-pdf-htmldoc		ds
	intranet-planning		fj
	intranet-portfolio-management	fk
	intranet-release-mgmt		dt
	intranet-reporting		du
	intranet-reporting-cubes	dv
	intranet-reporting-dashboard	dw
	intranet-reporting-finance	dx
	intranet-reporting-indicators	dy
	intranet-reporting-translation	dz
	intranet-reporting-tutorial	ea
	intranet-resource-management	fl
	intranet-rest			fm
	intranet-riskmanagement		eb
	intranet-rss-reader		fn
	intranet-scrum			fo
	intranet-search-pg		ec
	intranet-search-pg-files	ed
	intranet-security-update-client	ee
	intranet-security-update-server	ef
	intranet-sharepoint		fp
	intranet-simple-survey		eg
	intranet-sla-management		fq
	intranet-soap-lite-server	eh
	intranet-spam			ei
	intranet-sql-selectors		ej
	intranet-sysconfig		ek
	intranet-timesheet2		el
	intranet-timesheet2-invoices	em
	intranet-timesheet2-task-popup	en
	intranet-timesheet2-tasks	eo
	intranet-timesheet2-workflow	ep
	intranet-tinytm			eq
	intranet-trans-invoice-authorization	fr
	intranet-trans-invoices		er
	intranet-trans-project-wizard	et
	intranet-trans-quality		eu
	intranet-translation		es
	intranet-ubl			ev
	intranet-update-client		ew
	intranet-update-server		ex
	intranet-wiki			ey
	intranet-workflow		ez
	intranet-xmlrpc			fa
	lars-blogger			xa
	mail-tracking			xb
	notifications			xc
	oacs-dav			xu
	openacs-default-theme		xv
	organizations			xd
	oryx-ts-extensions		xe
	postal-address			xf
	ref-countries			xg
	ref-language			xh
	ref-timezones			xi
	ref-us-counties			xj
	ref-us-states			xk
	ref-us-zipcodes			xl
	rss-support			xm
	search				xn
	simple-survey			xo
	telecom-number			xp
	trackback			xq
	wiki				xr
	workflow			xs
	xml-rpc				xt
	xotcl-core			xw
	xowiki				xx
    }
    return $lut_list
}


ad_proc im_security_update_asus_status { 
    { -no_return_value_p 0}
} {
    Returns the status of the ASUS configuration (1=verbose, 0=anonymous)
    OR redirects to the ASUS Terms & Conditions page
    if the ASUS was not configured.
} {
    set return_url [ad_conn url]
    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_verbosity [parameter::get -package_id $package_id -parameter "SecurityUpdateVerboseP" -default "0"]

    # -1 means that the user needs to confirm using the UpdateService
    if {-1 == $sec_verbosity} {
	ad_returnredirect [export_vars -base "/intranet-security-update-client/user-agreement" {return_url}]
    }
    
    # No return value for use as a component when just checking if the ASUS is configured
    if {$no_return_value_p} { return "" }

    return $sec_verbosity
}



ad_proc im_exchange_rate_update_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set return_url [ad_conn url]
    set sec_verbosity [im_security_update_asus_status]
    if {0 == $sec_verbosity} {

	set content "
	[lang::message::lookup "" intranet-exchange-rate.Exchange_ASUS_Disabled "
		<p>
		You have chosen to disabled 'Full ASUS'. 
		</p><p>
		However, Automatic Exchange Rate update 
		requires 'Full ASUS' in order to automatically update exchange rates.
		</p>
	"]
	<form action='/intranet-security-update-client/user-agreement'>
	[export_form_vars return_url]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Enable_Full_ASUS "Update ASUS"]'>
	</form>
	"

    } else {

	set content "
	[lang::message::lookup "" intranet-exchange-rate.Exchange_ASUS_Disclaimer "
		<p>
		This service allows you to automatically update your
		exchange rates from our exchange rate server.<br>
		By using this service you accept that we provide this 
		service 'as is' and don't accept any liability for 
		incorrect data and any consequences of using them.
		</p>
	"]
	<form action='/intranet-security-update-client/get-exchange-rates'>
	[export_form_vars return_url]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Button_Get_Exchange_Rates_Now "Get Exchange Rates Now"]'>
	</form>
        "

	set return_url [im_url_with_query]
	set package_key "intranet-security-update-client"
	set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
	set enabled_p [parameter::get_from_package_key -package_key intranet-security-update-client -parameter ExchangeRateSweeperEnabledP -default 0]
	set days_before_update [parameter::get_from_package_key -package_key intranet-exchange-rate -parameter ExchangeRateDaysBeforeUpdate -default 0]
	set last_update [db_string last_update "select max(day::date) from im_exchange_rates where manual_p = 't'" -default "never"]
	# append content "<br>\n"
	append content "<h2>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Status "Automatic Update Status"]</h2>\n"
	append content "
		<table>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Last_Update "Last Update:"]</td>
			<td>$last_update</td>
		</tr>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Enabled_p "Automatic Update Enabled?"]</td>
			<td>$enabled_p</td>
		</tr>
		<tr>	<td>[lang::message::lookup "" intranet-exchange-rate.Automatic_Updates_Days "Automatic Update Every N Days:"]</td>
			<td>$days_before_update</td>
		</tr>
		</table>
	<form action='/shared/parameters' method=GET>
	[export_form_vars return_url package_id]
	<input type=submit value='[lang::message::lookup "" intranet-exchange-rate.Edit_Parameters "Edit Parameters"]'>
	</form>
	"

	append content "<h2>[lang::message::lookup "" intranet-exchange-rate.Automatic_Update_History "Automatic Update History"]</h2>\n"
	append content "<ul>\n"
	set log_sql "
		select	*,
			to_char(log_date, 'YYYY-MM-DD HH24:MI') as log_date_pretty
		from	acs_logs
		where	log_key = 'im_security_update_exchange_rate_sweeper'
		order by log_date DESC
		LIMIT 10
	"
	db_foreach last_logs $log_sql {
	    append content "<li>$log_date_pretty: $message</li>\n"
	}
	append content "</ul>"
    }

    return $content
}



ad_proc im_security_update_client_component { } {
    Shows a a component mainly consisting of an IFRAME.
    Passes on the version numbers of all installed packages
    in order to be able to retreive relevant messages
} {
    set current_user_id [ad_maybe_redirect_for_registration]
    set action_url "/intranet-security-update-client/update-preferences"
    set return_url [ad_conn url]

    set package_key "intranet-security-update-client"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set sec_url_base [parameter::get -package_id $package_id -parameter "SecurityUpdateServerUrl" -default "http://www.project-open.org/intranet-asus-server/update-information"]

    # Verbose ASUS configuration?
    # May redirect to user-agreement to confirm ASUS terms & conditions
    set sec_verbosity [im_security_update_asus_status]

    global tcl_platform
    set os_platform [lindex $tcl_platform(os) 0]
    set os_version [lindex $tcl_platform(osVersion) 0]
    set os_machine [lindex $tcl_platform(machine) 0]

    # Add the list of package versions to the URL in order to get 
    # the right messages

    # Define a look up table LUT mapping package names into abbreviations.
    array set lut_hash [im_security_update_package_look_up_table]

    # Go through the list of all packages and add to the URL
    set package_sql "
	select	v.package_key,
	        v.version_name
	from	(	select	max(version_id) as version_id,
				package_key
			from	apm_package_versions
		        group by package_key
	        ) m,
	        apm_package_versions v
	where	m.version_id = v.version_id
    "

    set sec_url "$sec_url_base?"
    db_foreach package_versions $package_sql {

	# copress package name if available in LUT
	if {[info exists lut_hash($package_key)]} { set package_key $lut_hash($package_key) }

	# Check if the version number has the format like: "3.4.0.7.0"
	# In this case we can savely remove the dots between the digits.
	if {[regexp {^[0-9]\.[0-9]\.[0-9]\.[0-9]\.[0-9]$} $version_name match]} {
	    regsub -all {\.} $version_name "" version_name
   	}

	# shorten the "intranet-" and "acs-" prefix from packages to save space
	if {[regexp {^intranet\-(.*)} $package_key match key]} { set package_key "i-$key"}
	if {[regexp {^acs\-(.*)} $package_key match key]} { set package_key "a-$key"}

	append sec_url "p.[string trim $package_key]=[string trim $version_name]&"
    }

    if {0 != $sec_verbosity} {
	append sec_url "email=[string trim [db_string email "select im_email_from_user_id(:current_user_id)"]]&"

	set compname [db_string compname "select company_name from im_companies where company_path='internal'" -default "Tigerpond"]
	append sec_url "compname=[ns_urlencode [string trim $compname]]&"

	# Get the name of the server from the URL pointing to this page.
	set header_vars [ns_conn headers]
	set host [ns_set get $header_vars "Host"]
	append sec_url "host=[ns_urlencode [string trim $host]]&"
    }

    # Get the number of active users for the three most important groups
    foreach g [list "employees" "customers" "freelancers"] {
	set count [db_string emp_count "
		select	count(*)
		from	cc_users u, 
			acs_rels r, 
			membership_rels m, 
			groups g 
		where	lower(group_name) = :g and 
			r.object_id_two = u.user_id and 
			r.object_id_one = g.group_id and 
			u.member_state = 'approved' 
			and r.rel_id = m.rel_id and 
			m.member_state = 'approved'
	"]
	set abbrev [string range $g 0 2]
	append sec_url "g.$abbrev=$count&"
    }

    append sec_url "os_platform=[string trim $os_platform]&"
    append sec_url "os_version=[string trim $os_version]&"
    append sec_url "os_machine=[string trim $os_machine]&"
    append sec_url "pg_version=[string trim [im_database_version]]&"   
    append sec_url "sid=[im_system_id]&"
    append sec_url "hid=[im_hardware_id]"

    set security_update_l10n [lang::message::lookup "" intranet-security-update-client.Security_Updates "ASUS Security Updates"]
    set no_iframes_l10n [lang::message::lookup "" intranet-security-update-client.Your_browser_cant_display_iframes "Your browser can't display IFrames. Please click for here for <a href=\"$sec_url_base\">security update messages</a>."]

    set anonymous_selected ""
    set verbose_selected ""
    if {0 == $sec_verbosity} {
	set anonymous_selected "checked"
    } else {
	set verbose_selected "checked"
    }

    # Check for upgrades to run
    set upgrade_message "You are running &#93project-open&#91; version: [im_core_version]<br><br>"
    set script_list [im_check_for_update_scripts]
    append upgrade_message $script_list
    if {"" != $script_list} { append upgrade_message "<br>&nbsp;<br>\n" }

    set sec_html "
	$upgrade_message
	<iframe src=\"$sec_url\" width=\"90%\" height=\"200\" name=\"$security_update_l10n\">
	  <p>$no_iframes_l10n</p>
	</iframe>
	<form action=\"$action_url\" method=POST>
	    <input type=\"radio\" name=\"verbosity\" value=\"1\" $verbose_selected>Detailed
	    [im_gif help "Choose this option for detailed security information. With this option the security update service transmits information about your configuration that might help us to assess your &#93project-open&#91; system configuration including package versions and operating system version information. It also includes your email address so that we can alert your in special situations."]
	    <input type=\"radio\" name=\"verbosity\" value=\"0\" $anonymous_selected>Anonymous
	    [im_gif help "Choose this option if you prefer not to reveal any information to &#93project-open&#91; that might identify you or your organization."]
	    <input type=\"hidden\" name=\"return_url\" value=\"$return_url\">
	    <input type=\"submit\" name=\"submit\" value=\"OK\">
	</form>
    "

    return $sec_html
}
