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
var anonimo_company_id = '<%= [db_string anon "select company_id from im_companies where company_path = 'anonimo'" -default 0] %>';

// Use TCL template language to get the current user_id
var currentUserId = <%= [ad_get_user_id] %>;

// Constant for employee groups
var employeeGroupId = '463';		// String!
var customerGroupId = '461';		// String!

// Check if the current user is an admin
var currentUserIsAdmin = <%= [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]] %>;	// Integer!
