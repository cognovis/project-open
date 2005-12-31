<master>
<property name=title>One Survey: @name;noquote@</property>
<property name="context">@context;noquote@</property>

    <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <form enctype=multipart/form-data method="post" action="process-response">
        <tr>
          <td class="tabledata">@description;noquote@</td>
        </tr>
        
        <tr>
          <td class="tabledata"><hr noshade size="1" color="#dddddd"></td>
        </tr>
        
        <tr>
          <td class="tabledata">
            <%= [export_form_vars survey_id] %>
            <include src=one_@display_type;noquote@ questions=@questions;noquote@>
            <hr noshapde size="1" color="#dddddd">
              <input type=submit value="Continue">
          </td>
        </tr>
        
      </form>
    </table>
