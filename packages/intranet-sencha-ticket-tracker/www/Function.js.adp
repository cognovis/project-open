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

function Function_save(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket){
	try{
		if (loadCompanyContact == loadTicket){
			//do nothing
			return;
		}

		Function_checkValues(companyValues);
		Function_checkValues(contactValues);
		Function_checkValues(ticketValues);
		Function_checkValues(ticketRightValues);
		
		if (Ext.isEmpty(companyValues.company_id)) {
			companyValues.company_name = companyValues.company_name.toUpperCase();
			companyValues.vat_number = companyValues.vat_number.toUpperCase();
		}
		if (Ext.isEmpty(contactValues.user_id)) {
			contactValues.first_names = contactValues.first_names.toUpperCase();
			contactValues.last_name = contactValues.last_name.toUpperCase();
			contactValues.last_name2 = contactValues.last_name2.toUpperCase();
			if (!Ext.isEmpty(contactValues.spri_email)) {
				contactValues.email = contactValues.spri_email + Math.random()*1000000000000000000
			} else {
				contactValues.email = "nowhere@nowhere.es" + Math.random()*1000000000000000000
			}
		}		
		
		if (ticketRightValues) {
			ticketRightValues.ticket_request = ticketRightValues.ticket_request.replace(/\r/g,"");
			ticketRightValues.ticket_resolution = ticketRightValues.ticket_resolution.replace(/\r/g,"");	
			if (!Ext.isEmpty(ticketRightValues.combo_send_mail)) {				
				ticketRightValues.ticket_send_mail_ids = ticketRightValues.combo_send_mail.join('_');
			}
		}
				
		//Company and contacts validations
		if (Ext.isEmpty(companyValues.company_id) && !Function_validateNewCompany(companyValues)) {
			return;							
		} 
		if (Ext.isEmpty(contactValues.user_id) && !Function_validateNewContact(contactValues)) {
			return;
		}						
		
		if (loadCompanyContact) {
			Ext.getCmp('companyContactCompoundPanel').disable();
		}
		if (loadTicket) {	
			Ext.getCmp('ticketCompoundPanel').disable();
		}
		
		Function_saveContact(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket);
	} catch(err) {		
		if (loadCompanyContact) {
			Function_errorMessage('Error al guardar entidad contacto', 'Se ha producido un error al guardar entidad contacto', err.description);				
			Ext.getCmp('companyContactCompoundPanel').enable();
		}
		if (loadTicket) {	
			Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Ticket_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Ticket_Error_Message#', err.description);				
			Ext.getCmp('ticketCompoundPanel').enable();
		}		
	}
}

function Function_saveCompany(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket){
	var companyModel;
	var newCompany = false;
	var company_id = companyValues.company_id;
	if (anonimo_company_id != company_id) {
		if (Ext.isEmpty(company_id)) {
			companyValues.company_id = null;
			companyModel = Ext.ModelManager.create(companyValues, 'TicketBrowser.Company');
			companyModel.phantom = true;
			newCompany = true;
		} else {
			companyModel = companyStore.findRecord('company_id',companyValues.company_id);
			companyModel.set(companyValues);
		}		
		companyModel.save({
			scope: this,
			success: function(company_record, operation) {
				// Store the new company in the store that that it can be referenced.
				company_id = company_record.get('company_id');
				if (newCompany) {
					companyValues.company_id = company_id;
					companyStore.add(company_record);
				}
	
				Function_relationCompanyContact(company_id, contactValues.user_id, loadCompanyContact, loadTicket);
				if (loadTicket){
					//Save ticket
					ticketValues.company_id = company_id;
					Function_saveTicket(ticketValues, ticketRightValues, loadCompanyContact, loadTicket);
				}
				if (loadCompanyContact) { 
					Ext.getCmp('companyContactCompoundPanel').tab.setText(company_record.get('company_name'));
				}
			},
			failure: function(company_record, operation) {
				Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Company_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Company_Error_Message# ', operation.request.scope.reader.jsonData["message"]);
				if (loadCompanyContact) {
					Ext.getCmp('companyContactCompoundPanel').enable();
				}
				if (loadTicket){
					Ext.getCmp('ticketCompoundPanel').enable();
				}				
			}
		});		
	} else {
		if (loadTicket){
			ticketValues.company_id = company_id;
			Function_saveTicket(ticketValues, ticketRightValues, loadCompanyContact, loadTicket);
		}
		if (loadCompanyContact) {
			companyRecord = companyStore.findRecord('company_id',company_id,0,false,false,true);
			Ext.getCmp('companyContactCompoundPanel').loadCompany(companyRecord);			
		}		
	}
}

function Function_saveContact(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket){
	var contactModel;
	var newContact = false;
	var contact_id = contactValues.user_id;
			
	if (anonimo_user_id != contact_id) {	
		if (Ext.isEmpty(contact_id)) {
			contactValues.user_id = null;
			contactValues.username =  contactValues.first_names + contactValues.last_name + parseInt((Math.random()*10000000),10);
			contactModel = Ext.ModelManager.create(contactValues, 'TicketBrowser.User');
			contactModel.phantom = true;		
			newContact =true;
		} else {
			contactModel = userCustomerContactStore.findRecord('user_id',contactValues.user_id);
			contactModel.set(contactValues);
		}			
		contactModel.save({
			scope: this,
			success: function(contact_record, operation) {	
				contact_id = contact_record.get('user_id');
				
				if (loadTicket){
					//ticketModel.set('ticket_customer_contact_id', contact_id);	
					ticketValues.ticket_customer_contact_id = contact_id;
				}
				companyValues.primary_contact_id = contact_id;
				if (newContact) {
					contactValues.user_id = contact_id;
					userStore.add(contact_record);
					userCustomerContactStore.add(contact_record);	
					userCustomerStore.add(contact_record);
						
					// Add the users to the group "Customers".
					// This code doesn't need to be synchronized.
					// The record will establish a "relationship" between the users and a group
					var groupMember = {
						object_id_one:	customerGroupId,		// group_id for Customers
						object_id_two:	contact_id,
						rel_type:	'membership_rel',
						member_state:	'approved'
					};
					var groupMemberModel = Ext.ModelManager.create(groupMember, 'TicketBrowser.GroupMember');
					groupMemberModel.phantom = true;
					groupMemberModel.save({
						scope: this,
						success: function(record, operation) { 
							Function_saveCompany(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket);
						},			
						failure: function(record, operation) { 
							Function_errorMessage('#intranet-sencha-ticket-tracker.Contact_Group_Error_Title#', '#intranet-sencha-ticket-tracker.Contact_Group_Error_Message#', operation.request.scope.reader.jsonData["message"]);
							if (loadCompanyContact){
								Ext.getCmp('companyContactCompoundPanel').enable(); 
							}
						}
					});														
				} else {								
					companyValues.primary_contact_id = contact_id;
					Function_saveCompany(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket);
				}
			},
			failure: function(record, operation) {
				Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Contact_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Contact_Error_Message#', operation.request.scope.reader.jsonData["message"]);
				if (loadCompanyContact){
					Ext.getCmp('companyContactCompoundPanel').enable();
				}
				if (loadTicket){
					Ext.getCmp('ticketCompoundPanel').enable();
				}						
			}
		});	
	} else {		
		if (loadTicket){
			ticketValues.ticket_customer_contact_id = contact_id;
		}		
		companyValues.primary_contact_id = contact_id;
		Function_saveCompany(companyValues, contactValues, ticketValues, ticketRightValues, loadCompanyContact, loadTicket);	
	}	
}

function Function_saveTicket(ticketValues, ticketRightValues, loadCompanyContact, loadTicket){
	var ticketModel;
	var newTicket = false;
	
	if (ticketRightValues.ticket_queue_id != ticketRightValues.ticket_org_queue_id){
		ticketRightValues.ticket_last_queue_id=ticketRightValues.ticket_org_queue_id;
	}
	
	if (Ext.isEmpty(ticketValues.ticket_id)){
		ticketValues.ticket_id = null;
		ticketRightValues.ticket_id = null;
		ticketModel = Ext.ModelManager.create(ticketValues, 'TicketBrowser.Ticket');
		ticketModel.phantom = true;	
		ticketModel.set(ticketRightValues);		
		newTicket = true;	
	} else {
		ticketModel = ticketStore.findRecord('ticket_id',ticketValues.ticket_id);
		ticketModel.set(ticketValues);
		ticketModel.set(ticketRightValues);
	}	
/*	if (ticketModel.get('ticket_queue_id') != ticketModel.get('ticket_org_queue_id')){
		ticketModel.set('ticket_last_queue_id', ticketModel.get('ticket_org_queue_id'));
	}	*/
	//console.log('Estado antes guardar: ' + ticketRightValues.ticket_status_id);
	ticketModel.save({
		scope: this,
		success: function(ticket_record, operation) {
			var ticket_id = ticket_record.get('ticket_id');
		//	console.log('Ticket guardado OK: ' + ticket_record.get('ticket_id') + ' Estado guardado: ' + ticket_record.get('ticket_status_id'));
			if (newTicket) {
				ticketValues.ticket_id = ticket_id;
				ticketRightValues.ticket_id = ticket_id;
				ticketStore.add(ticket_record);
			}
			if (0 != sendmailparameter) {
				Function_sendMail(ticket_id);
			}
			Function_insertAction(ticket_id, ticketValues.datetime, ticket_record);
			Ext.getCmp('ticketCompoundPanel').tab.setText(ticket_record.get('project_name'));
		},
		failure: function(record, operation) {
			Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Ticket_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Ticket_Error_Message#', operation.request.scope.reader.jsonData["message"]);				
			if (loadTicket) {
				Ext.getCmp('ticketCompoundPanel').enable();
			}					
		}
	});	
}

/**
 *	Create reletion between company and contact
 */
function Function_relationCompanyContact(company_id, contact_id, loadCompanyContact){
	if (anonimo_company_id != company_id) {		// Don't save for Anonymous
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
				if (loadCompanyContact) {
					companyRecord = companyStore.findRecord('company_id',company_id,0,false,false,true);
					Ext.getCmp('companyContactCompoundPanel').loadCompany(companyRecord);
				}	
			},
			failure: function(record, operation) { 
				Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Relationship_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Relationship_Error_Message#', operation.request.scope.reader.jsonData["message"]);
				if (loadCompanyContact) {
					Ext.getCmp('companyContactCompoundPanel').enable();
				}
			}
		});
	} else {
		if (loadCompanyContact) {
			companyRecord = companyStore.findRecord('company_id',company_id,0,false,false,true);
			Ext.getCmp('companyContactCompoundPanel').loadCompany(companyRecord);
		}			
	}
}

/**
 *	Validate a new company
 */
function Function_validateNewCompany(values){
	var comanyModelname = companyStore.findRecord('company_name',values.company_name,0,false,false,true);
	if (!Ext.isEmpty(comanyModelname)) {
		Ext.Msg.show({
	     	title:	'La entidad ya existe',
	     	msg:	'Ya existe una entidad con ese nombre',
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
	var userModelMail = userStore.findRecord('email',values.email,0,false,false,true);
	if (!Ext.isEmpty(userModelMail)) {
		Ext.Msg.show({
	     	title:	'El contacto ya existe',
	     	msg:	'Ya existe un contacto con ese email',
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		return false;
	}	
	return true;
}

/**
 *	Validate a ticket
 */
function Function_validateTicket(){
	var arr = new Array();
	arr[0] = Ext.getCmp('ticketForm').getForm();
	arr[1] = Ext.getCmp('ticketFormRight').getForm();
	arr[2] = Ext.getCmp('ticketContactForm').getForm();
	arr[3] = Ext.getCmp('ticketCustomerPanel').getForm();
	
	return Function_validateForms(arr);
}

/**
 *	Validate a contact/company
 */
function Function_validateCompanyContact(){
	var arr = new Array();
	arr[0] = Ext.getCmp('companyContactContactForm').getForm();
	arr[1] = Ext.getCmp('companyContactCustomerPanel').getForm();
	
	return Function_validateForms(arr);
}

/**
 *	Validate a Form
 */
function Function_validateForms(formArray){
	var result = true;
	for (i in formArray){
		if (!formArray[i].isValid()){
			Ext.Msg.show({
		     	title:	'Datos no v�lidos',
		     	msg:	'Algunos de los valores no son v�lidos.',
		    	buttons: Ext.Msg.OK,
		    	icon: Ext.MessageBox.ERROR
			});		
			result = false;	
			break;		
		}
	}
	return result;	
}

/**
 *	Ajax call to insert new action in audit.
 */
function Function_insertAction(object_id, act, record){
	Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/audit-insert?object_id=' + object_id + '&action=' + act ,
		success: function(response) {	
			if (response.responseText.indexOf('false') > 0) {
				Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Action_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Action_Error_Message#', response.responseText);
			}
			if (!Ext.isEmpty(record)){
				Ext.getCmp('ticketCompoundPanel').loadTicket(record);
			}
		},
		failure: function(response) {	
			Function_errorMessage('#intranet-sencha-ticket-tracker.Save_Action_Error_Title#', '#intranet-sencha-ticket-tracker.Save_Action_Error_Message#', response.responseText);
			if (!Ext.isEmpty(record)){
				Ext.getCmp('ticketCompoundPanel').loadTicket(record);
			}			
		}
	});
}

/**
 *	Calculate the drop-down box for escalation
 */
function Funtion_calculateEscalation(ticket_area_id){
	var programId = ticket_area_id;
	if (null != ticket_area_id) {
		var programModel = ticketAreaStore.findRecord('category_id', ticket_area_id);
		if (null != programModel) {
			// Delete the selection of the Escalation combo
			var esclationField = Ext.getCmp('ticketFormRight').getForm().findField('ticket_queue_id');
			delete esclationField.lastQuery;

			// Remove all elements from the store
			programGroupStore.removeAll();

			// Get the row with the list of groups enabled for this area:
			var programName = programModel.get('category');
            var mapRow = SPRIProgramGroupMap.findRecord('Programa', programName);
			if (null == mapRow) {
				//alert('Error de configuraci�n:\nPrograma "'+programName+'" no encontrado');
				console.log('Error de configuraci�n:\nPrograma "'+programName+'" no encontrado');
				return;
			}

			// loop through the groups in the profile store and add them
			// to the programGroupStore IF it's enabled for this program.
			for (var i = 0; i < profileStore.getCount(); i++) {
				var profileModel = profileStore.getAt(i);
				var profileName = profileModel.get('group_name');
				var enabled = mapRow.get(profileName);
				if (enabled != null && enabled != '') {
					programGroupStore.insert(0, profileModel);
				}
			}
	    }
	}		
}

/**
 *	Show generic error messagge, especific error will be write in console
 */
function Function_errorMessage(e_title, e_msg, e_log){
		Ext.Msg.show({
	     	title:	e_title,
	     	msg:	e_msg,
	    	buttons: Ext.Msg.OK,
	    	icon: Ext.MessageBox.ERROR
		});		
		if (!Ext.isEmpty(e_log)){
			console.error(e_log);
		}else{
			console.error("Error desconocido")
		}
}


function Function_stopBar() {
		//To avoid infinite loading in progressBar when the load is faster than grafical
		if (Ext.getCmp('ticketActionBar') == undefined) {
			//setTimeout("Function_StopBar()", 3000);
			GLOBAL_STOP_BAR = 1;
		} else {
			setTimeout("Ext.getCmp(\'ticketActionBar\').stopBar()", 2000);
		}
}

function Function_sendMail(ticket_id) {
	/* Comprobar si ya estaba escalado en las acciones, sino mandar mail en el tcl*/
	//var detinatarios_field =  Ext.getCmp('ticketFormRight').getForm().findField('combo_send_mail');
	var destinatarios = Ext.getCmp('ticketFormRight').getForm().findField('combo_send_mail').getValue();
	if (!Ext.isEmpty(destinatarios)) {
		Ext.Ajax.request({
			scope:	this,
			url:	'/intranet-sencha-ticket-tracker/send-mail?object_id=' + ticket_id+'&destinatarios='+destinatarios.join('_'),
			success: function(response) {	
				if (!Ext.isEmpty(response.responseText)) {
					Ext.Msg.show({
				     	title:	'Env�o de correo',
				     	msg:	response.responseText,
				    	buttons: Ext.Msg.OK,
				    	icon: Ext.MessageBox.INFO
					});	
				}				
			},
			failure: function(response) {	
				/* ToDo mail error message*/
				Function_errorMessage('Error al enviar mails', 'Los datos se han guardado correctamente pero se ha producido un error al intentar mandar emails.', response.responseText);		
			}
		});	
	}
}

function Function_updateEscalationDate() {
	var ticket_status_value = Ext.getCmp('ticketFormRight').getForm().findField('ticket_status_id').getValue();
		
	if ('30009'==ticket_status_value || '30011'==ticket_status_value) {	
		Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/today-date-time',
		success: function(response) {		// response is the current date-time
					Ext.getCmp('ticketFormRight').getForm().findField('ticket_escalation_date').setValue(response.responseText);
				}
		});	
	}
}

function Function_updateDoneDate() {
	var ticket_status_value = Ext.getCmp('ticketFormRight').getForm().findField('ticket_status_id').getValue();
		
	if ('30001'==ticket_status_value || '30022'==ticket_status_value || '30096'==ticket_status_value) {	
		Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/today-date-time',
		success: function(response) {		// response is the current date-time
					Ext.getCmp('ticketFormRight').getForm().findField('ticket_done_date').setValue(response.responseText);
				}
		});	
	}
}