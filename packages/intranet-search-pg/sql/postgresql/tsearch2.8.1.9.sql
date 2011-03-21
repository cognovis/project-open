-- Adjust this setting to control where the objects get CREATEd.
SET search_path = public;

BEGIN;

--dict conf
CREATE TABLE pg_ts_dict (
	dict_name	text not null primary key,
	dict_init	regprocedure,
	dict_initoption	text,
	dict_lexize	regprocedure not null,
	dict_comment	text
) with oids;

--dict interface
CREATE FUNCTION lexize(oid, text) 
	returns _text
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

CREATE FUNCTION lexize(text, text)
        returns _text
        as '$libdir/tsearch2', 'lexize_byname'
        language 'C'
        with (isstrict);

CREATE FUNCTION lexize(text)
        returns _text
        as '$libdir/tsearch2', 'lexize_bycurrent'
        language 'C'
        with (isstrict);

CREATE FUNCTION set_curdict(int)
	returns void
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

CREATE FUNCTION set_curdict(text)
	returns void
	as '$libdir/tsearch2', 'set_curdict_byname'
	language 'C'
	with (isstrict);

--built-in dictionaries
CREATE FUNCTION dex_init(internal)
	returns internal
	as '$libdir/tsearch2' 
	language 'C';

CREATE FUNCTION dex_lexize(internal,internal,int4)
	returns internal
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

insert into pg_ts_dict select 
	'simple', 
	'dex_init(internal)',
	null,
	'dex_lexize(internal,internal,int4)',
	'Simple example of dictionary.'
;
	 
CREATE FUNCTION snb_en_init(internal)
	returns internal
	as '$libdir/tsearch2' 
	language 'C';

CREATE FUNCTION snb_lexize(internal,internal,int4)
	returns internal
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

insert into pg_ts_dict select 
	'en_stem', 
	'snb_en_init(internal)',
	'contrib/english.stop',
	'snb_lexize(internal,internal,int4)',
	'English Stemmer. Snowball.'
;

CREATE FUNCTION snb_ru_init(internal)
	returns internal
	as '$libdir/tsearch2' 
	language 'C';

insert into pg_ts_dict select 
	'ru_stem', 
	'snb_ru_init(internal)',
	'contrib/russian.stop',
	'snb_lexize(internal,internal,int4)',
	'Russian Stemmer. Snowball.'
;
	 
CREATE FUNCTION spell_init(internal)
	returns internal
	as '$libdir/tsearch2' 
	language 'C';

CREATE FUNCTION spell_lexize(internal,internal,int4)
	returns internal
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

insert into pg_ts_dict select 
	'ispell_template', 
	'spell_init(internal)',
	null,
	'spell_lexize(internal,internal,int4)',
	'ISpell interface. Must have .dict and .aff files'
;

CREATE FUNCTION syn_init(internal)
	returns internal
	as '$libdir/tsearch2' 
	language 'C';

CREATE FUNCTION syn_lexize(internal,internal,int4)
	returns internal
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

insert into pg_ts_dict select 
	'synonym', 
	'syn_init(internal)',
	null,
	'syn_lexize(internal,internal,int4)',
	'Example of synonym dictionary'
;

--dict conf
CREATE TABLE pg_ts_parser (
	prs_name	text not null primary key,
	prs_start	regprocedure not null,
	prs_nexttoken	regprocedure not null,
	prs_end		regprocedure not null,
	prs_headline	regprocedure not null,
	prs_lextype	regprocedure not null,
	prs_comment	text
) with oids;

--sql-level interface
CREATE TYPE tokentype 
	as (tokid int4, alias text, descr text); 

CREATE FUNCTION token_type(int4)
	returns setof tokentype
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

CREATE FUNCTION token_type(text)
	returns setof tokentype
	as '$libdir/tsearch2', 'token_type_byname'
	language 'C'
	with (isstrict);

CREATE FUNCTION token_type()
	returns setof tokentype
	as '$libdir/tsearch2', 'token_type_current'
	language 'C'
	with (isstrict);

CREATE FUNCTION set_curprs(int)
	returns void
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

CREATE FUNCTION set_curprs(text)
	returns void
	as '$libdir/tsearch2', 'set_curprs_byname'
	language 'C'
	with (isstrict);

CREATE TYPE tokenout 
	as (tokid int4, token text);

CREATE FUNCTION parse(oid,text)
	returns setof tokenout
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);
 
CREATE FUNCTION parse(text,text)
	returns setof tokenout
	as '$libdir/tsearch2', 'parse_byname'
	language 'C'
	with (isstrict);
 
CREATE FUNCTION parse(text)
	returns setof tokenout
	as '$libdir/tsearch2', 'parse_current'
	language 'C'
	with (isstrict);
 
--default parser
CREATE FUNCTION prsd_start(internal,int4)
	returns internal
	as '$libdir/tsearch2'
	language 'C';

CREATE FUNCTION prsd_getlexeme(internal,internal,internal)
	returns int4
	as '$libdir/tsearch2'
	language 'C';

CREATE FUNCTION prsd_end(internal)
	returns void
	as '$libdir/tsearch2'
	language 'C';

CREATE FUNCTION prsd_lextype(internal)
	returns internal
	as '$libdir/tsearch2'
	language 'C';

CREATE FUNCTION prsd_headline(internal,internal,internal)
	returns internal
	as '$libdir/tsearch2'
	language 'C';

insert into pg_ts_parser select
	'default',
	'prsd_start(internal,int4)',
	'prsd_getlexeme(internal,internal,internal)',
	'prsd_end(internal)',
	'prsd_headline(internal,internal,internal)',
	'prsd_lextype(internal)',
	'Parser from OpenFTS v0.34'
;	

--tsearch config

CREATE TABLE pg_ts_cfg (
	ts_name		text not null primary key,
	prs_name	text not null,
	locale		text
) with oids;

CREATE TABLE pg_ts_cfgmap (
	ts_name		text not null,
	tok_alias	text not null,
	dict_name	text[],
	primary key (ts_name,tok_alias)
) with oids;

CREATE FUNCTION set_curcfg(int)
	returns void
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

CREATE FUNCTION set_curcfg(text)
	returns void
	as '$libdir/tsearch2', 'set_curcfg_byname'
	language 'C'
	with (isstrict);

CREATE FUNCTION show_curcfg()
	returns oid
	as '$libdir/tsearch2'
	language 'C'
	with (isstrict);

insert into pg_ts_cfg values ('default', 'default','C');
insert into pg_ts_cfg values ('default_russian', 'default','ru_RU.KOI8-R');
insert into pg_ts_cfg values ('simple', 'default');

insert into pg_ts_cfgmap values ('default', 'lword', '{en_stem}');
insert into pg_ts_cfgmap values ('default', 'nlword', '{simple}');
insert into pg_ts_cfgmap values ('default', 'word', '{simple}');
insert into pg_ts_cfgmap values ('default', 'email', '{simple}');
insert into pg_ts_cfgmap values ('default', 'url', '{simple}');
insert into pg_ts_cfgmap values ('default', 'host', '{simple}');
insert into pg_ts_cfgmap values ('default', 'sfloat', '{simple}');
insert into pg_ts_cfgmap values ('default', 'version', '{simple}');
insert into pg_ts_cfgmap values ('default', 'part_hword', '{simple}');
insert into pg_ts_cfgmap values ('default', 'nlpart_hword', '{simple}');
insert into pg_ts_cfgmap values ('default', 'lpart_hword', '{en_stem}');
insert into pg_ts_cfgmap values ('default', 'hword', '{simple}');
insert into pg_ts_cfgmap values ('default', 'lhword', '{en_stem}');
insert into pg_ts_cfgmap values ('default', 'nlhword', '{simple}');
insert into pg_ts_cfgmap values ('default', 'uri', '{simple}');
insert into pg_ts_cfgmap values ('default', 'file', '{simple}');
insert into pg_ts_cfgmap values ('default', 'float', '{simple}');
insert into pg_ts_cfgmap values ('default', 'int', '{simple}');
insert into pg_ts_cfgmap values ('default', 'uint', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'lword', '{en_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'nlword', '{ru_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'word', '{ru_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'email', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'url', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'host', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'sfloat', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'version', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'part_hword', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'nlpart_hword', '{ru_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'lpart_hword', '{en_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'hword', '{ru_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'lhword', '{en_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'nlhword', '{ru_stem}');
insert into pg_ts_cfgmap values ('default_russian', 'uri', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'file', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'float', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'int', '{simple}');
insert into pg_ts_cfgmap values ('default_russian', 'uint', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'lword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'nlword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'word', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'email', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'url', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'host', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'sfloat', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'version', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'part_hword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'nlpart_hword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'lpart_hword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'hword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'lhword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'nlhword', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'uri', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'file', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'float', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'int', '{simple}');
insert into pg_ts_cfgmap values ('simple', 'uint', '{simple}');

--tsvector type
CREATE FUNCTION tsvector_in(cstring)
RETURNS tsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE FUNCTION tsvector_out(tsvector)
RETURNS cstring
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE TYPE tsvector (
        INTERNALLENGTH = -1,
        INPUT = tsvector_in,
        OUTPUT = tsvector_out,
        STORAGE = extended
);

CREATE FUNCTION length(tsvector)
RETURNS int4
AS '$libdir/tsearch2', 'tsvector_length'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION to_tsvector(oid, text)
RETURNS tsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION to_tsvector(text, text)
RETURNS tsvector
AS '$libdir/tsearch2', 'to_tsvector_name'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION to_tsvector(text)
RETURNS tsvector
AS '$libdir/tsearch2', 'to_tsvector_current'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION strip(tsvector)
RETURNS tsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION setweight(tsvector,"char")
RETURNS tsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE FUNCTION concat(tsvector,tsvector)
RETURNS tsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict,iscachable);

CREATE OPERATOR || (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = concat
);

--query type
CREATE FUNCTION tsquery_in(cstring)
RETURNS tsquery
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE FUNCTION tsquery_out(tsquery)
RETURNS cstring
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE TYPE tsquery (
        INTERNALLENGTH = -1,
        INPUT = tsquery_in,
        OUTPUT = tsquery_out
);

CREATE FUNCTION querytree(tsquery)
RETURNS text
AS '$libdir/tsearch2', 'tsquerytree'
LANGUAGE 'C' with (isstrict);

CREATE FUNCTION to_tsquery(oid, text)
RETURNS tsquery
AS '$libdir/tsearch2'
LANGUAGE 'c' with (isstrict,iscachable);

CREATE FUNCTION to_tsquery(text, text)
RETURNS tsquery
AS '$libdir/tsearch2','to_tsquery_name'
LANGUAGE 'c' with (isstrict,iscachable);

CREATE FUNCTION to_tsquery(text)
RETURNS tsquery
AS '$libdir/tsearch2','to_tsquery_current'
LANGUAGE 'c' with (isstrict,iscachable);

--operations
CREATE FUNCTION exectsq(tsvector, tsquery)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict, iscachable);
  
COMMENT ON FUNCTION exectsq(tsvector, tsquery) IS 'boolean operation with text index';

CREATE FUNCTION rexectsq(tsquery, tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict, iscachable);

COMMENT ON FUNCTION rexectsq(tsquery, tsvector) IS 'boolean operation with text index';

CREATE OPERATOR @@ (
        LEFTARG = tsvector,
        RIGHTARG = tsquery,
        PROCEDURE = exectsq,
        COMMUTATOR = '@@',
        RESTRICT = contsel,
        JOIN = contjoinsel
);
CREATE OPERATOR @@ (
        LEFTARG = tsquery,
        RIGHTARG = tsvector,
        PROCEDURE = rexectsq,
        COMMUTATOR = '@@',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

--Trigger
CREATE FUNCTION tsearch2()
RETURNS trigger
AS '$libdir/tsearch2'
LANGUAGE 'C';

--Relevation
CREATE FUNCTION rank(float4[], tsvector, tsquery)
RETURNS float4
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank(float4[], tsvector, tsquery, int4)
RETURNS float4
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank(tsvector, tsquery)
RETURNS float4
AS '$libdir/tsearch2', 'rank_def'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank(tsvector, tsquery, int4)
RETURNS float4
AS '$libdir/tsearch2', 'rank_def'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank_cd(int4, tsvector, tsquery)
RETURNS float4
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank_cd(int4, tsvector, tsquery, int4)
RETURNS float4
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank_cd(tsvector, tsquery)
RETURNS float4
AS '$libdir/tsearch2', 'rank_cd_def'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION rank_cd(tsvector, tsquery, int4)
RETURNS float4
AS '$libdir/tsearch2', 'rank_cd_def'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(oid, text, tsquery, text)
RETURNS text
AS '$libdir/tsearch2', 'headline'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(oid, text, tsquery)
RETURNS text
AS '$libdir/tsearch2', 'headline'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(text, text, tsquery, text)
RETURNS text
AS '$libdir/tsearch2', 'headline_byname'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(text, text, tsquery)
RETURNS text
AS '$libdir/tsearch2', 'headline_byname'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(text, tsquery, text)
RETURNS text
AS '$libdir/tsearch2', 'headline_current'
LANGUAGE 'C' WITH (isstrict, iscachable);

CREATE FUNCTION headline(text, tsquery)
RETURNS text
AS '$libdir/tsearch2', 'headline_current'
LANGUAGE 'C' WITH (isstrict, iscachable);

--GiST
--GiST key type 
CREATE FUNCTION gtsvector_in(cstring)
RETURNS gtsvector
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE FUNCTION gtsvector_out(gtsvector)
RETURNS cstring
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE TYPE gtsvector (
        INTERNALLENGTH = -1,
        INPUT = gtsvector_in,
        OUTPUT = gtsvector_out
);

-- support FUNCTIONs
CREATE FUNCTION gtsvector_consistent(gtsvector,internal,int4)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C';
  
CREATE FUNCTION gtsvector_compress(internal)
RETURNS internal
AS '$libdir/tsearch2'
LANGUAGE 'C';

CREATE FUNCTION gtsvector_decompress(internal)
RETURNS internal
AS '$libdir/tsearch2'
LANGUAGE 'C';

CREATE FUNCTION gtsvector_penalty(internal,internal,internal)
RETURNS internal
AS '$libdir/tsearch2'
LANGUAGE 'C' with (isstrict);

CREATE FUNCTION gtsvector_picksplit(internal, internal)
RETURNS internal
AS '$libdir/tsearch2'
LANGUAGE 'C';

CREATE FUNCTION gtsvector_union(internal, internal)
RETURNS _int4
AS '$libdir/tsearch2'
LANGUAGE 'C';

CREATE FUNCTION gtsvector_same(gtsvector, gtsvector, internal)
RETURNS internal
AS '$libdir/tsearch2'
LANGUAGE 'C';

-- CREATE the OPERATOR class
CREATE OPERATOR CLASS gist_tsvector_ops
DEFAULT FOR TYPE tsvector USING gist
AS
        OPERATOR        1       @@ (tsvector, tsquery)  RECHECK ,
        FUNCTION        1       gtsvector_consistent (gtsvector, internal, int4),
        FUNCTION        2       gtsvector_union (internal, internal),
        FUNCTION        3       gtsvector_compress (internal),
        FUNCTION        4       gtsvector_decompress (internal),
        FUNCTION        5       gtsvector_penalty (internal, internal, internal),
        FUNCTION        6       gtsvector_picksplit (internal, internal),
        FUNCTION        7       gtsvector_same (gtsvector, gtsvector, internal),
        STORAGE         gtsvector;


--stat info
CREATE TYPE statinfo 
	as (word text, ndoc int4, nentry int4);

--CREATE FUNCTION tsstat_in(cstring)
--RETURNS tsstat
--AS '$libdir/tsearch2'
--LANGUAGE 'C' with (isstrict);
--
--CREATE FUNCTION tsstat_out(tsstat)
--RETURNS cstring
--AS '$libdir/tsearch2'
--LANGUAGE 'C' with (isstrict);
--
--CREATE TYPE tsstat (
--        INTERNALLENGTH = -1,
--        INPUT = tsstat_in,
--        OUTPUT = tsstat_out,
--        STORAGE = plain
--);
--
--CREATE FUNCTION ts_accum(tsstat,tsvector)
--RETURNS tsstat
--AS '$libdir/tsearch2'
--LANGUAGE 'C' with (isstrict);
--
--CREATE FUNCTION ts_accum_finish(tsstat)
--	returns setof statinfo
--	as '$libdir/tsearch2'
--	language 'C'
--	with (isstrict);
--
--CREATE AGGREGATE stat (
--	BASETYPE=tsvector,
--	SFUNC=ts_accum,
--	STYPE=tsstat,
--	FINALFUNC = ts_accum_finish,
--	initcond = ''
--); 

CREATE FUNCTION stat(text)
	returns setof statinfo
	as '$libdir/tsearch2', 'ts_stat'
	language 'C'
	with (isstrict);

CREATE FUNCTION stat(text,text)
	returns setof statinfo
	as '$libdir/tsearch2', 'ts_stat'
	language 'C'
	with (isstrict);

--reset - just for debuging
CREATE FUNCTION reset_tsearch()
        returns void
        as '$libdir/tsearch2'
        language 'C'
        with (isstrict);

--get cover (debug for rank_cd)
CREATE FUNCTION get_covers(tsvector,tsquery)
        returns text
        as '$libdir/tsearch2'
        language 'C'
        with (isstrict);

--debug function
create type tsdebug as (
        ts_name text,
        tok_type text,
        description text,
        token   text,
        dict_name text[],
        "tsvector" tsvector
);

create function _get_parser_from_curcfg() 
returns text as 
' select prs_name from pg_ts_cfg where oid = show_curcfg() '
language 'SQL' with(isstrict,iscachable);

create function ts_debug(text)
returns setof tsdebug as '
select 
        m.ts_name,
        t.alias as tok_type,
        t.descr as description,
        p.token,
        m.dict_name,
        strip(to_tsvector(p.token)) as tsvector
from
        parse( _get_parser_from_curcfg(), $1 ) as p,
        token_type() as t,
        pg_ts_cfgmap as m,
        pg_ts_cfg as c
where
        t.tokid=p.tokid and
        t.alias = m.tok_alias and 
        m.ts_name=c.ts_name and 
        c.oid=show_curcfg() 
' language 'SQL' with(isstrict);

--compare functions
CREATE FUNCTION tsvector_cmp(tsvector,tsvector)
RETURNS int4
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);

CREATE FUNCTION tsvector_lt(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);

CREATE FUNCTION tsvector_le(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);
        
CREATE FUNCTION tsvector_eq(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);

CREATE FUNCTION tsvector_ge(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);
        
CREATE FUNCTION tsvector_gt(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);

CREATE FUNCTION tsvector_ne(tsvector,tsvector)
RETURNS bool
AS '$libdir/tsearch2'
LANGUAGE 'C' WITH (isstrict,iscachable);

CREATE OPERATOR < (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_lt,
        COMMUTATOR = '>',
        NEGATOR = '>=',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE OPERATOR <= (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_le,
        COMMUTATOR = '>=',
        NEGATOR = '>',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE OPERATOR >= (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_ge,
        COMMUTATOR = '<=',
        NEGATOR = '<',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE OPERATOR > (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_gt,
        COMMUTATOR = '<',
        NEGATOR = '<=',
        RESTRICT = contsel,
        JOIN = contjoinsel
);

CREATE OPERATOR = (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_eq,
        COMMUTATOR = '=',
        NEGATOR = '<>',
        RESTRICT = eqsel,
        JOIN = eqjoinsel,
        SORT1 = '<',
        SORT2 = '<'
);

CREATE OPERATOR <> (
        LEFTARG = tsvector,
        RIGHTARG = tsvector,
        PROCEDURE = tsvector_ne,
        COMMUTATOR = '<>',
        NEGATOR = '=',
        RESTRICT = neqsel,
        JOIN = neqjoinsel
);

CREATE OPERATOR CLASS tsvector_ops
    DEFAULT FOR TYPE tsvector USING btree AS
        OPERATOR        1       < ,
        OPERATOR        2       <= , 
        OPERATOR        3       = ,
        OPERATOR        4       >= ,
        OPERATOR        5       > ,
        FUNCTION        1       tsvector_cmp(tsvector, tsvector);

--example of ISpell dictionary
--update pg_ts_dict set dict_initoption='DictFile="/usr/local/share/ispell/russian.dict" ,AffFile ="/usr/local/share/ispell/russian.aff", StopFile="/usr/local/share/ispell/russian.stop"' where dict_name='ispell_template';
--example of synonym dict
--update pg_ts_dict set dict_initoption='/usr/local/share/ispell/english.syn' where dict_id=5;
END;
