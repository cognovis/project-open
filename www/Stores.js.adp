/**
 * intranet-sencha-ticket-tracker/www/Stores.js
 * Data stores.
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


/*
 * Create a specific store for categories.
 * The subclass contains a special lookup function.
 */
Ext.ux.CategoryStore = Ext.extend(Ext.data.Store, {
	category_from_id: function(category_id) {
		if (null == category_id || '' == category_id) { return ''; }
		var	result = 'Category #' + category_id;
		var	rec = this.findRecord('category_id',category_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('category_translated'); 
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
 * Create a specific store for groups/profiles.
 * The subclass contains a special lookup function.
 */
Ext.ux.ProfileStore = Ext.extend(Ext.data.Store, {
	name_from_id: function(group_id) {
		var	result = 'Profile #' + group_id;
		var	rec = this.findRecord('group_id',group_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('group_name');
	}
});

/*
 * Create a specific store for users of all type.
 * The subclass contains a special lookup function.
 */
Ext.ux.CompanyStore = Ext.extend(Ext.data.Store, {
	name_from_id: function(company_id) {
		var result = 'Company #' + company_id;
		var rec = this.findRecord('company_id',company_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('company_name');
	},

	vat_id_from_id: function(company_id) {
		var rec = this.findRecord('company_id',company_id);
		if (rec == null || typeof rec == "undefined") { return ''; }
		return rec.get('vat_number');
	}

});



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
	storeId:	'ticketStatusStore',
	autoLoad:	true,
	remoteFilter:	true,
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
	storeId:	'companyTypeStore',
	autoLoad:	true,
	remoteFilter:	true,
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
	storeId:	'ticketPriorityStore',
	autoLoad:	true,
	remoteFilter:	true,
	// model:	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category'],
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


// Incoming and Outgoing channels are both 'Intranet Ticket Origin' category
var ticketOriginStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'ticketOriginStore',
	autoLoad:	true,
	remoteFilter:	true,
	// model:	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category', 'category_translated'],
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
	storeId:	'requestAreaStore',
	autoLoad:	true,
	remoteFilter:	true,
	pageSize:	500,
	// model: 	'TicketBrowser.Category',	// Causes the Drop-Down not to load
	fields: 	['category_id', 'category', 'category_translated'],
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



var requestAreaProgramStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'requestAreaProgramStore',
	autoLoad:	true,
	remoteFilter:	true,
	pageSize:	500,
	model:		'TicketBrowser.Category',
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


var bizObjectRoleStore = Ext.create('Ext.ux.CategoryStore', {
	storeId:	'bizObjectRoleStore',
	autoLoad:	true,
	remoteFilter:	true,
	pageSize:	500,
	model:		'TicketBrowser.Category',
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			category_type: '\'Intranet Biz Object Role\''
		},
		reader: { type: 'json', root: 'data' }
	}
});


var userStore = Ext.create('Ext.ux.UserStore', {
	storeId:	'userStore',
	model:		'TicketBrowser.User',
	remoteSort:	true,
	remoteFilter:	true,
	autoLoad: 	true,
	autoSync: 	true,			// Write changes to the REST server ASAP
	// Load all users into this table, this is rarely more than 2000...
	// ToDo: Replace this with a server-side search function plus cache(?)
	pageSize: 	1000000
});


var programStore = Ext.create('Ext.data.Store', {
	storeId:	'programStore',
	autoLoad:	true,
	remoteFilter:	true,
	fields:		['project_id', 'project_name'],
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
	storeId:	'ticketSlaStore',
	autoLoad:	true,
	remoteFilter:	true,
	fields:		['project_id', 'project_name'],
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
	remoteFilter:	true,
	pageSize: 10,			// Enable pagination
	autoSync: true,			// Write changes to the REST server ASAP
	sorters: [{
		property: 'creation_date',
		direction: 'DESC'
	}]
});
	

var companyStore = Ext.create('Ext.ux.CompanyStore', {
	storeId: 'companyStore',
	model: 'TicketBrowser.Company',
	remoteSort: true,
	remoteFilter:	true,
	pageSize: 1000000,
	autoSync: true,			// Write changes to the REST server ASAP
	autoLoad: true,
	sorters: [{
		property: 'creation_date',
		direction: 'DESC'
	}]
});


var profileStore = Ext.create('Ext.ux.ProfileStore', {
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


// fake store while developing
var ticketServiceTypeStore = ticketSlaStore;
var ticketChannelStore = ticketOriginStore; // look up for ticket_origin
var ticketQueueStore = ticketPriorityStore;

