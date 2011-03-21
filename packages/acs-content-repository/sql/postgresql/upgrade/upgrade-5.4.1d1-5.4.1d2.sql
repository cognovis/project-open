-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2008-03-11
-- @cvs-id $Id: upgrade-5.4.1d1-5.4.1d2.sql,v 1.1 2008/03/11 14:22:49 daveb Exp $
--

select define_function_args('content_type__is_content_type','object_type'); 