--
-- /packages/acs-kernel/sql/rel-constraints-drop.sql
-- 
-- @author Oumi Mehrotra
-- @creation-date 2000-11-22
-- @cvs-id $Id: rel-constraints-drop.sql,v 1.2 2010/10/19 20:11:34 po34demo Exp $


begin
acs_rel_type.drop_type('rel_constraint');
end;
/
show errors

drop view rel_constraints_violated_one;
drop view rel_constraints_violated_two;
drop view rc_required_rel_segments;
drop view rc_parties_in_required_segs;
drop view rc_violations_by_removing_rel;
drop table rel_constraints;
drop package rel_constraint;
