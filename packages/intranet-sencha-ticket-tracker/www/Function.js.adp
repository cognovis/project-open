/**
 * intranet-sencha-ticket-tracker/www/Function.js
 * General Functions
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

/**
	Trims whitespace:
		Only one whitespace between words is correct.
		Trims whitespace from either end of a string.
*/
function Function_espaces(text){
	if (!Ext.isString(text)){
		return text;
	} 

	var ar_word= text.split(' ');
	var new_text = "";
	
	for(var i=0;i<ar_word.length;i++){	
		if (ar_word[i].length > 0){
			new_text = new_text + " " + ar_word[i];
		}
	}

	return Ext.String.trim(new_text);
}

/**
 *	Check all the values removing whiteespaces with 'espaces' function
*/
function Function_checkValues(values){
	for(var field in values) {
		if (values.hasOwnProperty(field)) {
			values[field] = Function_espaces(values[field]);
		}
	}
}

/**
 *	Create a new company
 */
function Function_newCompany(values){
	Function_checkValues(values);
	values.company_id = null;
	values.company_name = values.company_name.toUpperCase();
	values.vat_number = values.vat_number.toUpperCase();
	
	var companyModel = Ext.ModelManager.create(values, 'TicketBrowser.Company');
	companyModel.phantom = true;
	
	companyModel.save({
		scope: this,
		success: function(company_record, operation) {
			// Store the new company in the store that that it can be referenced.
			companyStore.add(company_record);
			Ext.getCmp('companyContactCompoundPanel').loadCompany(company_record);
		},
		failure: function(company_record, operation) {
			Ext.Msg.alert("Error durante la creacion de una nueva entidad", operation.request.scope.reader.jsonData["message"]);
			Ext.getCmp('companyContactCompoundPanel').enable();
		}
	});
}

/**
 *	Update a company
 */
function Function_updateCompany(values){
	Function_checkValues(values);	
				
	// find the company in the store
	var company_record = companyStore.findRecord('company_id',values.company_id);

	if (values.company_id != anonimo_company_id) { //No save anonymous
		company_record.set('company_name', values.company_name.toUpperCase());
		company_record.set('vat_number', values.vat_number.toUpperCase());
		company_record.set('company_type_id', values.company_type_id);
		company_record.set('company_province', values.company_province);
		company_record.set('spri_company_telephone', values.spri_company_telephone);
		company_record.set('spri_company_email', values.spri_company_email);
		company_record.set('spri_company_fax', values.spri_company_fax);
		company_record.set('spri_company_pc', values.spri_company_pc);
		company_record.set('spri_company_address', values.spri_company_address);
		company_record.set('spri_company_city', values.spri_company_city);
		
		companyStore.sync();		// Tell the store to update the server via it's REST proxy
	}
}

/**
 *	Create a new contact
 */
function Function_newContact(values,company_id){
	Function_checkValues(values);	
	values.user_id = null;
	values.first_names = values.first_names.toUpperCase();
	values.last_name = values.last_name.toUpperCase();
	values.last_name2 = values.last_name2.toUpperCase();

	var userModel = Ext.ModelManager.create(values, 'TicketBrowser.User');
	userModel.phantom = true;
	userModel.save({
		scope: this,
		success: function(user_record, operation) {
			// Add the new user to the user store to make it accessible
			userStore.add(user_record);
			userCustomerStore.add(user_record);
			
			var contact_id = user_record.get('user_id');
			
			// Add the users to the group "Customers".
			// This code doesn't need to be synchronized.
			// The record will establish a "relationship" between the users and a group
			var groupMember = {
				object_id_one:	461,		// group_id for Customers
				object_id_two:	contact_id,
				rel_type:	'membership_rel',
				member_state:	'approved'
			};

			var groupMemberModel = Ext.ModelManager.create(groupMember, 'TicketBrowser.GroupMember');
			groupMemberModel.phantom = true;
			groupMemberModel.save({
				scope: this,
				success: function(record, operation) { 
					if (!Ext.isEmpty(company_id)){
						Function_newRelationCompanyContact(company_id, contact_id, true);
					}	
				},			
				failure: function(record, operation) { 
					Ext.Msg.alert('Failed to create group membership relationship.', operation.request.scope.reader.jsonData["message"]);
					Ext.getCmp('companyContactCompoundPanel').enable(); 
				}
			});					
		},
		failure: function(record, operation) {
			Ext.Msg.alert("Error durante la creacion de un nuevo contacto", operation.request.scope.reader.jsonData["message"]);
			Ext.getCmp('companyContactCompoundPanel').enable();
		}					
	});
}

/**
 *	Create reletion between company and contact
 */
function Function_newRelationCompanyContact(company_id, contact_id, loadCompanyContactCompoundPanel){
	if (!Ext.isEmpty(company_id) && !Ext.isEmpty(contact_id)) {
		if (75464 != company_id) {		// Don't save for Anonymous
			// Create an object_member relationship between the user and the company
			var memberValues = {
				object_id_one:	company_id,
				object_id_two:	contact_id,
				rel_type:	'im_biz_object_member',
				object_role_id:	1300,
				percentage:	''
			};
			var member_model = Ext.ModelManager.create(memberValues, 'TicketBrowser.BizObjectMember');
			member_model.phantom = true;
		
			member_model.save({
				scope: this,
				success: function(record, operation) { 
					if (loadCompanyContactCompoundPanel) {
						companyRecord = companyStore.findRecord('company_id',company_id,0,false,false,true);
						Ext.getCmp('companyContactCompoundPanel').loadCompany(companyRecord);
					}	
				},
				failure: function(record, operation) { 
					Ext.Msg.alert('Failed to create company-user relationship', operation.request.scope.reader.jsonData["message"]); 
					Ext.getCmp('companyContactCompoundPanel').enable();
				}
			});
		}
	}
}

/**
 *	Update a contact
 */
function Function_updateContact(values,company_id){
	Function_checkValues(values);	
	values.first_names = values.first_names.toUpperCase();
	values.last_name = values.last_name.toUpperCase();
	values.last_name2 = values.last_name2.toUpperCase();

	// Update the model with the form variables and save. NO save anonymous
	var userModel = userStore.findRecord('user_id',values.user_id);
	if (userModel.get('username').indexOf('anonimo') == -1) {	
		userModel.set(values);
		userModel.save({
			scope: this,
			success: function(contact_record, operation) {
				if (!Ext.isEmpty(company_id)){
					Function_newRelationCompanyContact(company_id, contact_record.get('user_id'), true);
				}
			},
			failure: function(record, operation) {
				Ext.Msg.alert('Failed to save user', operation.request.scope.reader.jsonData["message"]);
				Ext.getCmp('companyContactCompoundPanel').enable();
			}
		});
	}
}
/**
 *	Validate a new contact
 */
function Function_validateContact(values){
	if (Ext.isEmpty(values.first_names)  ||  Ext.isEmpty(values.last_name)) {
		Ext.Msg.show({
	     	title:	'Contacto no válido',
	     	msg:	'Debe introducir un nombre y apellido para el contacto',
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		return false;		
	}
	return true;	
}


/**
 *	Validate a new contact
 */
function Function_validateNewContact(values){
	if (!Function_validateContact(values)){
		return false;
	}
	
	var userModelmail = userStore.findRecord('email',values.email,0,false,false,true);
	//var userModelusername = userStore.findRecord('username',Ext.String.trim(values.first_names + ' ' + values.last_name));
	//if (!Ext.isEmpty(userModelmail) || !Ext.isEmpty(userModelusername)) {
	if (!Ext.isEmpty(userModelmail)) {
		Ext.Msg.show({
	     	title:	'El contacto ya existe',
	     	msg:	'Ya existe un contacto con ese nombre o email',
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		return false;
	}
	return true;
}

/**
 *	Validate a company
 */
function Function_validateCompany(values){
	if (Ext.isEmpty(values.company_name)  ||  Ext.isEmpty(values.company_type_id)  ||  Ext.isEmpty(values.company_province)) {
		Ext.Msg.show({
	     	title:	'Entidad no válida',
	     	msg:	'Debe introducir un nombre, tipo y provincia para la entidad',
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		return false;		
	}
	return true;
}

/**
 *	Validate a new company
 */
function Function_validateNewCompany(values){
	if (!Function_validateCompany(values)){
		return false;
	}
	
	var comanyModelname = companyStore.findRecord('company_name',values.company_name,0,false,false,true);
	if (!Ext.isEmpty(comanyModelname)) {
		Ext.Msg.show({
	     	title:	'La compañia ya existe',
	     	msg:	'Ya existe una compañia con ese nombre',
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		return false;
	}
	return true;
}

/**
 *	Ajax call to insert new action in audit.
 */
function Function_insertAction(object_id, act, record){
	Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/audit-insert?object_id=' + object_id + '&action=' + act ,
		success: function(response) {		
			if (!Ext.isEmpty(record)){
				Ext.getCmp('ticketCompoundPanel').loadTicket(record);
			}
		},
		failure: function(response) {	
			alert('Error al crear accion del ticket');	
			if (!Ext.isEmpty(record)){
				Ext.getCmp('ticketCompoundPanel').loadTicket(record);
			}			
		}
	});
}