/**
 * intranet-sencha-ticket-tracker/www/POClasses.js
 * Subclasses specific for ]po[ use of Sencha
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

Ext.define('PO.data.CategoryStore', {
	extend: 'Ext.data.Store',
	category_from_id: function(category_id) {
		if (null == category_id || '' == category_id) { return ''; }
		var	result = 'Category #' + category_id;
		var	rec = this.findRecord('category_id',category_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('category_translated'); 
	},
	fill_tree_category_translated: 	function(store) { // Concat the tree category names. It is useful to order by name and level
		store.each(function(record){
			var tree_sortkey = record.get('tree_sortkey');
			var lon = record.get('tree_sortkey').length;
			var tree_category = '';
			
			while (lon > 0) {
				lon = lon - 8;
				tree_category = store.findRecord('category_id','' + parseInt(tree_sortkey.substr(lon,8),10)).get('category_translated') +  tree_category;
			}						
			record.set('tree_category_translated', tree_category);					
		});
	},
	validateLevel: function(value,nullvalid) { //Validate the combo value. No level with sublevel is permitted. 
		if (nullvalid && Ext.isEmpty(value)) {
			return true;
		}
		if (!nullvalid && Ext.isEmpty(value)) {
			return 'Obligatorio';
		}

		try {
			var validate = true;
			var record = this.getById(value);
			var record_field_value = record.get('tree_sortkey');
			var record_field_length = record_field_value.length;		
			
			this.clearFilter()
			this.each(function(record){
					var store_field_value = record.get('tree_sortkey');
					var store_field_length = store_field_value.length;
					if (store_field_length > record_field_length && store_field_value.substring(0,record_field_length) == record_field_value) {
						validate = 'No permitido';
						return validate;
					}
				}
			);
			return validate;	
		} catch(err) {	
			return 'Obligatorio'; 
		}
	},
	addBlank:  function() { // Add blank value to the store. It is used to white selecction in comboboxes
		var categoryVars = {category_id: '', category_translated: null, sort_order: '0'};
		var category = Ext.ModelManager.create(categoryVars, 'TicketBrowser.Category');
		this.add(category);	
	},
	getParent: function(value) {//Get category parent ID
		if (!Ext.isEmpty(value)) {
			var record = this.getById(value);
			if (!Ext.isEmpty(record)) {
				var record_field_value = record.get('tree_sortkey');
				var record_field_length = record_field_value.length;	
				this.clearFilter();
				var parent_id = this.findRecord('tree_sortkey','' + parseInt(record_field_value.substr(0,record_field_length - 8),10)).get('category_id');
				return parent_id;
			}
		}
		return '';
	}
});

/*
 * Create a specific store for users of all type.
 * The subclass contains a special lookup function.
 */

Ext.define('PO.data.UserStore', {
	extend: 'Ext.data.Store',
	name_from_id: function(user_id) {
		if (null == user_id || '' == user_id) { return ''; }
		var	result = 'User #' + user_id;
		var	rec = this.findRecord('user_id',user_id);
		if (rec == null || typeof rec == "undefined") { return result; }
		return rec.get('name');
	},
	addBlank:  function() { // Add blank value to the store. It is used to white selecction in comboboxes
		if (Ext.isEmpty(this.findRecord('first_names', 'Nuevo contacto',0,false,true,true))){
			var userVars = {user_id: '', first_names: 'Nuevo contacto'};
			var user = Ext.ModelManager.create(userVars, 'TicketBrowser.User');
			this.add(user);	
		}
	}	
});

/*
 * Create a specific store for groups/profiles.
 * The subclass contains a special lookup function.
 */
Ext.define('PO.data.ProfileStore', {
	extend: 'Ext.data.Store',
	name_from_id: function(group_id) {
		if (null == group_id || '' == group_id) { return ''; }
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
Ext.define('PO.data.CompanyStore', {
	extend: 'Ext.data.Store',
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
	},
	addBlank:  function() { // Add blank value to the store. It is used to white selecction in comboboxes
		if (Ext.isEmpty(this.findRecord('company_name', 'Nueva entidad',0,false,true,true))){
			var companyVars = {company_id: '', company_name: 'Nueva entidad'};
			var company = Ext.ModelManager.create(companyVars, 'TicketBrowser.Company');
			this.add(company);	
		}
	}		

});



Ext.define('PO.form.field.DateTimeReadOnly', {
	extend: 'Ext.form.field.Text',
	alias:	'widget.po_datetimefield_read_only',

	setValue: function(mixed) {
		if (typeof mixed == 'undefined') { 
			// Just pass on directly to parent
			this.callParent(arguments);

		} else {
			var mixed = mixed.substr(0,16);
			this.callParent([mixed]);
		}
	}
});



// Define the date of today
// This date is only calculated one during loading
// ToDo: Update the date in regular intervals
var today_date = '<%= [db_string date "select to_char(now(), \'YYYY-MM-DD\') from dual"] %>';
var today_date_time = '<%= [db_string date "select to_char(now(), \'YYYY-MM-DD HH24:MI\') from dual"] %>';
var anonimo_company_id = '<%= [db_string anon_company "select company_id from im_companies where company_path = \'anonimo\'" -default 0] %>';
var anonimo_user_id = '<%= [db_string anon "select user_id from users where username = \'anonimo\'" -default 75028] %>';
var anonimo_sla = '<%= [db_string anon "select project_id from im_projects where project_nr = \'anonimo\'" -default 0] %>'

// Use TCL template language to get the current user_id
var currentUserId = <%= [ad_get_user_id] %>;

// Constant for employee groups
var employeeGroupId = '463';		// String!
var customerGroupId = '461';		// String!

// Check if the current user is an admin
var currentUserIsAdmin = <%= [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]] %>;	// Integer!

var serviceId = '10000152';

//Check date format
dateFormat = /^([0-9]{4}\-[0-9]{2}\-[0-9]{2})?(\ [0-9]{2}\:[0-9]{2})?$/ ;

var sendmailparameter = <%= [parameter::get_from_package_key -package_key intranet-sencha-ticket-tracker -parameter SendMail -default 0] %>;
var userIsSACE = <%= [im_user_group_member_p [ad_get_user_id] 73369] %>;

var defaultQueueFilter = 'my_groups';
var emptyDefaultQueueFilter = '#intranet-sencha-ticket-tracker.My_Groups#';
if (userIsSACE) {
	defaultQueueFilter = 'all_groups';
	emptyDefaultQueueFilter = 'Todos Grupos';
}