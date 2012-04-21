<master>
<property name="title">#intranet-core.Projects#</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<formtemplate id="@form_id@"></formtemplate>

<script type="text/javascript">
        var html_tag = document.getElementsByName('project_name')[0];
        html_tag.setAttribute('onBlur','set_project_path();');
function set_project_path() {
        // var tmp = document.getElementsByName('project_name')[0].value.replace(' ','_');
        var tmp = replaceSpaces(document.getElementsByName('project_name')[0].value);
        document.getElementsByName('project_path')[0].value = removeSpaces(tmp.replace(/[^a-zA-Z 0-9 _ ]+/g,'')).substring(0,29);
}
function removeSpaces(string) {
 return string.split(' ').join('');
}
function replaceSpaces(string) {
 return string.split(' ').join('_');
}
</script>
