--
-- Integrate mail with OpenACS
--
-- @author <a href="mailto:frank.bergmann@project-open.com">frank.bergmann@project-open.com</a>
-- @version $Id: intranet-mail-import-drop.sql,v 1.2 2005/08/11 18:47:05 cvs Exp $
--

-- nothing...


-- Delete components and menus
select  im_component_plugin__del_module('intranet-mail-import');
select  im_menu__del_module('intranet-mail-import');

