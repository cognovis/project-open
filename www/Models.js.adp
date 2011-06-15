/**
 * intranet-sencha-ticket-tracker/www/Models.js
 * Models for the Sencha ]project-open[ Interface
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id$
 *
 * Copyright (C) 2011, ]project-open[
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Use TCL template language to get the current user_id
var currentUserId = <%= [ad_get_user_id] %>;

Ext.define('TicketBrowser.Sla', {
    extend: 'Ext.data.Model',
    idProperty: 'project_id',		// The primary key of object_id of the SLA project
    fields: [
	'project_id',			// The primary key of object_id of the SLA project
	'project_name',			// The name of the SLA
	{ name: 'leaf', convert: function(value, record) { return true; } }
    ]
});



Ext.define('TicketBrowser.Profile', {
    extend: 'Ext.data.Model',
    idProperty: 'group_id',		// The primary key. A Queue is a subtype of "group".
    fields: [
	'group_id',			// The primary key
	'group_name',			// The name of the queue
    ]
});




// A "category" is a kind of constant frequently used for states and types
Ext.define('TicketBrowser.Category', {
    extend: 'Ext.data.Model',
    idProperty: 'category_id',		// The primary key of the category
    fields: [
        {type: 'string', name: 'category_id'},
        {type: 'string', name: 'tree_sortkey'},
        {type: 'string', name: 'category'},
        {type: 'string', name: 'category_translated'},
        {type: 'string', name: 'indent_class',
		// Determine the indentation level for each element in the tree
		convert: function(value, record) {
			var	category = record.get('category_translated');
			var	indent = (record.get('tree_sortkey').length / 8) - 1;
			return 'extjs-indent-level-' + indent;
		}
	}
    ]
});



Ext.define('TicketBrowser.Ticket', {
    extend: 'Ext.data.Model',

    idProperty: 'ticket_id',		// The primary key or object_id of the ticket
    fields: [
	// Basic ticket fields with special meaning
	'ticket_id',			// The primary key or object_id of the ticket
	'project_name',			// The name of the ticket. Ticket is as sub-type of Project, 
					// so the ticket name is stored as project_name.
	'parent_id',			// The parent_id of the ticket is the Service Level Agreement (SLA)
					// project that handles the financials of the ticket.
	'company_id',			// Company for whom the ticket has been created
	'creation_user',		// User_id of the guy creating the ticket
	'ticket_status_id',		// Lifecycle control: Current Status
	'ticket_type_id',		// Type of ticket: Controls presence/absence of DynFields
	'ticket_customer_contact_id',	// For whom do we work?

	'fs_folder_id',			// File-storage folder for this ticket

	// Main ticket fields
	'ticket_prio_id',		// Priority
	'ticket_assignee_id',		// Who is assigned to the work?
	'ticket_dept_id',		// Which department?
	'ticket_service_type_id',
	'ticket_hardware_id',
	'ticket_application_id',
	'ticket_queue_id',		// Assignee queue (currently not used)
	'ticket_last_queue_id',		// Last queue before escalation
	'ticket_conf_item_id',
	'ticket_component_id',
	'ticket_description',		// Initial description of the ticket
	'ticket_resolution_time',	// 
	'ticket_closed_in_1st_contact_p',

	// Alarm mechanism - not supported yet
	'ticket_alarm_date',
	'ticket_alarm_action',

	// Ticket lifecycle tracking	
	'ticket_creation_date',		// 
	'ticket_reaction_date',		// 
	'ticket_confirmation_date',	// 
	'ticket_escalation_date',	// 
	'ticket_resolution_date',	// 
	'ticket_done_date',		// 
	'ticket_signoff_date',		//

	'ticket_requires_addition_info_p',
	'ticket_incoming_channel_id',	// actually ticket_origin
	'ticket_outgoing_channel_id',

        'ticket_area_id',		// Area y programa

        'ticket_file',                  // expediente
        'ticket_request',               // expediente
        'ticket_resolution',            // expediente

        'ticket_origin',                // canal
        'ticket_sex',                   // genero hombre/mujer
        'ticket_language',              // idioma
        'ticket_province',              // Provincia

        'ticket_answer',                // Respuesta
        'ticket_observations',           // Observaciones

	'replycount'			// Number of ticket replies - not supported at the moment
    ],

	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_ticket',
		extraParams: {
			format: 'json',		// Tell the ]po[ REST to return JSON data.
			format_variant: 'sencha'	// Tell the ]po[ REST to return all columns
		},
		reader: {
			type: 'json',		// Tell the Proxy Reader to parse JSON
			root: 'data',		// Where do the data start in the JSON file?
			totalProperty: 'total'
		},
		writer: {
			type: 'json'
		}
	}

});


Ext.define('TicketBrowser.Company', {
    extend: 'Ext.data.Model',

    idProperty: 'company_id',		// The primary key or object_id of the company
    fields: [
	// Basic company fields with special meaning
	'company_id',			// The primary key or object_id of the company
	'company_name',			// The name of the company. Company is as sub-type of Project, 
					// so the company name is stored as project_name.
	'company_path',			// Short name and path to the company's filestorage
	'main_office_id',		// The company's main office
					// project that handles the financials of the company.
	'company_status_id',		// Lifecycle control: Current Status
	'company_type_id',		// Type of company: Controls presence/absence of DynFields
	'primary_contact_id',		// Main customer contact
	'accounting_contact_id',	// Customer contact for accounting purposes
	'note',				// Free text note for company, full-text indexed
	'referral_source',		// How have we heard about the company first?
	'annual_revenue_id',		// How much turnover do we have with company?
	'vat_number',			// Company's VAT ID
	'company_group_id',		// Does the company belong to a group structure?
	'business_sector_id',		// Business sector of the company

	'company_province'		// Custom field "province"
    ],

	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_company',
		extraParams: {
			format: 'json'		// Tell the ]po[ REST to return JSON data.
		},
		reader: {
			type: 'json',		// Tell the Proxy Reader to parse JSON
			root: 'data',		// Where do the data start in the JSON file?
			totalProperty: 'total'
		},
		writer: {
			type: 'json'
		}
	}

});


Ext.define('TicketBrowser.User', {
    extend: 'Ext.data.Model',

    idProperty: 'user_id',		// The primary key or object_id of the company
    fields: [
	'user_id',			// Primary key
	'first_names',			// First name(s)
	'last_name',			// Standard last name
	'last_name2',			// Spanish 2nd last name
	'email',			// Just email txt
	'gender',			// male or female
	'language',			// es_ES or eu_ES
	{ name: 'name',			// Calculated compound name
	  convert: function(value, record) {
		return record.get('first_names') + ' ' + record.get('last_name') + ' ' + record.get('last_name2');
	  }
	}
    ],
    proxy: {
	type: 'rest',
	url: '/intranet-rest/user',
	appendId: true,
	extraParams: {
	    format: 'json',
	    format_variant: 'sencha'
	},
	reader: { 
	    type: 'json', 
	    root: 'data',
	    totalProperty: 'total'
	},
	writer: {
	    type: 'json'
	}
    }
});



Ext.define('TicketBrowser.ObjectMember', {
    extend: 'Ext.data.Model',

    idProperty: 'rel_id',			// The primary key or object_id of the company
    fields: [
	'rel_id',				// Primary key
	'rel_type',				// Type of relationship (membership_rel, im_key_account_rel, ...)
	'object_id_one',			// Business Object (company, project, ...)
	'object_id_two',			// User who is a member
	'object_role_id',			// The "role" in which the user is part of the biz object,
						// i.w. Project Manager, Key Account, Full Member etc.
	'percentage'				// Membership percentage (only membership roles)
    ],
    proxy: {
	type: 'rest',
	url: '/intranet-sencha-ticket-tracker/object-member-datasource',
	appendId: true,
	extraParams: {
		// object_id_one: <business object>
		// object_id_two: <user>
	},
	reader: { 
	    type: 'json', 
	    root: 'data',
	    totalProperty: 'total'
	}
    }
});






Ext.define('TicketBrowser.FileStorage', {
    extend: 'Ext.data.Model',

    idProperty: 'item_id',		// The primary key or object_id of the filestorage
    fields: [
	// Basic filestorage fields with special meaning
	'item_id',			// The primary key or object_id of the filestorage
	'name',				// The name of the file.
	'parent_id',			// The ID of the content folder that contains the file
	'mime_type',			// MIME type of the file, i.e. "image/jpeg", ...
	'description',			// Manual description of the file
	'creation_date',		// Date of creation
	'creation_user',		// The user who created the file
	'last_modified',		// Date of last modification
	'content_length'		// size of the file
    ]
});



Ext.define('TicketBrowser.TicketAudit', {
    extend: 'Ext.data.Model',

    idProperty: 'audit_id',		// The primary key or object_id of the filestorage
    fields: [
	'audit_id',			// The primary key or object_id of the filestorage
	'audit_object_id',		// The name of the file.
	'audit_action',			// The ID of the content folder that contains the file
	'audit_user_id',		// MIME type of the file, i.e. "image/jpeg", ...
	'audit_date',			// Manual description of the file
	'audit_ip',			// Date of creation
	'audit_object_status_id',	// The user who created the file

	// Fields from im_company
	'company_id',
	'company_project_nr',
	'confirm_date',
	'corporate_sponsor',
	'cost_bills_cache',
	'cost_cache_dirty',
	'cost_delivery_notes_cache',
	'cost_expense_logged_cache',
	'cost_expense_planned_cache',
	'cost_invoices_cache',
	'cost_purchase_orders_cache',
	'cost_quotes_cache',
	'cost_timesheet_logged_cache',
	'cost_timesheet_planned_cache',
	'description',
	'end_date',
	'milestone_p',
	'note',
	'on_track_status_id',
	'parent_id',
	'percent_completed',
	'presales_probability',
	'presales_value',
	'program_id',
	'project_budget',
	'project_budget_currency',
	'project_budget_hours',
	'project_id',
	'project_lead_id',
	'project_name',
	'project_nr',
	'project_path',
	'project_priority_id',
	'project_risk',
	'project_status_id',
	'project_type_id',
	'reported_days_cache',
	'reported_hours_cache',
	'sla_ticket_priority_map',
	'sort_order',
	'start_date',
	'subject_area_id',
	'supervisor_id',

        'ticket_file',                  // expediente
        'ticket_request',               // expediente
        'ticket_resolution',            // expediente

	// fields from im_ticket
	'ticket_alarm_action',
	'ticket_alarm_date',
	'ticket_application_id',
	'ticket_assignee_id',
	'ticket_closed_in_1st_contact_p',
	'ticket_component_id',
	'ticket_conf_item_id',
	'ticket_confirmation_date',
	'ticket_creation_date',
	'ticket_customer_contact_id',
	'ticket_customer_deadline',
	'ticket_dept_id',
	'ticket_description',
	'ticket_done_date',
	'ticket_hardware_id',
	'ticket_id',
	'ticket_note',
	'ticket_prio_id',
	'ticket_queue_id',
	'ticket_quote_comment',
	'ticket_quoted_days',
	'ticket_reaction_date',
	'ticket_resolution_time',
	'ticket_resolution_time_dirty',
	'ticket_service_id',
	'ticket_signoff_date',
	'ticket_sla_id',
	'ticket_status_id',
	'ticket_telephony_new_number',
	'ticket_telephony_old_number',
	'ticket_telephony_request_type_id',
	'ticket_type_id'
    ]
});


