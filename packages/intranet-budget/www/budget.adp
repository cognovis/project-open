  <master src="../../intranet-core/www/master"></master>
  <property name="title">@page_title;noquote@</property>
  <property name="main_navbar_label">finance</property>
  <property name="sub_navbar">@sub_navbar;noquote@</property>

   <script type="text/javascript">

    Ext.util.Format.comboRenderer = function(combo){
        return function(value){
            var record = combo.findRecord(combo.valueField, value);
            return record ? record.get(combo.displayField) : combo.valueNotFoundText;
        }
    }



Ext.util.Format.Currency = function(v)
{
    v = Ext.num(String(v).replace(/\,/, '.'));
    v = (Math.round((v-0)*100))/100;
    v = (v == Math.floor(v)) ? v + ".00" : ((v*10 == Math.floor(v*10)) ? v + "0" : v);
    if (v==0)
    {
        v = '-';
        return (v);
    }
    else
    {
        return (v + ' &euro;').replace(/\./, ',');
    }
};


Ext.onReady(function(){
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



});
</script>
    <div id="amount_grid" style="margin-left: 1em"></div>
    <p />
    <div id="hour_grid" style="margin-left: 1em"></div>    