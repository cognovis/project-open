<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="context">{#acs-subsite.Log_In#}</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>

<include src="/packages/acs-subsite/lib/login" 
	return_url="@return_url;noquote@" 
	no_frame_p="1" 
	authority_id="@authority_id@" 
	username="@username;noquote@" 
	password_hash="@password_hash;noquote@" 
	time="@time;noquote@" 
	otp="@otp;noquote@" 
	otp_nr="@otp_nr@" 
	otp_enabled_p="@otp_enabled_p@" 
	otp_user_id="@otp_user_id;noquote@" 
	email="@email;noquote@" 
	&="__adp_properties"
>

