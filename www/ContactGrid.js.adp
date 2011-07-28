/**
 * intranet-sencha-ticket-tracker/www/CompanyGrid.js
 * Grid table for ]po[ companies
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


// This store is similar to userStore but needs to be separated
// because it will be filtered. Also, it is paged, while userStore
// contains all users in the system.
var contactGridStore = Ext.create('PO.data.UserStore', {
	storeId:	'contactGridStore',
	model:		'TicketBrowser.User',
	remoteSort:	false,
	remoteFilter:	true,
	autoLoad: 	false,			// Don't load manually
	autoSync: 	true,			// Write changes to the REST server ASAP
	pageSize: 	20,			// 
	sorters: [{
		property: 'first_names',
		direction: 'ASC'
	}, {
		property: 'last_name',
		direction: 'ASC'
	}]
});


var contactGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
	mode:	'SINGLE',
	listeners: {
		selectionchange: function(sm, selections) {
			if (selections.length > 0){
				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',false);
			} else {
				Ext.getCmp('ticketActionBar').checkButton('buttonRemoveSelected',true);
			}
		}
	}	
});


var contactGrid = Ext.define('TicketBrowser.ContactGrid', {
	extend:		'Ext.grid.Panel',	
	alias:		'widget.contactGrid',
	id:		'contactGrid',
	minHeight:	200,
	store:		contactGridStore,
	selModel:	contactGridSelModel,

	listeners: {
		itemdblclick: function(view, record, item, index, e) {
			// Load the contact into the ContactCompoundPanel
			var compoundPanel = Ext.getCmp('contactCompoundPanel');
			compoundPanel.loadContact(record);
		}
	},

	columns: [
		{
			header:		'#intranet-sencha-ticket-tracker.Contacts#',
			dataIndex:	'name',
			flex:		1,
			minWidth:	150,
			renderer: function(value, metaData, record, rowIndex, colIndex, store) {
				return '<a href="/intranet/users/view?user_id=' + 
					record.get('user_id') + 
					'" target="_blank">' + 
					value +
					'</a>';
			}
		}, {
			header:		'#intranet-core.First_names#',
			dataIndex:	'first_names'
		}, {
			header:		'#intranet-core.Last_name#',
			dataIndex:	'last_name'
		}, {
			header:		'#intranet-sencha-ticket-tracker.Last_Name2#',
			dataIndex:	'last_name2'
		}, {
			header:		'#intranet-sencha-ticket-tracker.Contact_Mail#',
			dataIndex:	'email',
			minWidth:	150
		}, {
			header:	'#intranet-core.Telephone#',
			dataIndex:	'contact_telephone'
		}, {
			header:	'#intranet-sencha-ticket-tracker.Language#',
			dataIndex:	'language',
			renderer: function(value, metaData, record, rowIndex, colIndex, store) {
				switch (value) {
					case 'es_ES':	return '#intranet-sencha-ticket-tracker.lang_es_ES#';
					case 'eu_ES':	return '#intranet-sencha-ticket-tracker.lang_eu_ES#';
					default:	return value;
				}
			}
		}, {
			header:		'#intranet-sencha-ticket-tracker.Gender#',
			dataIndex:	'gender',
			renderer: function(value, metaData, record, rowIndex, colIndex, store) {
				switch (value) {
					case 'female':	return '#intranet-sencha-ticket-tracker.Female#';
					case 'male':	return '#intranet-sencha-ticket-tracker.Male#';
					default:	return value;
				}
			}
		}, {
			header:		'#intranet-sencha-ticket-tracker.Last_Updated#',
			dataIndex:	'last_modified'
		}
	],
	dockedItems:	[{
		xtype:		'pagingtoolbar',
		store:		contactGridStore,
		dock:		'bottom',
		displayInfo:	true
	}],

	// Called from ContactFilterForm in order to limit the list of
	// contacts according to filter variables.
	// filterValues is a key-value list (object).
	filterContacts: function(filterValues){
		var store = this.store;
		var proxy = store.getProxy();
		var value = '';
		var query = '1=1';
	
		// delete filters added by other accordion filters
		delete proxy.extraParams['query'];
	
		// Apply the filter values directly to the proxy.
		// This only works if the filters are named according
		// to the REST interface specs.
		for(var key in filterValues) {
			if (filterValues.hasOwnProperty(key)) {
	
				value = filterValues[key];
				if (value == '' || value == undefined || value == null) {
					// Delete the filter
					delete proxy.extraParams[key];
				} else {
		
					// special treatment for special filter variables
					switch (key) {
					case 'first_names':
						// Fuzzy search
						value = value.toLowerCase();
						query = query + ' and lower(first_names) like \'%' + value + '%\'';
						key = 'query';
						value = query;
						break;
					case 'last_name':
						// Fuzzy search
						value = value.toLowerCase();
						query = query + ' and lower(last_name) like \'%' + value + '%\'';
						key = 'query';
						value = query;
						break;
					case 'last_name2':
						// Fuzzy search
						value = value.toLowerCase();
						query = query + ' and lower(last_name2) like \'%' + value + '%\'';
						key = 'query';
						value = query;
						break;
					case 'email':
						// Fuzzy search
						value = value.toLowerCase();
						query = query + ' and lower(email) like \'%' + value + '%\'';
						key = 'query';
						value = query;
						break;
					case 'start_date':
						// I can't get the proxy to quote (') the date, so we do it manually here:
						var	year = '' + value.getFullYear(),
							month =  '' + (1 + value.getMonth()),
							day = '' + value.getDate();
						if (month.length < 2) { month = '0' + month; }
						if (day.length < 2) { day = '0' + day; }
						value = '\'' + year + '-' + month + '-' + day + '\'';
						// console.log(value);
						query = query + ' and contact_creation_date >= ' + value;
						key = 'query';
						value = query;
						break;
					case 'end_date':
						// I can't get the proxy to quote (') the date, so we do it manually here:
						var	year = '' + value.getFullYear(),
							month =  '' + (1 + value.getMonth()),
							day = '' + value.getDate();
						if (month.length < 2) { month = '0' + month; }
						if (day.length < 2) { day = '0' + day; }
						value = '\'' + year + '-' + month + '-' + day + '\'';
						// console.log(value);
						query = query + ' and contact_creation_date <= ' + value;
						key = 'query';
						value = query;
						break;
					break;
					}
		
					// Save the property in the proxy, which will pass it directly to the REST server
					proxy.extraParams[key] = value;
				}
			}
		}
		
		// Load the filtered user store
		store.load({
			scope: this,
			callback: function(record, operation) {
				if (!operation.wasSuccessful()) {
					Ext.Msg.alert('Error buscando por un contacto', operation.request.scope.reader.jsonData["message"]);
				}
			}
		});
	},

	// The user has pressed the "New" button.
	// Tell the ContactForm to clean the data
	onNew: function() {
		var contactForm = Ext.getCmp('contactForm');
		contactForm.newContact();
	},

	// The user has pressed the "Delete" button in the contact list page
/*	onDelete: function() {

		// Get the selected user (only one!)
		var selection = this.selModel.getSelection();
		var userModel = selection[0];

		// Delete the user. This triggers a DELETE server request
		userModel.destroy({
			success: function(record, operation) {
				contactGridStore.remove(userModel);
				userStore.remove(userModel);
			},
			failure: function(record, operation) {
				Ext.Msg.alert('Error borrando User #'+userModel.get('project_nr')+':\nSolo administradores tienen permisso para borrar users.', operation.request.scope.reader.jsonData["message"]);
			}
		});


	},*/
	onDelete: function() {
		// Get the selected customer (only one!)
		var selection = this.selModel.getSelection();
		var contactModel = selection[0];		
		
		//Create and show the window to change and delete the customer
		var changeWindow = new TicketBrowser.TicketChangeContactWindow();
		changeWindow.down('form').getForm().findField('contactDeleteCombo').select(contactModel.get('user_id'));
		changeWindow.show();
	},	

	onCopy: function() {
		alert('ContactGrid.onCopy() not implemented yet');
	}

});
