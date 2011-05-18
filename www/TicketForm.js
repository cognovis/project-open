Ext.define('TicketBrowser.TicketForm', {
	extend: 'Ext.form.Panel',	
	alias: 'widget.ticketform',
	minHeight: 200,

	url:'simple-form-save',
	stanardsubmit:false,
	frame:true,
	title: 'Simple Form',
	bodyStyle:'padding:5px 5px 0',
	width: 350,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 75
	},
	defaultType: 'textfield',
	defaults: {
		anchor: '100%'
	},

	items: [{
		fieldLabel: 'First Name',
		name: 'first',
		allowBlank:false
	},{
		fieldLabel: 'Last Name',
		name: 'last'
	},{
		fieldLabel: 'Company',
		name: 'company'
	}, {
		fieldLabel: 'Email',
		name: 'email',
		vtype:'email'
	}, {
		xtype: 'timefield',
		fieldLabel: 'Time',
		name: 'time',
		minValue: '8:00am',
		maxValue: '6:00pm'
	}],

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
