/**
 * intranet-sencha-ticket-tracker/www/Models.js
 * Models for the Sencha ]project-open[ Interface
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: Models.js.adp,v 1.8 2011/06/10 14:24:05 po34demo Exp $
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
        {type: 'int', name: 'category_id'},
        {type: 'string', name: 'tree_sortkey'},
        {type: 'string', name: 'category'},
        {type: 'string', name: 'category_translated'},
        {	name: 'pretty_name',
		convert: function(value, record) {
			var	category = record.get('category_translated'),
				indent = record.get('tree_sortkey').length - 8,
				result = '',
				i=0;
			for (i=0; i<indent; i++){
				result = result + '&nbsp;';
			}
			result = result + category;
			return result;
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
	'ticket_service_id',
	'ticket_hardware_id',
	'ticket_application_id',
	'ticket_queue_id',		// Assignee queue (currently not used)
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
	'ticket_confirmation_date',		// 
	'ticket_done_date',		// 
	'ticket_signoff_date',		// 

        'service_type',                 // tipo de Servicio
        'intranet_request_area',        // Area y programa

        'ticket_file',                  // expediente
        'ticket_origin',                // canal
        'ticket_sex',                   // genero hombre/mujer
        'ticket_language',              // idioma
        'ticket_province',              // Provincia

        'ticket_answer',                // Respuesta
        'ticket_observations',           // Observaciones

	'replycount'			// Number of ticket replies - not supported at the moment
    ]
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
			format: 'json',		// Tell the ]po[ REST to return JSON data.
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
	'first_names',
	'last_name',
	{ name: 'name',			// Calculated compound name
	  convert: function(value, record) {
		return record.get('first_names') + ' ' + record.get('last_name');
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

