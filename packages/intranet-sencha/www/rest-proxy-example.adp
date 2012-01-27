<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<link rel='stylesheet' href='/intranet-sencha/css/example.css' type='text/css' media='screen'>
	<script type="text/javascript" src="/intranet-sencha/js/bootstrap.js"></script> 
	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
</head> 
<body id="docbody"> 
<h1>REST Proxy Example</h1> 

<script type="text/javascript">
Ext.require(['Ext.data.*', 'Ext.grid.*']);

Ext.define('Person', {
	extend: 'Ext.data.Model',
	fields: [
		{name: 'id', type: 'int', useNull: true}, 
		'email',
		'first_names', 
		'last_name'
		],
	validations: [{
		type: 'length',
		field: 'email',
		min: 1
	}, {
		type: 'length',
		field: 'first_names',
		min: 1
	}, {
		type: 'length',
		field: 'last_name',
		min: 1
	}]
});

Ext.onReady(function(){

	var store = Ext.create('Ext.data.Store', {
		autoLoad: true,
		autoSync: true,
		model: 'Person',
		proxy: {
			type: 'rest',
			url: '/intranet-rest/user',
			appendId: true,
			extraParams: {format: 'json', format_variant: 'sencha'},
			reader: {
				type: 'json',
				root: 'data'
			},
			writer: {
				type: 'json'
			}
		},
		listeners: {
			write: function(store, operation){
				var record = operation.records[0],
					name = Ext.String.capitalize(operation.action),
					verb;
					
				if (name == 'Destroy') {
					verb = 'Destroyed';
				} else {
					verb = name + 'd';
				}
				Ext.example.msg(name, Ext.String.format("{0} user: {1}", verb, record.getId()));
				
			}
		}
	});
	
	var rowEditing = Ext.create('Ext.grid.plugin.RowEditing');
	
	var grid = Ext.create('Ext.grid.Panel', {
		renderTo: document.body,
		plugins: [rowEditing],
		width: 400,
		height: 300,
		frame: true,
		title: 'Users',
		store: store,
		iconCls: 'icon-user',
		columns: [{
			text: 'ID',
			width: 40,
			sortable: true,
			dataIndex: 'id',
			renderer: function(v){
				if (Ext.isEmpty(v)) {
					v = '&#160;';
				}
				return v;
			}
		}, {
			text: 'Email',
			flex: 1,
			sortable: true,
			dataIndex: 'email',
			field: {
				xtype: 'textfield'
			}
		}, {
			header: 'First',
			width: 80,
			sortable: true,
			dataIndex: 'first_names',
			field: {
				xtype: 'textfield'
			}
		}, {
			text: 'Last',
			width: 80,
			sortable: true,
			dataIndex: 'last_name',
			field: {
				xtype: 'textfield'
			}
		}],
		dockedItems: [{
			xtype: 'toolbar',
			items: [{
				text: 'Add',
				iconCls: 'icon-add',
				handler: function(){
					// empty record
					store.insert(0, new Person());
					rowEditing.startEdit(0, 0);
				}
			}, '-', {
				text: 'Delete',
				iconCls: 'icon-delete',
				handler: function(){
					var selection = grid.getView().getSelectionModel().getSelection()[0];
					if (selection) {
						store.remove(selection);
					}
				}
			}]
		}]
	});
});





</script>
</body>
</html>

