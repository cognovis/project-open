-- upgrade-3.4.0.3.1-3.4.0.3.2.sql

-- Rename Authentication in "LDAP Authentication"
-- for its main purpose
--
update im_menus
set name = 'LDAP Authentication'
where label = 'openacs_auth';

