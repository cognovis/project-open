  <master src="../../intranet-core/www/master"></master>
  <property name="title">@page_title;noquote@</property>
  <property name="main_navbar_label">projects</property>
  <property name="sub_navbar">@sub_navbar;noquote@</property>
  <property name="show_left_navbar_p">0</property>
   <script type="text/javascript">
    
Ext.onReady(function(){

    //  Top Form....
    var budget_form = new Ext.form.FormPanel({
        id: 'budget_form',
        frame:true,
        title: 'Budgetantrag',
        bodyStyle:'padding:5px 5px 0',
        width: '1000',
        renderTo: 'malte',
        items: [{
            layout:'column',
            labelAlign: 'top',
            items:[{
                columnWidth:.5,
                layout: 'form',
                items: [@budget_js;noquote@,
                        @invest_js;noquote@,
                        @invest_exp_js;noquote@,
                        @annual_js;noquote@,
                        @annual_exp_js;noquote@]
            },{
                columnWidth:.5,
                layout: 'form',
                items: [@budget_hours_js;noquote@,
                        @single_js;noquote@,
                        @single_exp_js;noquote@,
                        @gain_js;noquote@,
                        @gain_exp_js;noquote@]
            }]
        }],
        buttons: [{
            text: '#acs-kernel.common_Reset#',
            handler:function(){
                budget_form.getForm().load({
                    url:'budget-data',
                    params: {
                        action: 'get_budget', budget_id: @budget_id@},
                    failure: function(response){
                        var result=response.responseText;
                        Ext.MessageBox.alert(result,'could not connect to database');
                    }
                });
            }
        },{
            text: '#intranet-pmo.Approved#',
            handler:function(){
                budget_form.getForm().load({
                    url:'budget-data',
                    params: {
                        action: 'get_live_budget', budget_id: @budget_id@},
                    failure: function(response){
                        var result=response.responseText;
                        Ext.MessageBox.alert(result,'could not connect to database');
                    }
                });
            }
        },{
            text: '#intranet-pmo.Calculated#',
            handler:function(){
                budget_form.getForm().load({
                    url:'budget-data',
                    params: {
                        action: 'get_calculated_budget', budget_id: @budget_id@},
                    failure: function(response){
                        var result=response.responseText;
                        Ext.MessageBox.alert(result,'could not connect to database');
                    }
                });
            }
        },{
            text: '#acs-kernel.common_Save#',
            handler:function(){
                budget_form.getForm().submit({
                    method:'GET',
                    waitTitle:'Connecting',
                    waitMsg:'Sending data...',
                    url:'budget-data',
                    params: { action: 'save_budget',
                              budget_id: '@budget_id@' },
                    success: function(res){
                        Ext.Msg.alert('Status', 'Saving successful');
                    },
                    failure: function(res, req){
                        var result=respo.responseText;
                        Ext.MessageBox.alert(result,'could not connect to database');
                    }
                });
            }
        }@pmo_approve_js;noquote@]
    });

    budget_form.getForm().load({
        url:'budget-data',
        params: {
            action: 'get_budget', budget_id: @budget_id@},
        failure: function(response){
            var result=response.responseText;
            Ext.MessageBox.alert(result,'could not connect to database');
        }
    });


    // Form for the Cost elements
    var amount_fm = Ext.form;
    @amount_category_combobox;noquote@
    @amount_editor;noquote@
    @amount_cm;noquote@
    @amount_store;noquote@
    @amount_grid;noquote@

    // Form for the hourly data
    
    var hour_fm = Ext.form;
    @department_combobox;noquote@
    @hour_editor;noquote@
    @hour_cm;noquote@
    @hour_store;noquote@
    @hour_grid;noquote@


    // Form for the Cost elements
    var benefit_fm = Ext.form;
    @benefit_editor;noquote@
    @benefit_cm;noquote@
    @benefit_store;noquote@
    @benefit_grid;noquote@

});
</script>
    <div id="malte" style="margin-left: 1em"></div>
    <div id="amount_grid" style="margin-left: 1em"></div>
    <p />
    <div id="hour_grid" style="margin-left: 1em"></div>    
    <p />
    <div id="benefit_grid" style="margin-left: 1em"></div>    
