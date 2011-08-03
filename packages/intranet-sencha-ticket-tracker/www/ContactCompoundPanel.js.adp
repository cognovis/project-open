/**
 * intranet-sencha-ticket-tracker/www/ContactCompoundPanel.js
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: ContactCompoundPanel.js.adp,v 1.1 2011/07/18 11:26:17 po34demo Exp $
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


var contactCompoundPanel = Ext.define('TicketBrowser.ContactCompoundPanel', {
	extend:		'Ext.container.Container',
	alias:		'widget.contactCompoundPanel',
	id:		'contactCompoundPanel',
	title:		'Loading...',
	layout:		'border',
	deferredRender:	false,
	minHeight:	200,
	split:		true,
	autoScroll:	true,
	items: [{
		itemId: 'contactForm',
		xtype: 'contactForm',
		title: '#intranet-core.Contact#',
		split:	true,
		region:	'center'
/*
	}, {
		itemId:	'contactCustomerPanel',
		title:	'#intranet-sencha-ticket-tracker.Contact#',
		xtype:	'contactCustomerPanel',
		split:	true,
		region:	'center'
	}, {
		itemId: 'contactContactPanel',
		title: '#intranet-core.Contact#',
		xtype: 'contactContactPanel',
		split:	true,
		region:	'south'
*/
	}],

	// Called from the ContactGrid if the user has selected a contact
	newContact: function(rec){
		var contactForm = this.child('#contactForm');
		contactForm.newContact(rec);

/*		this.child('#center').child('#contactCustomerPanel').newContact(rec);
		this.child('#center').child('#contactContactPanel').newContact(rec);
		this.child('#east').child('#auditGrid').newContact(rec);
		this.child('#east').child('#contactFormRight').newContact(rec);
		this.child('#east').child('#fileStorageGrid').newContact(rec);
*/
	},

	// Called from the ContactGrid if the user has selected a contact
	loadContact: function(rec){
		var contactForm = this.child('#contactForm');
		contactForm.loadContact(rec);

/*
		this.child('#center').child('#contactContactPanel').loadContact(rec);
		this.child('#center').child('#contactCustomerPanel').loadContact(rec);
		this.child('#east').child('#auditGrid').loadContact(rec);
		this.child('#east').child('#contactFormRight').loadContact(rec);
		this.child('#east').child('#fileStorageGrid').loadContact(rec);
*/
	}

});


