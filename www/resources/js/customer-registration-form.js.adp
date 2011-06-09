Ext.onReady(function(){
 
	var simple = new Ext.form.FormPanel({
		id: 'frmRegister',
       		standardSubmit: true,
		url: '/intranet-customer-portal/customer-registration-form-action.tcl',
		method: 'POST',
	        width: 350,
      		defaults: {width: 230},
	        defaultType: 'textfield',
		items: [
			@form_fields_str@
	       	], // end items 
       		buttons: [{
	       		text: 'Submit',
		        handler: function() {
				Ext.getCmp('frmRegister').getForm().submit();
       			}
		}]
	});

	simple.render('form_customer_registration');
 
	// Validation
	// Uniqueness of email 
	Ext.apply(Ext.form.VTypes, {
        	unique_email : function(val, field) {
			var email = Ext.getCmp("frmRegister").getForm().findField("email").getValue(); 
	                Ext.Ajax.request({
        	                url: '/intranet-customer-portal/validate-is-email-unique.tcl',
                	        method: 'POST',
                        	params: 'email=' + email,
	                        success: function(o) {
        	                        if (o.responseText == 0) {
						field.markInvalid('Email already in use, please login');
                        	        }
	                        }
        	        });
                	return true;
	        },
	        emailText : 'Email already in use, please login.'
	});

	Ext.apply(Ext.form.VTypes, {
		password: function(val, field) {
		if (field.password_confirm) {
			// var pwd = Ext.getCmp(field.initialPassField);
			var pwd =  Ext.getCmp("frmRegister").getForm().findField("password").getValue();
			return (val == pwd);
		}
		return true;
  	},
	passwordText: 'The passwords entered do not match!'
	});


	function setemailvalidfalse() {
	  Ext.apply(Ext.form.VTypes, {
		unique_email_false : function(val, field) {
			return false;
		}
	  });
	}

	function setemailvalidtrue() {
	  Ext.apply(Ext.form.VTypes, {
		unique_email_true : function(val, field) {
			return true;
		}
	  });
	}
});
