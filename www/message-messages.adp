<html>
<head>
<title>#intranet-contacts.Mail_Merge_Results#</title>
<link href="/resources/contacts/contacts.css" rel="stylesheet" media="screen" type="text/css">
<link href="/resources/contacts/contacts-print.css" rel="stylesheet" media="print" type="text/css">
</head>
<body>
<multiple name="messages">
<if @messages.message_type@ eq letter>
<div class="<if @messages.rownum@ eq @messages:rowcount@>#intranet-contacts.last#</if>letter">
@messages.content;noquote@
</div>
</if>	
<if @messages.message_type@ eq email>
<pre>
From:    @from@
To:      @messages.to@
Subject: @messages.subject@

@messages.content@
</pre>
<if @messages.rownum@ not eq @messages:rowcount@><br><br><br><hr /></if>
</if>
</multiple>
</body>

