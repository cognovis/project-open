<if @message_type@ eq email>
<master src="/packages/intranet-contacts/lib/contact-master" />
<property name="party_id">@party_id@</property>
<property name="header_stuff">
  <link rel="stylesheet" type="text/css" href="/resources/contacts/contacts-print.css">
</property>

@content;noquote@


</if>
<else>
<html>
<head>
<title>#intranet-contacts.Print_Letter#</title>
<link rel="stylesheet" type="text/css" href="/resources/contacts/contacts-print.css">
</head>
<body>
<p style="padding: 2em;"><a href="@return_url@" style="padding: 2px; text-decoration: none; background-color: #EEE; border: 1px solid #CCC;">#intranet-contacts.Return_to_history#</a></p>

@content;noquote@

</body>
</html>

</else>


