<style type="text/css">
    .yui-skin-sam .yui-dt td.up { 
        background-color: #efe; 
    } 
    .yui-skin-sam .yui-dt td.down { 
        background-color: #fee; 
    } 
</style>
<script type="text/javascript">
    
YAHOO.example.Data = {
	project_list: [
		@data_source;noquote@
	]
}

@days_planned_arr;noquote@
@available_days_cc_arr;noquote@

YAHOO.util.Event.addListener(window, "load", function() {
	YAHOO.example.Basic = function() {
        
		var oPushButton1 = new YAHOO.widget.Button("pushbutton1", { onclick: { fn: calculateTable } }); 
        var oPushButton2 = new YAHOO.widget.Button("pushbutton2", { onclick: { fn: postForm } });
        
		function calculateTable(p_oEvent) {
			setPrioAverage();			
			myDataTable.sortColumn(myDataTable.getColumn("project_priority"),"yui-dt-desc");
            myDataTable.reCalculate();	
		}

		function getValueCellEditor(label) {
            field = 'project_priority_op_id';
            var oColumn = myDataTable.getColumn(field),
            lookupTable = oColumn.lookupTable  || (oColumn.editor instanceof YAHOO.widget.DropdownCellEditor) && oColumn.editor.dropdownOptions;
            if (YAHOO.lang.isArray(lookupTable)) {
	            for (var i = 0; i < lookupTable.length;i++) {
					if (lookupTable[i].label == label) {
					    return lookupTable[i].value;
                    }
                };
				return label
            }
		}
        
        
        @editors_init;noquote@
        
		// ddEditor_project_priority_op_id.subscribe('saveEvent', editorSaveHandler);
		// ddEditor_project_priority_st_id.subscribe('saveEvent', editorSaveHandler);
        
		YAHOO.widget.DataTable.formatLookup = function(elCell, oRecord,	oColumn, oData) {
			var lookupTable = oColumn.lookupTable  || (oColumn.editor instanceof YAHOO.widget.DropdownCellEditor) && oColumn.editor.dropdownOptions;
			if (YAHOO.lang.isArray(lookupTable)) {
				for (var i = 0; i < lookupTable.length; i++) {
					if (lookupTable[i].value == oData) {
						elCell.innerHTML = lookupTable[i].label;
						return;
					}
				}
			}
			elCell.innerHTML = oData || ""; // if oData is null, show a blank.
		};
        
		function setPrioAverage() {
            var records = myDataTable.getRecordSet().getRecords();
            var record_ctr = 0;
            for (j=0; j < records.length; j++) {
                project_priority_value = parseInt(getValueCellEditor(myDataTable.getRecordSet().getRecord(record_ctr).getData('project_priority_op_id')));
			    project_priority_value += parseInt(getValueCellEditor(myDataTable.getRecordSet().getRecord(record_ctr).getData('project_priority_st_id')));
			    myDataTable.getRecordSet().getRecord(record_ctr).setData("project_priority", project_priority_value)
				record_ctr++;
            }
            
		}
        
        
		function postForm(p_oEvent) {
	        var records = myDataTable.getRecordSet().getRecords();
			var record_ctr = 0; 
			var project_priority = -1; 
			var project_id = -1;
			
            for (j=0; j < records.length; j++) {
         	    project_id = myDataTable.getRecordSet().getRecord(record_ctr).getData('project_id');
                project_priority_op_id = getValueCellEditor(myDataTable.getRecordSet().getRecord(record_ctr).getData('project_priority_op_id'));
                project_priority_st_id = getValueCellEditor(myDataTable.getRecordSet().getRecord(record_ctr).getData('project_priority_st_id'));
			    document.department_planner.innerHTML = document.department_planner.innerHTML + "<input type='hidden' name='project_priority_op_id." + project_id + "' value='" + project_priority_op_id + "'>";
			    document.department_planner.innerHTML = document.department_planner.innerHTML + "<input type='hidden' name='project_priority_st_id." + project_id + "' value='" + project_priority_st_id + "'>"; 
                record_ctr++;
                
            }
		    document.department_planner.innerHTML = document.department_planner.innerHTML + 
				"<input type='hidden' name='return_url' value='@return_url;noquote@'>";
			document.department_planner.submit();
		}
        
		var customDropdownSort = function(a, b, desc, field) { 
			field = field || 'project_priority';
			var oColumn = myDataTable.getColumn(field),
			lookupTable = oColumn.lookupTable  || (oColumn.editor instanceof YAHOO.widget.DropdownCellEditor) && oColumn.editor.dropdownOptions;
		    
			if (YAHOO.lang.isArray(lookupTable)) {
				var getLabel = function(value) {
					for (var i = 0; i < lookupTable.length;i++) {
						if (lookupTable[i].value == value) {
							return lookupTable[i].label;
						}					
					}
				};
				return YAHOO.util.Sort.compare(getLabel(a.getData(field)), getLabel(b.getData(field)), desc);
			} else {
				return YAHOO.util.Sort.compare(a.getData(field), b.getData(field), desc);
		    }
		};
        
        
        // Format the column red if the remaining hours are negative
        this.myCustomFormatter = function(elLiner, oRecord, oColumn, oData) { 
            if(oData < 0) { 
                YAHOO.util.Dom.replaceClass(elLiner.parentNode, "up", "down"); 
                elLiner.innerHTML = Math.round(oData*10)/10; 
            } 
            else { 
                YAHOO.util.Dom.replaceClass(elLiner.parentNode, "down","up"); 
                elLiner.innerHTML = Math.round(oData*10)/10;
            } 
        };         
        

	    // Add the custom formatter 
	    YAHOO.widget.DataTable.Formatter.myCustom = this.myCustomFormatter; 
        
		// add lookup 
		YAHOO.widget.DataTable.Formatter.lookup = YAHOO.widget.DataTable.formatLookup;
        
	    var myColumnDefs = [
			@column_defs;noquote@
	    ];
	    
	    var myDataSource = new YAHOO.util.DataSource(YAHOO.example.Data.project_list);
        
	    myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSARRAY;
	    myDataSource.responseSchema = {
			@response_schema;noquote@
	    };
	    
		var myDataTable = new YAHOO.widget.DataTable("basic", myColumnDefs, myDataSource, {caption:""});
	    
        
		myDataTable.on('cellClickEvent',function() {
			this.onEventShowCellEditor.apply(this,arguments);
 		});
        
        
        myDataTable.reCalculate = function() {
            
			// available_days_cc_arr shows how many days are available for each cc:  available_days_cc_arr [526, 30965]=2.0;
			// days_planned_arr shows number of days available for each cc: var days_planned_arr [526]=210;
            
			var i = 0; 
			var j = 0; 
			var days_left = 0;
			var recordKey = 0; 
			var record_ctr = 0;
			var days_planned_arr_backup = []; 
            
			// get all records
			var records = myDataTable.getRecordSet().getRecords();
            
			// for all cost centers found in cc_arr
			for (i in days_planned_arr) {
				// what CC ? 
				recordKey = "key_cc_" + i;
				
				// backup days_planned_arr
				days_planned_arr_backup[i] = days_planned_arr[i];
                
				for (j=0; j < records.length; j++) {
					// calculate new remaing days for this project   
					days_left = days_planned_arr[i] - window['available_days_cc_arr_'+ i +'_'+ myDataTable.getRecordSet().getRecord(record_ctr).getData('project_id')];
					// update available days in CC
					myDataTable.getRecordSet().updateRecordValue(record_ctr, recordKey, days_left);
					days_planned_arr[i] = days_left;
					record_ctr++;
				}
				record_ctr=0; 
				days_planned_arr[i] = days_planned_arr_backup[i];
			}
			myDataTable.refreshView();
		};
        
        @editors_conf;noquote@
	    
	    
		setPrioAverage();
        myDataTable.sortColumn(myDataTable.getColumn("project_priority"),"yui-dt-desc");
        myDataTable.reCalculate();
		myDataTable.hideColumn("project_id");
		myDataTable.hideColumn("project_priority");
	    return {
	        oDS: myDataSource,
	        oDT: myDataTable
	    };
	}();
});
document.getElementsByTagName('body')[0].className+='yui-skin-sam';

</script>

<br />
<br />
<form action="/intranet-budget/department-planner/save-ajax.tcl" name="department_planner" id="department_planner" method="post">
        <button type="button" id="pushbutton1" name="button1" value="Add">Calculate</button> 
        <button type="button" id="pushbutton2" name="button2" value="Add">Save</button> 
</form>
<br />
<br />

<div id="basic"></div>


<br>
<br>

<if "" ne @error_html@>
<br>
<h1>Errors</h1>
<ul>
@error_html;noquote@
</ul>
</if>

