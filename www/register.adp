<master src="master">
<property name="title">Register New User</property>

<h2>Register New User</h2>

<if @is_admin@ eq t>
  <b><font color="red">This user will be made a CMS administrator.</font></b>
</if>


<formtemplate id="register_user"></formtemplate>
