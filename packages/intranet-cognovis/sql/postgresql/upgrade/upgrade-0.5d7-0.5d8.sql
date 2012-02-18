-- 
-- packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d7-0.5d8.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2011-03-31
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d7-0.5d8.sql','');

update im_view_columns set column_render_tcl = '"<nobr>$indent_html$gif_html<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a></nobr>"' where column_id = 91101;

update im_view_columns set column_render_tcl = '"<nobr>$indent_html$gif_html<a href=/intranet-cognovis/tasks/view?[export_url_vars project_id task_id return_url]>$task_name</a></nobr>"' where column_id = 91002;
