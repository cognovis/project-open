--
-- Integrate mail with OpenACS
--
-- @author <a href="mailto:frank.bergmann@project-open.com">frank.bergmann@project-open.com</a>
-- @version $Id$
--

-- nothing...


-- Delete components and menus
select  im_component_plugin__del_module('intranet-mail-import');
select  im_menu__del_module('intranet-mail-import');

