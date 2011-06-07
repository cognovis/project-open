<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">tickets</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>


<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="ticket"></formtemplate>

<script type="text/javascript">
        var html_tag = document.getElementsByName('project_name')[0];
        html_tag.setAttribute('onBlur','set_ticket_nr();');
function set_ticket_nr() {
        // var tmp = document.getElementsByName('project_name')[0].value.replace(' ','_');
        var tmp = replaceSpaces(document.getElementsByName('project_name')[0].value);
        document.getElementsByName('project_nr')[0].value = removeSpaces(tmp.replace(/[^a-zA-Z 0-9 _ ]+/g,'')).substring(0,29);
}
function removeSpaces(string) {
 return string.split(' ').join('');
}
function replaceSpaces(string) {
 return string.split(' ').join('_');
}
</script>

