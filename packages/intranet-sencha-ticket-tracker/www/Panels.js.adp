
// -------------------------------------------------------------------- //
//                       Entidad y Persona de contacto                  //
// -------------------------------------------------------------------- //

Ext.define('TEC.panel.TicketEntidad', {
    extend:     'Ext.form.Panel',
    url:        'save-form',
    frame:      true,
    title:      'Informaci&oacute;n de Entidad',
    bodyStyle:  'padding:5px 5px 0',
    width:      350,
    fieldDefaults: {
        msgTarget: 'side',
        labelWidth: 75
    },
    defaults: {
        anchor: '100%'
    },
    items: [{
            fieldLabel: 'Razon social',
            name:       'ticket_company_name',
            allowBlank: false
        },
        {
            fieldLabel: 'DNI/NIF',
            name:       'nif_cif'
        },
        {
            xtype:      'radiofield',
            name:       'ticket_language',
            value:      'eu_EU',
            fieldLabel: 'Idioma',
            boxLabel:   'Euskera'
        },
        {
            xtype:      'radiofield',
            name:       'ticket_language',
            value:      'es_ES',
            fieldLabel: '',
            labelSeparator: '',
            hideEmptyLabel: false,
            boxLabel:   'Castellano'
        },
        {
            xtype:      'fieldset',
            title:      'Entidad',
            collapsible: true,
            defaultType: 'textfield',
            layout:     'anchor',
            defaults: {
                anchor: '100%'
            },
            items :[
                {
                    xtype:          'combo',
                    fieldLabel:     'Tipo de Sociedad',
                    name:           'company',
                    value:          '',
                    valueField:     'id',
                    displayField:   'pretty_name',
                    queryMode:      'local',
                    anchor:          '-5',
                    store:          'TEC.store.CompanyTypes'
                },
                {
                    fieldLabel: 'Provincia',
                    name:       'ticket_province'
                }]
        },
        {
            xtype:      'fieldset',
            title:      'Usuario de contacto',
            defaultType: 'textfield',
            collapsed:  false,
            layout:     'anchor',
            defaults: {
                anchor: '100%'
            },
            items :[
                {
                    fieldLabel: '#intranet-core.First_names#',
                    name:       'ticket_first_contact_name',
                    allowBlank: false
                },
                {
                    fieldLabel: '(Apellidos)',
                    name:       'ticket_first_contact_last_name'
                },
                {
                    xtype:  'radiofield',
                    name:   'ticket_sex',
                    value:  '1',
                    fieldLabel: 'Genero',
                    boxLabel:   '#intranet-sencha-ticket-tracker.Male#'
                },
                {
                    xtype:          'radiofield',
                    name:           'ticket_sex',
                    value:          '0',
                    fieldLabel:     '',
                    labelSeparator: '',
                    hideEmptyLabel: false,
                    boxLabel:       '#intranet-sencha-ticket-tracker.Female#'
                }]
        },
        {
            fieldLabel:     '#intranet-sencha-ticket-tracker.Email#',
            name:           'ticket_first_mail',
            vtype:          'email'
        },
        {
            fieldLabel:     '#intranet-sencha-ticket-tracker.Mobile#',
            name:           'contact_telephone'
        }]
    ,
    buttons: [{
        text: 'Nuevo Contacto'
    },{
        text: 'Nueva Empresa'
    }]
});


// -------------------------------------------------------------------- //
//          Panel/Formulario sobre acciones de contacto                 //
// -------------------------------------------------------------------- //

Ext.define('TEC.panel.TickeContacto', {
    extend:     'Ext.form.Panel',
    frame:true,
    title: 'Información sobre acciones de contacto',
    bodyStyle:    'padding:5px 5px 0',
    width: 700,
    fieldDefaults: {
        labelAlign: 'top',
        msgTarget: 'side'
    },
    items: [{
        xtype: 'container',
        anchor: '100%',
        layout:    'hbox',
        items:[{
                xtype:    'datefield',
                fieldLabel: 'Fecha Creación',
                name: 'ticket_creation_date',
                anchor:    '96%'
            },
            {
                xtype:    'datefield',
                fieldLabel: 'Fecha de cierre',
                name: 'ticket_cierre_date',
                anchor:    '96%'
            }]
        },
        {
            xtype:          'container',
            columnWidth:    2,
            layout:         'hbox',
            items: [{
                    xtype:      'datefield',
                    fieldLabel: 'Reception Date',
                    name:       'fecha_recepcion',
                    anchor:     '100%'
                },
                {
                    xtype:          'combo',
                    fieldLabel:     'Canal de entrada',
                    name:           'ticket_incoming_channel_id',
                    mode:           'local',
                    value:          '',
                    triggerAction:  'all',
                    forceSelection: true,
                    editable:       false,
                    displayField:   'pretty_name',
                    valueField:     'id',
                    queryMode:      'local',
                    store:          'TEC.store.TicketOrigin'
                }]
        }, 
        {
            xtype:      'fieldcontainer',
            fieldLabel: 'Acción',
            combineErrors: true,
            msgTarget : 'side',
            layout:     'hbox',
            defaults: {
                flex: 1,
                hideLabel: true
            },
            items: [
                {
                    xtype: 'textareafield',
                    name: 'ticket_description',
                    fieldLabel: 'Descripción de la solicitud',
                    value: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                    width: 300
                },
                {
                    xtype: 'textareafield',
                    name: 'ticket_answer',
                    fieldLabel: 'Resultado',
                    value: '',
                    width: 300
                }
            ]
        },
        {
            xtype: 'container',
            anchor: '100%',
            layout:    'hbox',
            items:[{
                    xtype:          'combo',
                    fieldLabel:     'Estado',
                    name:           'status',
                    mode:           'local',
                    value:          'Escalado', // :TODO: get ticket value...
                    triggerAction:  'all',
                    forceSelection: true,
                    editable:       false,
                    displayField:   'pretty_name',
                    valueField:     'id',
                    queryMode:      'local',
                    store:          'TEC.store.TicketStatus'
                } ,
                {
                    xtype:      'displayfield',
                    fieldLabel: 'Detalle sobre estado...',
                    name:       'ticket_status_detail',
                    value:      '',
                    anchor:     "100%"
                }]
        },
        {
            xtype:          'combo',
            fieldLabel:     'Escalado',
            name:           'escalado',
            mode:           'local',
            value:          'Escalado',
            triggerAction:  'all',
            forceSelection: true,
            editable:       false,
            displayField:   'escalado',
            valueField:     'value',
            queryMode:      'local',
            store:          Ext.create('Ext.data.Store', {
               fields : ['escalado', 'value'],
               data   : [
                   {escalado : 'Escalado',   value: '25000'},
                   {escalado : 'Abierto',  value: '25000'},
                   {escalado : 'Cerrado',  value: '25000'}
               ]
            })            
        }],

    buttons: [{
        text: 'Cancelar'
    },
    {
        text: 'Guardar cambios'
    }]
});

// -------------------------------------------------------------------- //
//              Panel/formulario sobre ficheros adjuntos                //
// -------------------------------------------------------------------- //

Ext.define('TEC.panel.TicketFiles', {
    extend:     'Ext.form.Panel',
    url:    'save-form',
    frame:true,
    title: 'Ficheros adjuntos',
    bodyStyle:    'padding:5px 5px 0',
    width: 350,
    fieldDefaults: {
        msgTarget: 'side',
        labelWidth: 125
    },
    defaultType: 'filefield',
    defaults: {
        anchor: '100%'
    },

    items: [{
        fieldLabel: 'Adjuntos',
        name: 'file_attachment',
        msgTarget: 'side',
        labelWidth: 75,
        allowBlank:false
    }]
});

// -------------------------------------------------------------------- //
//                  Acciones de contacto con tabs                       //
// -------------------------------------------------------------------- //

var ticket_contacto_tabs = Ext.create('Ext.form.Panel', {
    title: 'Información de Acciones de Contacto',
    bodyStyle:    'padding:5px',
    width: 600,
    fieldDefaults: {
        labelAlign: 'top',
        msgTarget: 'side'
    },
    defaults: {
        anchor: '100%'
    },

    items: [{
        layout:     'column',
        border:     false,
        items:[{
            columnWidth:.5,
            border:     false,
            layout:     'anchor',
            defaultType: 'textfield',
            items: [{
                fieldLabel: 'First Name',
                name: 'first',
                anchor:    '95%'
            }, {
                fieldLabel: 'Company',
                name: 'company',
                anchor:    '95%'
            }]
        },{
            columnWidth:.5,
            border:false,
            layout: 'anchor',
            defaultType: 'textfield',
            items: [{
                fieldLabel: 'Last Name',
                name: 'last',
                anchor:    '95%'
            },{
                fieldLabel: 'Email',
                name: 'email',
                vtype:    'email',
                anchor:    '95%'
            }]
        }]
    },{
        xtype:    'tabpanel',
        plain:true,
        activeTab: 0,
        height:235,
        defaults:{bodyStyle:    'padding:10px'},
        items:[{
            title:    'Personal Details',
            defaults: {width: 230},
            defaultType: 'textfield',

            items: [{
                fieldLabel: 'First Name',
                name: 'first',
                allowBlank:false,
                value: 'Jamie'
            },{
                fieldLabel: 'Last Name',
                name: 'last',
                value: 'Avins'
            },{
                fieldLabel: 'Company',
                name: 'company',
                value: 'Ext JS'
            }, {
                fieldLabel: 'Email',
                name: 'email',
                vtype:    'email'
            }]
        },{
            title:    'Phone Numbers',
            defaults: {width: 230},
            defaultType: 'textfield',

            items: [{
                fieldLabel: 'Home',
                name: 'home',
                value: '(888) 555-1212'
            },{
                fieldLabel: 'Business',
                name: 'business'
            },{
                fieldLabel: 'Mobile',
                name: 'mobile'
            },{
                fieldLabel: 'Fax',
                name: 'fax'
            }]
        },{
            cls: 'x-plain',
            title: 'Biography',
            layout: 'fit',
            items: {
                xtype: 'htmleditor',
                name: 'bio2',
                fieldLabel: 'Biography'
            }
        }]
    }],

    buttons: [{
        text: 'Save'
    },{
        text: 'Cancel'
    }]
});
