<?xml version="1.0"?>
<queryset>

    <fullquery name="acs_mail_lite::bouncing_email_p.bouncing_p">
      <querytext>

    	select case when email_bouncing_p = 't' then 1 else 0 end 
	as send_p 
      	from cc_users 
     	where lower(email) = lower(:email)

      </querytext>
    </fullquery>


    <fullquery name="acs_mail_lite::bouncing_user_p.bouncing_p">
      <querytext>

    	select case when email_bouncing_p = 't' then 1 else 0 end 
	as send_p 
      	from cc_users 
     	where user_id = :user_id

      </querytext>
    </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.record_mail_sent">
     <querytext>

       update acs_mail_lite_mail_log
       set last_mail_date = sysdate
       where user_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.insert_log_entry">
     <querytext>

       insert into acs_mail_lite_mail_log (user_id, last_mail_date)
       values (:user_id, sysdate)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::load_mail_dir.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where user_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::load_mail_dir.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (user_id, bounce_count)
       values (:user_id, 1)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_log_if_no_recent_bounce">
     <querytext>

       delete from acs_mail_lite_bounce
       where user_id in (select user_id
                         from acs_mail_lite_mail_log
                         where last_mail_date < sysdate - :max_days_to_bounce)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.disable_bouncing_email">
     <querytext>

       update users
       set email_bouncing_p = 't'
       where user_id in (select user_id
                         from acs_mail_lite_bounce
                         where bounce_count >= :max_bounce_count)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_bouncing_users_from_log">
     <querytext>

       delete from acs_mail_lite_bounce
       where bounce_count >= :max_bounce_count

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::get_address_array.get_user_name_and_id">
     <querytext>

       select	user_id, 
		im_name_from_user_id(user_id) as user_name
       from	cc_users
       where	email = :email

     </querytext>
   </fullquery>


    <fullquery name="acs_mail_lite::sweeper.delete_queue_entry">
        <querytext>
            delete
            from acs_mail_lite_queue
            where message_id = :message_id
        </querytext>
    </fullquery>

</queryset>
