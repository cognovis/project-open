/**
 * intranet-sencha-ticket-tracker/www/CompanyCompoundPanel.js
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


var companyCompoundPanel = Ext.define('TicketBrowser.CompanyCompoundPanel', {
	extend:		'Ext.container.Container',
	alias:		'widget.companyCompoundPanel',
	id:		'companyCompoundPanel',
	title:		'Loading...',
	layout:		'border',
	deferredRender:	false,
	minHeight:	200,
	split:		true,
	autoScroll:	true,
	items: [{
		itemId: 'companyForm',
		xtype: 'companyForm',
		title: '#intranet-sencha-ticket-tracker.Company#',
		split:	true,
		region:	'center'
/*
	}, {
		itemId:	'companyCustomerPanel',
		title:	'#intranet-sencha-ticket-tracker.Company#',
		xtype:	'companyCustomerPanel',
		split:	true,
		region:	'center'
	}, {
		itemId: 'companyContactPanel',
		title: '#intranet-sencha-ticket-tracker.Contact#',
		xtype: 'companyContactPanel',
		split:	true,
		region:	'south'
*/
	}],

	// Called from the CompanyGrid if the user has selected a company
	newCompany: function(rec){
		var companyForm = this.child('#companyForm');
		companyForm.newCompany(rec);

/*		this.child('#center').child('#companyCustomerPanel').newCompany(rec);
		this.child('#center').child('#companyContactPanel').newCompany(rec);
		this.child('#east').child('#auditGrid').newCompany(rec);
		this.child('#east').child('#companyFormRight').newCompany(rec);
		this.child('#east').child('#fileStorageGrid').newCompany(rec);
*/
	},

	// Called from the CompanyGrid if the user has selected a company
	loadCompany: function(rec){
		var companyForm = this.child('#companyForm');
		companyForm.loadCompany(rec);

/*
		this.child('#center').child('#companyContactPanel').loadCompany(rec);
		this.child('#center').child('#companyCustomerPanel').loadCompany(rec);
		this.child('#east').child('#auditGrid').loadCompany(rec);
		this.child('#east').child('#companyFormRight').loadCompany(rec);
		this.child('#east').child('#fileStorageGrid').loadCompany(rec);
*/
	}

});


