/** 
 *  Container for contacts detail.
 *
 * @author David Blanco (david.blanco@grupoversia.com)
 * @creation-date 2011-08
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
 
 Ext.define('TicketBrowser.CompanyContactContactPanel', {
	extend:		'Ext.panel.Panel',
	alias:		'widget.companyContactContactPanel',
 	id:			'companyContactContactPanel',
	title:		'#intranet-sencha-ticket-tracker.Contact#',
	layout:		'border',
	split:	true,

	items: [{
		title:	'#intranet-sencha-ticket-tracker.Contacts#',
		itemId:	'companyContactBizObjectMemberGrid',
		xtype:	'companyContactBizObjectMemberGrid',
		region:	'north',
		split:	true,
		preventHeader: true
	}, {
		title:	'#intranet-sencha-ticket-tracker.Contacts#',
		itemId:	'companyContactContactForm',
		xtype:	'companyContactContactForm',
		region:	'center',
		split:	true,
		preventHeader: true
	}],

    // Called from the TicketGrid if the user has selected a ticket
    newContact: function(rec){
        this.child('#companyContactBizObjectMemberGrid').newContact(rec);
        this.child('#companyContactContactForm').newContact(rec);
    },

    loadContact: function(rec){
        this.child('#companyContactBizObjectMemberGrid').loadContact(rec);
        this.child('#companyContactContactForm').loadContact(rec);
    },

    // if the company changed
    loadCompany: function(rec){
    	this.show();
        this.child('#companyContactBizObjectMemberGrid').loadCompany(rec);
        this.child('#companyContactContactForm').loadCompany(rec);
    },
    
    newCompany: function(rec){
    	//this.hide();
        this.child('#companyContactBizObjectMemberGrid').newCompany();
        this.child('#companyContactContactForm').newCompany();
    }
});