<master>
<property name="title">Spam Administration</property>
<property name="context">@context;noquote@</property>

<h3>Spam Queue</h3>

<table cellspacing=3>

<tr bgcolor="#dddddd">
  <th>Subject</th>
  <th>Scheduled Delivery</th>
  <th>Total Recipients</th>
  <th>Approval</th>
</tr>

    <multiple name=spam_queue>
<tr bgcolor="#cccccc">
  <td><a href="spam-edit?spam_id=@spam_queue.spam_id@">@spam_queue.title@</a></td>
  <td>@spam_queue.wait_until@</td>
  <td align=center><a href="spam-show-users?spam_id=@spam_queue.spam_id@">@spam_queue.total_recipients@</a></td>
  <td align=center><if @spam_queue.admin_p@ eq t><a href="toggle-approval?spam_id=@spam_queue.spam_id@">@spam_queue.pretty_approved@</a></if><else>@spam_queue.pretty_approved@</else></td>
</tr>
    </multiple>

</table>


<form action="process-queue">
<input type=submit value="Process Queue Now">
</form>




<h3>Spam Already Sent</h3>

<table cellspacing=3>

<tr bgcolor="#cccccc">
  <th>Subject</th>
  <th>When Sent</th>
</tr>

    <multiple name=spam_sent>
<tr bgcolor="#cccccc">
  <td><a href="spam-view?spam_id=@spam_sent.spam_id@">@spam_sent.title@</a></td>
  <td>@spam_sent.send_date@</td>
</tr>
    </multiple>

</table>

