/**
 * intranet-sencha-ticket-tracker/www/TicketCompoundPanel.js
 * Container for company-contacts detail.
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


Ext.define('TicketBrowser.CompanyContactCompoundPanel', {
    extend:		'Ext.container.Container',
    alias:		'widget.companyContactCompoundPanel',
    id:			'companyContactCompoundPanel',
    title:		'Loading...',
    layout:		'border',
    deferredRender:	false,
    split:		true,

	items: [{
		itemId:	'companyContactCustomerPanel',
		title:	'#intranet-sencha-ticket-tracker.Company#',
		xtype:	'companyContactCustomerPanel',
		split:	true,
		minHeight: 100,
		region:	'center'
	}, {
		itemId: 'companyContactContactPanel',
		title: '#intranet-sencha-ticket-tracker.Contact#',
		xtype: 'companyContactContactPanel',
		split:	true,
		height: '60%',
		width: '50%',
		minHeight: 150,
		region:	'south'
    }],

    newCompany: function(){
    	this.enable();
		Ext.getCmp('companyContactCustomerPanel').newCompany();
		Ext.getCmp('companyContactContactPanel').newCompany();
    },
        
    loadCompany: function(rec){
    	this.enable();
    	Ext.getCmp('companyContactCustomerPanel').loadCompany(rec);
    	Ext.getCmp('companyContactContactPanel').loadCompany(rec);
        
        //Inicialize dirty. There is no changes after load.
		var companyModel =companyStore.findRecord('company_id',rec.get('company_id'));
		if (companyModel != null) { 
			companyModel.dirty = false;        
		}
    },
    
	//If the field value is diferent from store value, set model dirty variable to true
	checkCompanyField: function(field,newValue,oldValue,store) { 
		var company_id_field = Ext.getCmp('companyContactCustomerPanel').getForm().findField('company_id');
		var company_id = company_id_field.getValue();
		var companyModel = companyStore.findRecord('company_id',company_id);
		
		if (companyModel != null && companyModel != undefined) {
			var companyModelFieldValue =  companyModel.get(field.name);
			if (companyModelFieldValue != null && companyModelFieldValue != undefined && newValue != companyModelFieldValue) {						
				companyModel.setDirty();
			}
		}
	},
	
	//If the field value is diferent from store value, set model dirty variable to true
	checkContactField: function(field,newValue,oldValue,store) { 
		var contact_id_field = Ext.getCmp('companyContactContactForm').getForm().findField('user_id');
		var contact_id = contact_id_field.getValue();
		var contactModel = userCustomerStore.findRecord('user_id',contact_id);
		
		if (contactModel != null && contactModel != undefined) {
			var contactModelFieldValue =  contactModel.get(field.name);
			if (contactModelFieldValue != null && contactModelFieldValue != undefined && newValue != contactModelFieldValue) {						
				contactModel.setDirty();
			}
		}
	}    	
      
});


