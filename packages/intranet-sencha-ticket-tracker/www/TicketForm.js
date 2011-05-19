
Ext.define('TicketBrowser.TicketForm', {
	extend: 'Ext.form.Panel',	
	alias: 'widget.ticketform',
	minHeight: 200,

	url:'ticket-save',
	stanardsubmit:false,
	frame:true,
	title: 'Ticket',
	bodyStyle:'padding:5px 5px 0',
	width: 350,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 75
	},
	defaultType: 'textfield',
	defaults: { anchor: '100%' },

	items: [{
		fieldLabel: 'Name',
		name: 'project_name',
		allowBlank:false
	},{
		fieldLabel: 'SLA',
		name: 'parent_id',
		allowBlank:false
	},{
		fieldLabel: 'Customer Contact',
		name: 'ticket_customer_contact_id',
		xtype: 'combobox',
                valueField: 'user_id',
                displayField: 'name',
		forceSelection: true,
		queryMode: 'remote',
		store: customerContactStore
	}, {
		fieldLabel: 'Type',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
		fieldLabel: 'Status',
		name: 'ticket_status_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketStatusStore
	}, {
		fieldLabel: 'Prio',
		name: 'ticket_prio_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketPriorityStore
	}, {
		xtype: 'timefield',
		fieldLabel: 'Time',
		name: 'time',
		minValue: '8:00am',
		maxValue: '6:00pm'
	}],

	loadTicket: function(rec){
		this.loadRecord(rec);
		var comp = this.getComponent('ticket_type_id');
	},

	buttons: [{
		text: 'Save'
	},{
		text: 'Cancel',
		handler: function() {
		this.up('form').getForm().reset();
		}
	},{
		text: 'Submit',
		formBind: true, //only enabled once the form is valid
		disabled: true,
		handler: function() {
			var form = this.up('form').getForm();
			if (form.isValid()) {
			form.submit({
				success: function(form, action) {
				   Ext.Msg.alert('Success', action.result.msg);
				},
				failure: function(form, action) {
				Ext.Msg.alert('Failed', action.result.msg);
				}
			});
			}
		}
	}]
});
