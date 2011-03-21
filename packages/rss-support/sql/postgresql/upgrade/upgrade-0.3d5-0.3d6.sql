-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-02-15
-- @arch-tag: 0bbad9f6-cbcd-4d2f-b3c3-26191ffef798
-- @cvs-id $Id: upgrade-0.3d5-0.3d6.sql,v 1.2 2005/02/24 13:33:25 jeffd Exp $
--

select define_function_args ('rss_gen_subscr__new','p_subscr_id,p_impl_id,p_summary_context_id,p_timeout,p_lastbuild;now,p_object_type,p_creation_date;now,p_creation_user,p_creation_ip,p_context_id');