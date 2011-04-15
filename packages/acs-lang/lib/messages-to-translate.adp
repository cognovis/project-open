

<if @display_p@>
  <hr>

  <h3>#acs-lang.Translated_messages_on_this_page#</h3>
  <form action="/acs-lang/translation-edit" method="POST" name="form">
    <listtemplate name="messages"></listtemplate>
    <input type="hidden" name="locale" value="@locale;noquote@">
    <input type="hidden" name="return_url" value="@return_url;noquote@">
    <input type="submit" name="submit" value="Translate All">
   </form>
</if>



