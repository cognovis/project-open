# /extjs/tcl/extjs-procs.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# Also see http://www.sencha.com/license.

ad_library {
    
    ExtJS Integration procedures
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-03-15

}

namespace eval extjs:: {}

ad_proc -private extjs::init {
} {
    Accepts a tcl list of sources to load.
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} {
    
    template::head::add_css -href "/extjs/ExtJS3/resources/css/ext-all.css"
    template::head::add_javascript -src "/extjs/ExtJS3/adapter/ext/ext-base.js" -order 1
    template::head::add_javascript -src "/extjs/ExtJS3/ext-all-debug.js" -order 2
    template::head::add_javascript -src "/extjs/extjs-util.js" -order 23
}

ad_proc -private extjs::filter_init {
} {
    Accepts a tcl list of sources to load.
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} {
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/menu/RangeMenu.js" -order 23
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/menu/ListMenu.js" -order 23
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/GridFilters.js" -order 24
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/Filter.js" -order 31
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/StringFilter.js" -order 31
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/DateFilter.js" -order 31
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/ListFilter.js" -order 31
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/NumericFilter.js" -order 31
    template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/gridfilters/filter/BooleanFilter.js" -order 31
}



namespace eval extjs::RowEditor {}
namespace eval extjs::DataStore {}
namespace eval extjs::Form {}
namespace eval extjs::Form::Attribute {}

ad_proc -public extjs::Form::Attribute::Currency {
    {-name:required}
    {-label ""}
    {-default ""}
    {-anchor ""}
} {
    Return the item definition for a currency field
} { 
    set js_tmp ""
    if {$default ne ""} {
        append js_tmp "emptyText: '\u20AC $default', \n"
    }

    if {$label ne ""} {
        append js_tmp "fieldLabel: '$label', \n"
    }

    if {$anchor ne ""} {
        append js_tmp "anchor: '$anchor', \n"
    }
    
    return "\{
                    $js_tmp xtype:'numericfield',
                    currencySymbol: '\u20AC',
                    useThousandSeparator: true,
                    thousandSeparator: '.',
                    setDecimalPrecision: 2,
                    decimalSeparator: ',',
                    alwaysDisplayDecimals: true,
                    name: '$name'
    \}"
}

ad_proc -public extjs::Form::Attribute::Htmleditor {
    {-name:required}
    {-label ""}
    {-default ""}
    {-anchor ""}
} {
    Return the item definition for a numeric field
} { 
    set js_tmp ""
    if {$default ne ""} {
        append js_tmp "emptyText: '$default', \n"
    }

    if {$label ne ""} {
        append js_tmp "fieldLabel: '$label', \n"
    }

    if {$anchor ne ""} {
        append js_tmp "anchor: '$anchor', \n"
    }
    return "\{
                    $js_tmp xtype:'htmleditor',
                    name: '$name'
    \}"
}

ad_proc -public extjs::Form::Attribute::Textarea {
    {-name:required}
    {-label ""}
    {-default ""}
    {-maxlength ""}
    {-anchor ""}
} {
    Return the item definition for a numeric field
} { 
    set js_tmp ""
    if {$default ne ""} {
        append js_tmp "emptyText: '$default',"
    }
    if {$maxlength ne ""} {
        append js_tmp "maxLength: '$maxlength',"
    }

    if {$label ne ""} {
        append js_tmp "fieldLabel: '$label',"
    }

    if {$anchor ne ""} {
        append js_tmp "anchor: '$anchor',"
    }
    return "\{
                    $js_tmp xtype:'textarea',
                    height: 150,
                    name: '$name'
    \}"
}

ad_proc -public extjs::Form::Attribute::Numeric {
    {-name:required}
    {-label ""}
    {-default ""}
    {-anchor ""}
} {
    Return the item definition for a numeric field
} { 
    set js_tmp ""
    if {$default ne ""} {
        append js_tmp "emptyText: '$default', \n"
    }

    if {$label ne ""} {
        append js_tmp "fieldLabel: '$label', \n"
    }

    if {$anchor ne ""} {
        append js_tmp "anchor: '$anchor', \n"
    }
    return "\{
                    $js_tmp xtype:'numericfield',
                    useThousandSeparator: true,
                    thousandSeparator: '.',
                    decimalSeparator: ',',
                    alwaysDisplayDecimals: true,
                    name: '$name'
    \}"
}


ad_proc -public extjs::Form::Attribute::Number {
    {-name:required}
    {-label ""}
    {-default ""}
    {-anchor ""}
} {
    Return the item definition for a number field
} { 
    set js_tmp ""
    if {$default ne ""} {
        append js_tmp "emptyText: '$default', \n"
    }

    if {$label ne ""} {
        append js_tmp "fieldLabel: '$label', \n"
    }

    if {$anchor ne ""} {
        append js_tmp "anchor: '$anchor', \n"
    }
    return "\{
                    $js_tmp xtype:'numberfield',
                    name: '$name'
    \}"
}


ad_proc -public extjs::DataStore::Json {
    {-url:required}
    {-prefix:required}
    {-baseParams:required}
    {-root ""}
    {-id_column ""}
    {-columnDef:required}
    {-sortInfo_json ""}
} {
    This procedure returns the Javascript for initializing a remote JSON Data Store.
    
    @param url URL where your -data.tcl can be found.
    @param baseParams The base parameters you send to your -data.tcl. Usually this is at least the action (e.g. "get_json") and some ID or object_type. Example: [list action "get_json" object_id $object_id]
    @param root This is the root name of the JSON array which contains the rows.
    @param id_column Name of the column in the JSON array which is the identifier
    @param column_def Column Definition as a key value list {attribute_name datatype attribute_name datatype}. Usually it is a good thing to make the JS names match the JSON names match the acs_attribute_names.
    @param sortInfo_json Sort order definition for the column you want to sort. Usually generated with util::json::create::object list field <column_name> direction "ASC"

    @see util::json::array::create
} {

    set column_def_list [list]
    foreach {attribute datatype} $columnDef {
        lappend column_def_list "\{name: '$attribute', type: '$datatype'\}"
    }

    if {$root ne ""} {
        set root "root: '$root',"
    }
    if {$id_column ne ""} {
        set id_column "id: '$id_column'"
    }
    if {$sortInfo_json ne ""} {
        set sortInfo_json "sortInfo: $sortInfo_json"
    }
    
    return "
    // create the Data Store
    var ${prefix}store = new Ext.data.Store(\{
        // destroy the store if the grid is destroyed
        //autoDestroy: true,
        
        // load remote data using HTTP
        proxy: new Ext.data.HttpProxy(\{
            url: '$url',
            method: 'Post'
        \}),
        baseParams:  [util::json::gen [util::json::object::create $baseParams]],

        // Now really fill the store with the data from 
        reader: new Ext.data.JsonReader(\{
            $root
            $id_column
        \}, \[ 
           [join $column_def_list ",\n"] 
        \]),
        $sortInfo_json
    \});
    ${prefix}store.load(); // We need to load the store before the grid is rendered.
   "
}

ad_proc -public extjs::RowEditor::ColumnModel {
    {-prefix ""}
    {-column_defs_json:required}
    {-show_row_num_p "1"}
} {
    Return the js for the column model
    
    @param prefix The prefix for cm
    @param column_defs_json List of json objects for the column definition
    @param show_row_num_p Show the row number in the table
} {

    if {$show_row_num_p} {
        set first_row "new Ext.grid.RowNumberer(),"
    } else {
        set first_row ""
    }

    return "
    // the column model has information about grid columns
    // dataIndex maps the column to the specific data field in
    // the data store (created below)
    var ${prefix}cm = new Ext.grid.ColumnModel(\{
        // specify any defaults for each column
        defaults: \{
            sortable: true // columns are not sortable by default           
        \},
        columns: \[
                  $first_row
                  $column_defs_json
        \]
    \});
    "
}

ad_proc -public extjs::RowEditor::ComboBox {
    {-combo_name:required}
    {-optionDef ""}
    {-sql ""}
    {-form_name:required}
} {
    Return a combo box javascript definintion so the combo box can be called in the columns rendering
    
    @param combo_name Name of the combo box (like the select name) by which it can be identified.
    @param form_name Name of the form (of the grid?) which should include this combobox.
    @param optionDef List of key value pairs with the id / value and the display name. So use it like list category_id category_name category_id category_name and not the other way round. First the Value, then the displayed name
} {

    set data [list]    
    if {$optionDef eq ""} {
        if {$sql eq ""} {
            ad_return_error "Missing parameter" "we Need either SQL or optiondef"
        } else {
            set option_list [db_list_of_lists sql $sql]
            foreach option $option_list {
		set option_string [lindex $option 1]
		set option_string [lang::message::lookup "" intranet-core.[lang::util::suggest_key $option_string] $option_string ]
                lappend data "\['[lindex $option 0]', '$option_string'\]"  
            }
        }
    } else {
        foreach {value name} $optionDef {
            lappend data "\['$value', '$name'\]"
        }
    }
    
    return "
    // This is the combo box for retrieving the values from a select. This should be wrapped into a function.
    var $combo_name =  new ${form_name}.ComboBox(\{
        typeAhead: true,
        triggerAction: 'all',
        lazyRender: true,
        mode: 'local',
        store: new Ext.data.ArrayStore(\{
            id: 0,
            fields: \[
                'valueId',
                'displayName'
            \],
            data: \[[join $data ", "]\]
        \}),
        valueField: 'valueId',
        displayField: 'displayName',
        listClass: 'x-combo-list-small'
    \});"
}

ad_proc -public extjs::RowEditor::Editor {
    {-prefix:required}
    {-saveText "Update"}
    {-url:required}
    {-columnDef:required}
    {-baseParams:required}
    {-after_success ""}
} {
    Get the js for the editor plugin for the row editor. This also takes care of saving things back.
    
    @param url URL which handles the saving of the parameters. Each row entry field will be sent back to the URL as form attributes
    @param column_def Column Definition as a key value list {attribute_name datatype attribute_name datatype}. Usually it is a good thing to make the JS names match the JSON names match the acs_attribute_names.
    @param baseParams The base parameters you send to your -data.tcl. Usually this is at least the action (e.g. "get_json") and some ID or object_type. Example: [list action "get_json" object_id $object_id]    
    @param after_success This is JS code which is executed after the row has been successfully saved. This allows for code injection in additon to the standard saving
} {
    set params [list]
    foreach {attribute datatype} $columnDef {
        lappend params "$attribute: record.data.${attribute}"
    }

    foreach {key value} $baseParams {
        lappend params "$key: '$value'"
    }
    
    return "
    // Editor for row Level editing
    var ${prefix}editor = new Ext.ux.grid.RowEditor(\{
        saveText: '$saveText',
        resize: function() \{
            var row = Ext.fly(this.grid.getView().getRow(this.rowIndex)).getBottom();
            var lastRow = Ext.fly(this.grid.getView().getRow(this.grid.getStore().getCount()-1)).getBottom();
            var mainBody = this.grid.getView().mainBody;
            var h = Ext.max(\[row + this.btns.getHeight() + 10, lastRow\]) - mainBody.getTop();
            mainBody.setHeight(h,true);
        \},
        listeners: \{
            move: function(p)\{ this.resize(); \},
            hide: function(p)\{
                var mainBody = this.grid.getView().mainBody;
                var lastRow = Ext.fly(this.grid.getView().getRow(this.grid.getStore().getCount()-1));
                mainBody.setHeight(lastRow.getBottom() - mainBody.getTop(),\{
                    callback: function()\{ mainBody.setHeight('auto'); \}
                \});
            \},
            afterlayout: function(container, layout) \{ this.resize(); \},
            afteredit: \{
                fn:function(roweditor, changes, record, rowIndex)\{
                    Ext.Ajax.request(\{
                        waitMsg: 'Please wait...',
                        url: '$url',
                        params: \{ [join $params ",\n"] \},
                        success: function(response)\{
                            var result=eval(response.responseText);
                            switch(result)\{
                            case 1:
                                ${prefix}store.commitChanges();
                                ${prefix}store.reload();
                                $after_success
                                break;
                            default:
                                Ext.MessageBox.alert('Uh uh..', 'Probleme beim Speichern....');
                                break;
                            \}
                        \},
                        failure: function(response)\{
                            var result=response.responseText;
                            Ext.MessageBox.alert('error','could not connect to database');
                        \}
                    \});
                    
                \}
            \}
        \}
    \});
   "    
}

ad_proc -public extjs::RowEditor::GridPanel {
    {-prefix:required}
    {-autoExpandColumn ""}
    {-title ""}
    {-new_title ""}
    {-new_json ""}
    {-width "1000"}
} {
    Thid procedure returns the code for creating a GridPanel callen $prefix_grid. You need to add a div called ${prefix}_grid to your .adp file to show the Grid Panel on your page.
    
    @param prefix Prefix which is being used. This has to be the same consistently for the Grid as well as the Store and the Column Modell being used. Store ist called prefix_store and Column Modell is called prefix_cm
    
    @param autoExpandColumn Name of the column which autoexpands. Preferably the column with the title / name
    @param title Title of the Grid. Shows up on the top left corner
    @param new_title If provided and new_json ist not empty, add a "Add new" button for a new row.
    
} {

    set return_js "
    // create the editor grid
    var ${prefix}grid = new Ext.grid.GridPanel(\{
        store: ${prefix}store,
        cm: ${prefix}cm,
        renderTo: '${prefix}grid', // Name of the div
        width: '$width',
        region: 'center',
        autoExpandColumn: '$autoExpandColumn', // column with this id will be expanded
        autoScroll: true,
        autoHeight: true,
        plugins: \[${prefix}editor\], // The editor plugin for row level editing
        title: '$title',
        clicksToEdit: 1"

    if {$new_title ne "" && $new_json ne ""} {
        append return_js ",
        tbar: \[
            \{
                text: '$new_title',
                handler : function()\{
                    // access the Record constructor through the grid's store
                    var Cost = ${prefix}grid.getStore().recordType;
                    var p = new Cost($new_json);
                    ${prefix}editor.stopEditing();
    
                    // add the new record as the top row, select it
                    ${prefix}store.insert(0, p);
                    ${prefix}grid.getView().refresh();
                    ${prefix}grid.getSelectionModel().selectRow(0);

                    // Start editing again. Update should send it to the server
                    ${prefix}editor.startEditing(0, 0);
                \}
            \}
        \]
    "
    }
    append return_js "\});"

    
    return $return_js


}