-- upgrade-0.5d6-0.5d7.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d6-0.5d7.sql','');



-- Add more html tags in the acs-kernel parameter
CREATE OR REPLACE FUNCTION inline_0 ()
RETURN integer AS '
BEGIN

	UPDATE apm_parameter_values SET attr_value = ''A ADDRESS B BLOCKQUOTE BR CODE DIV DD DL DT EM FONT HR I LI OL P PRE SPAN STRIKE STRONG SUB SUP TABLE TBODY TD TR TT U UL EMAIL FIRST_NAMES LAST_NAME GROUP_NAME H1 H2 H3 H4 H5 H6'' WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = ''AllowedTag'');

	UPDATE apm_parameter_values SET attr_value = ''align alt border cellpadding cellspacing color face height href hspace id name size src style target title valign vspace width'' WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = ''AllowedAttribute'');

	UPDATE apm_parameter_values SET attr_value = 1 WHERE parameter_id = (SELECT parameter_id FROM apm_parameters WHERE parameter_name = ''UseHtmlAreaForRichtextP'');

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();