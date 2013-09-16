<style>
.delete-button-client-pagination {
    cursor: pointer;
    background: transparent url(/intranet/images/navbar_default/delete.png) no-repeat center center;
}
</style>
<script type="text/javascript">

      // src: intranet-mail-import/www/js/client-pagination.adp
      YAHOO.util.Event.addListener(window, "load", function() {
        this.myCustomSubjFormatter = function(elLiner, oRecord, oColumn, oData) {
		elLiner.innerHTML = "<a href=\"/intranet-mail-import/mail-view?content_item_id=" + oRecord.getData("id") + "\" id=\"" + oRecord.getData("id") + "\">" + oData + "</a>";
		YAHOO.util.Event.addListener( oRecord.getData("id"), "click", interceptLink);
        };

	YAHOO.example.ClientPagination = function() {
        var myColumnDefs = [
            {key:"delete", label:"Delete", className:'delete-button-client-pagination'},
            {key:"id", label:"ID"},
            {key:"date", label:"Date", sortable: true},
            {key:"subject", label:"Subject", formatter:"myCustomSubj"},
            {key:"from", label:"From"},
            {key:"to", label:"To"}
        ];

        var myDataSource = new YAHOO.util.DataSource("/intranet-mail-import/get-mail-list?format=json&object_id=@object_id@&");
        myDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;

        myDataSource.responseSchema = {
            resultsList: "records",
            fields: ["id","date","subject","from","to"]
        };

        var oConfigs = {
                paginator: new YAHOO.widget.Paginator({
                    rowsPerPage: 15
                }),
                initialRequest: "results=1000"
        };

	YAHOO.widget.DataTable.Formatter.myCustomSubj = this.myCustomSubjFormatter;
	YAHOO.widget.DataTable.Formatter.myCustomRemove = this.myCustomRemoveFormatter;

        var myDataTable = new YAHOO.widget.DataTable("paginated", myColumnDefs, myDataSource, oConfigs);

	myDataTable.subscribe('cellClickEvent',myDataTable.onEventShowCellEditor);

        myDataTable.subscribe('cellClickEvent',function(oArgs) {
   		var target = oArgs.target;
		var column = myDataTable.getColumn(target);
		if (column.key == 'delete') {
		        if (confirm('Are you sure?')) {
			var record = this.getRecord(target);
		            myDataTable.deleteRow(target);
		            YAHOO.util.Connect.asyncRequest(
                		'GET',
		                '/intranet-mail-import/remove-mail-assignment?mail_id=' + record.getData('id') + '&object_id=<%=$object_id%>',
                		{
                                    success: function (o) {
                                            // this.deleteRow(target);
					    alert(o.responseText);
		                    },
                		    failure: function (o) {
		                        alert(o.responseText);
                		    },
		                    scope:this
                		}
            		  );
        		}
		} else {
		        myDataTable.onEventShowCellEditor(oArgs);
    		}
	});

     
        return {
            oDS: myDataSource,
            oDT: myDataTable
        };
    }();
});
		
</script>

