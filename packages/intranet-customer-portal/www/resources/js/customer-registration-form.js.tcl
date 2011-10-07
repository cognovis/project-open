# /packages/intranet-customer-portal/www/resources/js/wizard/wizard-form.js.tcl
#
# Copyright (C) 2011, ]project-open[
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ad_page_contract {
    Builds ExtJS form for 'Inquire Quoute'

    @param dynview
    @author klaus.hofeditz@project-open.com
} {
    { object_table "" }
}

# ---------------------------------------------------------------
# Security 
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Settings
# ---------------------------------------------------------------

set form_fields_list [list]
set captcha_question "What is two + two? (Please type answer as a number)" 
set captcha_answer "4" 

# ---------------------------------------------------------------
# Build form 
# ---------------------------------------------------------------

        set form_fields_str "
		{fieldLabel: '[_ intranet-core.First_names]',
	               name: 'first_names',
        	       allowBlank:false
		},\n
		{fieldLabel: '[_ intranet-core.Last_name]',
                	name: 'last_name',
	        	allowBlank:false
		},\n
                {fieldLabel: '[_ intranet-core.Email]',
                        name: 'email',
                        id: 'email',
                        allowBlank:false,
                        vtype: 'unique_email',
                },\n
                {fieldLabel: '[_ intranet-core.Phone]',
                        name: 'phone',
                        id: 'phone',
                        allowBlank:true
                },\n
		{fieldLabel: '[_ intranet-core.Company_Name]', 
			name: 'company_name',
			allowBlank:true
		}\n
	"
#                {fieldLabel: 'This helps us to check if you are a human being. Please answer the following question:<br>$captcha_question',
#                        name: 'captcha',
#                        allowBlank:false
#                },\n
#		{fieldLabel: '[_ intranet-core.Password]',
#                	name: 'password',
#	        	allowBlank:false,
#			inputType: 'password',
#			minLength: 6,
#			minLengthText: 'Password must be at least 6 characters long.'
#		},\n
#		{fieldLabel: '[_ intranet-core.lt_Password_Confirmation]',
#	               	name: 'password_confirm',
#        	       	allowBlank:false,
#			inputType: 'password',
#			minLength: 6,
#			minLengthText: 'Password must be at least 6 characters long.',
#			initialPassField: 'password'
#		},\n

# set type to JS
ns_set put [ad_conn outputheaders] "content-type" "application/x-javascript; charset=utf-8"



