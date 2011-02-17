<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">@main_navbar_label@</property>

<form enctype="multipart/form-data" method=POST action="import-@object_type@.tcl">
<%= [export_form_vars object_type return_url import_filename] %>

     <table>
     <tr clas=rowtitle>
     <td class=rowtitle>Field Name</td>
     <td class=rowtitle>Row 1</td>
     <td class=rowtitle>Row 2</td>
     <td class=rowtitle>Mapping</td>
     <td class=rowtitle>Transformation</td>
     </tr>

     <multiple name=mapping>

     <if @mapping.rownum@ odd><tr class="list-odd"></if>
     <else><tr class="list-even"></else>

     <td>@mapping.field_name@ @mapping.column;noquote@</td>
     <td>@mapping.row_1@</td>
     <td>@mapping.row_2@</td>
     <td>@mapping.map;noquote@</td>
     <td>@mapping.parser;noquote@</td>
     </tr>
     </multiple>
     </table>

     <table>
     <tr>
     <td>Save Mapping as:</td>
     <td><input type=text name=mapping_name></td>
     </tr>
     <tr>
     <td></td>
     <td><input type=submit value="#intranet-csv-import.Import_CVS#"></td>
     </tr>
     </table>

</form>

