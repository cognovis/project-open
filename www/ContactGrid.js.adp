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


var contactGridSelModel = Ext.create('Ext.selection.CheckboxModel', {
	mode:	'SINGLE'
});


var contactGrid = Ext.define('TicketBrowser.ContactGrid', {
	extend:		'Ext.grid.Panel',	
	alias:		'widget.contactGrid',
	id:		'contactGrid',
	minHeight:	200,
	store:		userStore,
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
		xtype:	'toolbar',
		cls:	'x-docked-noborder-top',
		items:	[{
				text:		'#intranet-sencha-ticket-tracker.New_Contact#',
				iconCls:	'icon-new-ticket',
				handler: function(){
					alert('Not implemented');
				}
		}] 
	}, {
		xtype:		'pagingtoolbar',
		store:		userStore,
		dock:		'bottom',
		displayInfo:	true
	}]
});
