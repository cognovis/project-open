<!-- packages/intranet-mail-import/www/index.adp -->
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>

<H1>@page_title@</h1>

<ul>
<li><a href="imported-emails">List of users with imported mails</a>
<li><a href="missing-emails">List of emails that need to be defined</a>
<li><a href="blacklist">List of emails to ignore (Blacklist)</a>
</ul>

<br>

<h1><%=[lang::message::lookup "" intranet-mail-import.Title_Mail_Dispatcher "Mail Dispatcher"]%></h1>
<ul>
<li><a href="mail-dispatcher">Mail Dispatcher</a>
</ul>

