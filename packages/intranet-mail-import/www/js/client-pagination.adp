<script type="text/javascript">
      // src: intranet-mail-import/www/js/client-pagination.adp
      YAHOO.util.Event.addListener(window, "load", function() {
        this.myCustomFormatter = function(elLiner, oRecord, oColumn, oData) {
		elLiner.innerHTML = "<a href=\"/intranet-mail-import/mail-view?content_item_id=" + oRecord.getData("id") + "\" id=\"" + oRecord.getData("id") + "\">" + oData + "</a>";
		YAHOO.util.Event.addListener( oRecord.getData("id"), "click", interceptLink);
        };

	YAHOO.example.ClientPagination = function() {
        var myColumnDefs = [
            {key:"id", label:"ID"},
            {key:"date", label:"Date", sortable: true},
            {key:"subject", label:"Subject", formatter:"myCustom"},
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

	YAHOO.widget.DataTable.Formatter.myCustom = this.myCustomFormatter;
        var myDataTable = new YAHOO.widget.DataTable("paginated", myColumnDefs, myDataSource, oConfigs);
             
        return {
            oDS: myDataSource,
            oDT: myDataTable
        };
    }();
});
		
</script>

