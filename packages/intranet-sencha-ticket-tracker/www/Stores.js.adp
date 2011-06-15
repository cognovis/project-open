/**
 * intranet-sencha-ticket-tracker/www/Stores.js
 * Data stores.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
<<<<<<< HEAD
 * @cvs-id $Id: Stores.js.adp,v 1.20 2011/06/14 18:30:17 po34demo Exp $
=======
 * @cvs-id $Id: Stores.js.adp,v 1.14 2011/06/10 14:24:05 po34demo Exp $
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
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


/*
 * Create a specific store for categories.
 * The subclass contains a special lookup function.
 */
Ext.ux.CategoryStore = Ext.extend(Ext.data.Store, {
	category_from_id: function(category_id) {
<<<<<<< HEAD
		if (null == category_id || '' == category_id) { return ''; }
		var	result = 'Category #' + category_id;
		var	rec = this.findRecord('category_id',category_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('category_translated'); 
=======
		var	result = 'Category #' + category_id;
		var	rec = this.findRecord('category_id',category_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('category'); 
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	}
});

/*
 * Create a specific store for users of all type.
 * The subclass contains a special lookup function.
 */
Ext.ux.UserStore = Ext.extend(Ext.data.Store, {
	name_from_id: function(user_id) {
		var	result = 'User #' + user_id;
		var	rec = this.findRecord('user_id',user_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('name');
	}
});

/*
 * Create a specific store for users of all type.
 * The subclass contains a special lookup function.
 */
Ext.ux.CompanyStore = Ext.extend(Ext.data.Store, {
	name_from_id: function(company_id) {
<<<<<<< HEAD
		var result = 'Company #' + company_id;
		var rec = this.findRecord('company_id',company_id);
=======
		var	result = 'Company #' + company_id;
		var	rec = this.findRecord('company_id',company_id);
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('company_name');
	},

	vat_id_from_id: function(company_id) {
<<<<<<< HEAD
		var rec = this.findRecord('company_id',company_id);
=======
		var	rec = this.findRecord('company_id',company_id);
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
		if (rec == null || typeof rec == "undefined") { return ''; }
		return rec.get('vat_number');
	}

});


<<<<<<< HEAD

var ticketAreaStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'ticketAreaStore',
	autoLoad:	true,
	remoteFilter:	true,
	model:		'TicketBrowser.Category',	// Causes the Drop-Down not to load
	// fields: ['category_id', 'category', 'category_translated'],
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Sencha Ticket Tracker Area\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var ticketTypeStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'ticketTypeStore',
	remoteFilter:	true,
	autoLoad:	true,
=======
var ticketTypeStore = Ext.create('Ext.ux.CategoryStore', {
	storeId: 'ticketTypeStore',
	autoLoad: true,
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Ticket Type\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var ticketStatusStore = Ext.create('Ext.ux.CategoryStore', {
<<<<<<< HEAD
	storeId:	'ticketStatusStore',
	autoLoad:	true,
	remoteFilter:	true,
=======
	storeId: 'ticketStatusStore',
	autoLoad: true,
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Ticket Status\''
		},
		reader: { type: 'json', root: 'data' }
	}
});

var companyTypeStore = Ext.create('Ext.ux.CategoryStore', {
<<<<<<< HEAD
	storeId:	'companyTypeStore',
	autoLoad:	true,
	remoteFilter:	true,
=======
	storeId: 'companyTypeStore',
	autoLoad: true,
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Company Type\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var ticketPriorityStore = Ext.create('Ext.ux.CategoryStore', {
<<<<<<< HEAD
	storeId:	'ticketPriorityStore',
	autoLoad:	true,
	remoteFilter:	true,
	// model:	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category'],
=======
	storeId: 'ticketPriorityStore',
	autoLoad: true,
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Ticket Priority\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


<<<<<<< HEAD
// Incoming and Outgoing channels are both 'Intranet Ticket Origin' category
var ticketOriginStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'ticketOriginStore',
	autoLoad:	true,
	remoteFilter:	true,
	// model:	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category', 'category_translated'],
=======

var ticketOriginStore = Ext.create('Ext.data.Store', {
	storeId: 'ticketOriginStore',
	autoLoad: true,
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Ticket Origin\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var requestAreaStore = Ext.create('Ext.data.Store', {
<<<<<<< HEAD
	storeId:	'requestAreaStore',
	autoLoad:	true,
	remoteFilter:	true,
	pageSize:	500,
	// model: 	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category', 'category_translated'],
=======
	storeId: 'requestAreaStore',
	autoLoad: true,
	pageSize: 500,
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Request Area\''
		},
		reader: { type: 'json', root: 'data' }
	}
});



var requestAreaProgramStore = Ext.create('Ext.data.Store', {
<<<<<<< HEAD
	storeId:	'requestAreaProgramStore',
	autoLoad:	true,
	remoteFilter:	true,
	pageSize:	500,
	// model:	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields:		['category_id', 'category', 'category_translated'],
=======
	storeId: 'requestAreaProgramStore',
	autoLoad: true,
	pageSize: 500,
	// model: 'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: ['category_id', 'category', 'category_translated'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Request Area\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var ticketPriorityData = [
{"id": "30201", "object_name": "1", "category_id": "30201", "tree_sortkey": "00030201", "category": "1", "category_translated": "1", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30202", "object_name": "2", "category_id": "30202", "tree_sortkey": "00030202", "category": "2", "category_translated": "2", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30203", "object_name": "3", "category_id": "30203", "tree_sortkey": "00030203", "category": "3", "category_translated": "3", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30204", "object_name": "4", "category_id": "30204", "tree_sortkey": "00030204", "category": "4", "category_translated": "4", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30205", "object_name": "5", "category_id": "30205", "tree_sortkey": "00030205", "category": "5", "category_translated": "5", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30206", "object_name": "6", "category_id": "30206", "tree_sortkey": "00030206", "category": "6", "category_translated": "6", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30207", "object_name": "7", "category_id": "30207", "tree_sortkey": "00030207", "category": "7", "category_translated": "7", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30208", "object_name": "8", "category_id": "30208", "tree_sortkey": "00030208", "category": "8", "category_translated": "8", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"},
{"id": "30209", "object_name": "9", "category_id": "30209", "tree_sortkey": "00030209", "category": "9", "category_translated": "9", "category_description": "", "category_type": "Intranet Ticket Priority", "category_gif": "category", "enabled_p": "t", "parent_only_p": "f", "aux_int1": "", "aux_int2": "", "aux_string1": "", "aux_string2": "", "sort_order": "0"}
];

var userStore = Ext.create('Ext.ux.UserStore', {
	storeId:	'userStore',
	model:		'TicketBrowser.User',
	remoteSort:	true,
<<<<<<< HEAD
	remoteFilter:	true,
=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	autoLoad: 	true,
	autoSync: 	true,			// Write changes to the REST server ASAP
	// Load all users into this table, this is rarely more than 2000...
	// ToDo: Replace this with a server-side search function plus cache(?)
	pageSize: 	1000000
});


var programStore = Ext.create('Ext.data.Store', {
<<<<<<< HEAD
	storeId:	'programStore',
	autoLoad:	true,
	remoteFilter:	true,
	fields:		['project_id', 'project_name'],
=======
	storeId: 'programStore',
	autoLoad: true,
	fields: ['project_id', 'project_name'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_project',
		appendId: true,
		extraParams: {
			format: 'json',
			format_variant: 'sencha',
			project_type_id: '2510'		// project_type_id = "Program"
		},
		reader: { type: 'json', root: 'data' }
	}
});



var ticketSlaStore = Ext.create('Ext.data.Store', {
<<<<<<< HEAD
	storeId:	'ticketSlaStore',
	autoLoad:	true,
	remoteFilter:	true,
	fields:		['project_id', 'project_name'],
=======
	storeId: 'ticketSlaStore',
	autoLoad: true,
	fields: ['project_id', 'project_name'],
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_project',
		appendId: true,
		extraParams: {
			format: 'json',
			format_variant: 'sencha',
			project_type_id: '2502'		// project_type_id = "Service Level Agreement"
		},
		reader: { type: 'json', root: 'data' }
	}
});



var ticketStore = Ext.create('Ext.data.Store', {
	storeId: 'ticketStore',
	model: 'TicketBrowser.Ticket',
	remoteSort: true,
<<<<<<< HEAD
	remoteFilter:	true,
=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	pageSize: 10,			// Enable pagination
	autoSync: true,			// Write changes to the REST server ASAP
	sorters: [{
		property: 'creation_date',
		direction: 'DESC'
<<<<<<< HEAD
	}]
=======
	}],
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
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
});
	

var companyStore = Ext.create('Ext.ux.CompanyStore', {
	storeId: 'companyStore',
	model: 'TicketBrowser.Company',
	remoteSort: true,
<<<<<<< HEAD
	remoteFilter:	true,
=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
	pageSize: 1000000,
	autoSync: true,			// Write changes to the REST server ASAP
	autoLoad: true,
	sorters: [{
		property: 'creation_date',
		direction: 'DESC'
	}]
});


<<<<<<< HEAD
var profileStore = Ext.create('Ext.data.Store', {
	storeId: 'profileStore',
	model: 'TicketBrowser.Profile',
	autoLoad: true,
	remoteSort: true,
	remoteFilter:	true,
	pageSize: 1000,			// There should never be more then dozen groups or so...
	sorters: [{
		property: 'group_name',
		direction: 'DESC'
	}],
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_profile',
		extraParams: {
			format: 'json'		// Tell the ]po[ REST to return JSON data.
		},
		reader: {
			type: 'json',		// Tell the Proxy Reader to parse JSON
			root: 'data',		// Where do the data start in the JSON file?
			totalProperty: 'total'
		}
	}
});


=======
>>>>>>> f28b20312987c00522c779b38657840137fb0b5b
// fake store while developing
var ticketServiceTypeStore = ticketSlaStore;
var ticketChannelStore = ticketOriginStore; // look up for ticket_origin
var ticketQueueStore = ticketPriorityStore;

