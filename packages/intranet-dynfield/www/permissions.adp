<if 1 ne @nomaster_p@>
<master src="master">
<property name="context">@context_bar@</property>
<property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_dynfield</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
</if>

<script type="text/javascript">
        $(document).ready(function () {
            function hideCol($table, idx) {
				if (idx != 1 && idx != 2) {
				    $('td:nth-child(' + idx + '),th:nth-child(' + idx + ')').hide();
				}
            }
            function showCol($table, idx) {
                $('td:nth-child(' + idx + '),th:nth-child(' + idx + ')').show();
            }
            $("select").change(function () {
                var $table = $("#editable_table"),
                cols = $(this).val();
				if (cols != null) {
                   for (var i = 1; i <= $table.find("th").length; i++) {
                   	    if (cols.indexOf(i + '') === -1) {
                        	  hideCol($table, i);
                    	 }
                    	 else {
                        	  showCol($table, i);
                    	};
                   };
				} else {
                   for (var i = 1; i <= $table.find("th").length; i++) {
                         hideCol($table, i);
                   };
				};
            });
        });
</script>

@table;noquote@
