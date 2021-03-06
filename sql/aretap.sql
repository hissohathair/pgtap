\unset ECHO
\i test_setup.sql

SELECT plan(280);
--SELECT * FROM no_plan();

-- This will be rolled back. :-)
SET client_min_messages = warning;

CREATE TABLE public.fou(
    id    INT NOT NULL PRIMARY KEY,
    name  TEXT DEFAULT '',
    numb  NUMERIC(10, 2),
    myint NUMERIC(8)
);
CREATE TABLE public.foo(
    id    INT NOT NULL PRIMARY KEY
);

CREATE RULE ins_me AS ON INSERT TO public.fou DO NOTHING;
CREATE RULE upd_me AS ON UPDATE TO public.fou DO NOTHING;

CREATE INDEX idx_fou_id ON public.fou(id);
CREATE INDEX idx_fou_name ON public.fou(name);

CREATE VIEW public.voo AS SELECT * FROM foo;
CREATE VIEW public.vou AS SELECT * FROM fou;

CREATE SEQUENCE public.someseq;
CREATE SEQUENCE public.sumeseq;

CREATE SCHEMA someschema;

CREATE FUNCTION someschema.yip() returns boolean as 'SELECT TRUE' language SQL;
CREATE FUNCTION someschema.yap() returns boolean as 'SELECT TRUE' language SQL;

CREATE DOMAIN public.goofy AS text CHECK ( TRUE );
CREATE OR REPLACE FUNCTION public.goofy_cmp(goofy,goofy)
RETURNS INTEGER AS $$
    SELECT CASE WHEN $1 = $2 THEN 0
                WHEN $1 > $2 THEN 1
                ELSE -1
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION public.goofy_eq (goofy, goofy) RETURNS boolean AS $$
    SELECT $1 = $2;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OPERATOR public.= ( PROCEDURE = goofy_eq, LEFTARG = goofy, RIGHTARG = goofy);

CREATE OPERATOR CLASS public.goofy_ops
DEFAULT FOR TYPE goofy USING BTREE AS
	OPERATOR 1 =,
	FUNCTION 1 goofy_cmp(goofy,goofy)
;

RESET client_min_messages;

/****************************************************************************/
-- Test tablespaces_are().

CREATE FUNCTION ___myts(ex text) RETURNS NAME[] AS $$
    SELECT ARRAY(
        SELECT spcname
          FROM pg_catalog.pg_tablespace
         WHERE spcname <> $1
    );
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    tablespaces_are( ___myts(''), 'whatever' ),
    true,
    'tablespaces_are(schemas, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    tablespaces_are( ___myts('') ),
    true,
    'tablespaces_are(schemas)',
    'There should be the correct tablespaces',
    ''
);

SELECT * FROM check_test(
    tablespaces_are( array_append(___myts(''), '__booya__'), 'whatever' ),
    false,
    'tablespaces_are(schemas, desc) missing',
    'whatever',
    '    Missing tablespaces:
        __booya__'
);

SELECT * FROM check_test(
    tablespaces_are( ___myts('pg_default'), 'whatever' ),
    false,
    'tablespaces_are(schemas, desc) extra',
    'whatever',
    '    Extra tablespaces:
        pg_default'
);

SELECT * FROM check_test(
    tablespaces_are( array_append(___myts('pg_default'), '__booya__'), 'whatever' ),
    false,
    'tablespaces_are(schemas, desc) extras and missing',
    'whatever',
    '    Extra tablespaces:
        pg_default
    Missing tablespaces:
        __booya__'
);

/****************************************************************************/
-- Test schemas_are().

CREATE FUNCTION ___mysch(ex text) RETURNS NAME[] AS $$
    SELECT ARRAY(
        SELECT nspname
          FROM pg_catalog.pg_namespace
         WHERE nspname NOT LIKE 'pg_%'
           AND nspname <> 'information_schema'
           AND nspname <> $1
    );
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    schemas_are( ___mysch(''), 'whatever' ),
    true,
    'schemas_are(schemas, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    schemas_are( ___mysch('') ),
    true,
    'schemas_are(schemas)',
    'There should be the correct schemas',
    ''
);

SELECT * FROM check_test(
    schemas_are( array_append(___mysch(''), '__howdy__'), 'whatever' ),
    false,
    'schemas_are(schemas, desc) missing',
    'whatever',
    '    Missing schemas:
        __howdy__'
);

SELECT * FROM check_test(
    schemas_are( ___mysch('someschema'), 'whatever' ),
    false,
    'schemas_are(schemas, desc) extras',
    'whatever',
    '    Extra schemas:
        someschema'
);

SELECT * FROM check_test(
    schemas_are( array_append(___mysch('someschema'), '__howdy__'), 'whatever' ),
    false,
    'schemas_are(schemas, desc) missing and extras',
    'whatever',
    '    Extra schemas:
        someschema
    Missing schemas:
        __howdy__'
);

/****************************************************************************/
-- Test tables_are().

SELECT * FROM check_test(
    tables_are( 'public', ARRAY['fou', 'foo'], 'whatever' ),
    true,
    'tables_are(schema, tables, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    tables_are( 'public', ARRAY['fou', 'foo'] ),
    true,
    'tables_are(schema, tables)',
    'Schema public should have the correct tables',
    ''
);

SELECT * FROM check_test(
    tables_are( ARRAY['fou', 'foo'] ),
    true,
    'tables_are(tables)',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct tables',
    ''
);

SELECT * FROM check_test(
    tables_are( ARRAY['fou', 'foo'], 'whatever' ),
    true,
    'tables_are(tables, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    tables_are( 'public', ARRAY['fou', 'foo', 'bar'] ),
    false,
    'tables_are(schema, tables) missing',
    'Schema public should have the correct tables',
    '    Missing tables:
        bar'
);

SELECT * FROM check_test(
    tables_are( ARRAY['fou', 'foo', 'bar'] ),
    false,
    'tables_are(tables) missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct tables',
    '    Missing tables:
        bar'
);

SELECT * FROM check_test(
    tables_are( 'public', ARRAY['fou'] ),
    false,
    'tables_are(schema, tables) extra',
    'Schema public should have the correct tables',
    '    Extra tables:
        foo'
);

SELECT * FROM check_test(
    tables_are( ARRAY['fou'] ),
    false,
    'tables_are(tables) extra',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct tables',
    '    Extra tables:
        foo'
);

SELECT * FROM check_test(
    tables_are( 'public', ARRAY['bar', 'baz'] ),
    false,
    'tables_are(schema, tables) extra and missing',
    'Schema public should have the correct tables',
    '    Extra tables:
        fo[ou]
        fo[ou]
    Missing tables:
        ba[rz]
        ba[rz]',
    true
);

SELECT * FROM check_test(
    tables_are( ARRAY['bar', 'baz'] ),
    false,
    'tables_are(tables) extra and missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct tables',
    '    Extra tables:' || '
        fo[ou]
        fo[ou]
    Missing tables:' || '
        ba[rz]
        ba[rz]',
    true
);

/****************************************************************************/
-- Test views_are().
SELECT * FROM check_test(
    views_are( 'public', ARRAY['vou', 'voo'], 'whatever' ),
    true,
    'views_are(schema, views, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    views_are( 'public', ARRAY['vou', 'voo'] ),
    true,
    'views_are(schema, views)',
    'Schema public should have the correct views',
    ''
);

SELECT * FROM check_test(
    views_are( ARRAY['vou', 'voo'] ),
    true,
    'views_are(views)',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct views',
    ''
);

SELECT * FROM check_test(
    views_are( ARRAY['vou', 'voo'], 'whatever' ),
    true,
    'views_are(views, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    views_are( 'public', ARRAY['vou', 'voo', 'bar'] ),
    false,
    'views_are(schema, views) missing',
    'Schema public should have the correct views',
    '    Missing views:
        bar'
);

SELECT * FROM check_test(
    views_are( ARRAY['vou', 'voo', 'bar'] ),
    false,
    'views_are(views) missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct views',
    '    Missing views:
        bar'
);

SELECT * FROM check_test(
    views_are( 'public', ARRAY['vou'] ),
    false,
    'views_are(schema, views) extra',
    'Schema public should have the correct views',
    '    Extra views:
        voo'
);

SELECT * FROM check_test(
    views_are( ARRAY['vou'] ),
    false,
    'views_are(views) extra',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct views',
    '    Extra views:
        voo'
);

SELECT * FROM check_test(
    views_are( 'public', ARRAY['bar', 'baz'] ),
    false,
    'views_are(schema, views) extra and missing',
    'Schema public should have the correct views',
    '    Extra views:
        vo[ou]
        vo[ou]
    Missing views:
        ba[rz]
        ba[rz]',
    true
);

SELECT * FROM check_test(
    views_are( ARRAY['bar', 'baz'] ),
    false,
    'views_are(views) extra and missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct views',
    '    Extra views:' || '
        vo[ou]
        vo[ou]
    Missing views:' || '
        ba[rz]
        ba[rz]',
    true
);

/****************************************************************************/
-- Test sequences_are().
SELECT * FROM check_test(
    sequences_are( 'public', ARRAY['sumeseq', 'someseq'], 'whatever' ),
    true,
    'sequences_are(schema, sequences, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    sequences_are( 'public', ARRAY['sumeseq', 'someseq'] ),
    true,
    'sequences_are(schema, sequences)',
    'Schema public should have the correct sequences',
    ''
);

SELECT * FROM check_test(
    sequences_are( ARRAY['sumeseq', 'someseq'] ),
    true,
    'sequences_are(sequences)',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct sequences',
    ''
);

SELECT * FROM check_test(
    sequences_are( ARRAY['sumeseq', 'someseq'], 'whatever' ),
    true,
    'sequences_are(sequences, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    sequences_are( 'public', ARRAY['sumeseq', 'someseq', 'bar'] ),
    false,
    'sequences_are(schema, sequences) missing',
    'Schema public should have the correct sequences',
    '    Missing sequences:
        bar'
);

SELECT * FROM check_test(
    sequences_are( ARRAY['sumeseq', 'someseq', 'bar'] ),
    false,
    'sequences_are(sequences) missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct sequences',
    '    Missing sequences:
        bar'
);

SELECT * FROM check_test(
    sequences_are( 'public', ARRAY['sumeseq'] ),
    false,
    'sequences_are(schema, sequences) extra',
    'Schema public should have the correct sequences',
    '    Extra sequences:
        someseq'
);

SELECT * FROM check_test(
    sequences_are( ARRAY['sumeseq'] ),
    false,
    'sequences_are(sequences) extra',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct sequences',
    '    Extra sequences:
        someseq'
);

SELECT * FROM check_test(
    sequences_are( 'public', ARRAY['bar', 'baz'] ),
    false,
    'sequences_are(schema, sequences) extra and missing',
    'Schema public should have the correct sequences',
    '    Extra sequences:
        s[ou]meseq
        s[ou]meseq
    Missing sequences:
        ba[rz]
        ba[rz]',
    true
);

SELECT * FROM check_test(
    sequences_are( ARRAY['bar', 'baz'] ),
    false,
    'sequences_are(sequences) extra and missing',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct sequences',
    '    Extra sequences:' || '
        s[ou]meseq
        s[ou]meseq
    Missing sequences:' || '
        ba[rz]
        ba[rz]',
    true
);

/****************************************************************************/
-- Test functions_are().

SELECT * FROM check_test(
    functions_are( 'someschema', ARRAY['yip', 'yap'], 'whatever' ),
    true,
    'functions_are(schema, functions, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    functions_are( 'someschema', ARRAY['yip', 'yap'] ),
    true,
    'functions_are(schema, functions)',
    'Schema someschema should have the correct functions'
    ''
);

SELECT * FROM check_test(
    functions_are( 'someschema', ARRAY['yip', 'yap', 'yop'], 'whatever' ),
    false,
    'functions_are(schema, functions, desc) + missing',
    'whatever',
    '    Missing functions:
        yop'
);

SELECT * FROM check_test(
    functions_are( 'someschema', ARRAY['yip'], 'whatever' ),
    false,
    'functions_are(schema, functions, desc) + extra',
    'whatever',
    '    Extra functions:
        yap'
);

SELECT * FROM check_test(
    functions_are( 'someschema', ARRAY['yap', 'yop'], 'whatever' ),
    false,
    'functions_are(schema, functions, desc) + extra & missing',
    'whatever',
    '    Extra functions:
        yip
    Missing functions:
        yop'
);

CREATE FUNCTION ___myfunk(ex text) RETURNS NAME[] AS $$
    SELECT ARRAY(
        SELECT p.proname
          FROM pg_catalog.pg_namespace n
          JOIN pg_catalog.pg_proc p ON n.oid = p.pronamespace
         WHERE pg_catalog.pg_function_is_visible(p.oid)
           AND n.nspname <> 'pg_catalog'
           AND p.proname <> $1
    );
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    functions_are( ___myfunk(''), 'whatever' ),
    true,
    'functions_are(functions, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    functions_are( ___myfunk('') ),
    true,
    'functions_are(functions)',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct functions',
    ''
);

SELECT * FROM check_test(
    functions_are( array_append(___myfunk(''), '__booyah__'), 'whatever' ),
    false,
    'functions_are(functions, desc) + missing',
    'whatever',
    '    Missing functions:
        __booyah__'
);

SELECT * FROM check_test(
    functions_are( ___myfunk('check_test'), 'whatever' ),
    false,
    'functions_are(functions, desc) + extra',
    'whatever',
    '    Extra functions:
        check_test'
);

SELECT * FROM check_test(
    functions_are( array_append(___myfunk('check_test'), '__booyah__'), 'whatever' ),
    false,
    'functions_are(functions, desc) + extra & missing',
    'whatever',
    '    Extra functions:
        check_test
    Missing functions:
        __booyah__'
);

/****************************************************************************/
-- Test indexes_are().
SELECT * FROM check_test(
    indexes_are( 'public', 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey'], 'whatever' ),
    true,
    'indexes_are(schema, table, indexes, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    indexes_are( 'public', 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey'] ),
    true,
    'indexes_are(schema, table, indexes)',
    'Table public.fou should have the correct indexes',
    ''
);

SELECT * FROM check_test(
    indexes_are( 'public', 'fou', ARRAY['idx_fou_id', 'idx_fou_name'] ),
    false,
    'indexes_are(schema, table, indexes) + extra',
    'Table public.fou should have the correct indexes',
    '    Extra indexes:
        fou_pkey'
);

SELECT * FROM check_test(
    indexes_are( 'public', 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey', 'howdy'] ),
    false,
    'indexes_are(schema, table, indexes) + missing',
    'Table public.fou should have the correct indexes',
    '    Missing indexes:
        howdy'
);

SELECT * FROM check_test(
    indexes_are( 'public', 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'howdy'] ),
    false,
    'indexes_are(schema, table, indexes) + extra & missing',
    'Table public.fou should have the correct indexes',
    '    Extra indexes:
        fou_pkey
    Missing indexes:
        howdy'
);

SELECT * FROM check_test(
    indexes_are( 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey'], 'whatever' ),
    true,
    'indexes_are(table, indexes, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    indexes_are( 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey'] ),
    true,
    'indexes_are(table, indexes)',
    'Table fou should have the correct indexes',
    ''
);

SELECT * FROM check_test(
    indexes_are( 'fou', ARRAY['idx_fou_id', 'idx_fou_name'] ),
    false,
    'indexes_are(table, indexes) + extra',
    'Table fou should have the correct indexes',
    '    Extra indexes:
        fou_pkey'
);

SELECT * FROM check_test(
    indexes_are( 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'fou_pkey', 'howdy'] ),
    false,
    'indexes_are(table, indexes) + missing',
    'Table fou should have the correct indexes',
    '    Missing indexes:
        howdy'
);

SELECT * FROM check_test(
    indexes_are( 'fou', ARRAY['idx_fou_id', 'idx_fou_name', 'howdy'] ),
    false,
    'indexes_are(table, indexes) + extra & missing',
    'Table fou should have the correct indexes',
    '    Extra indexes:
        fou_pkey
    Missing indexes:
        howdy'
);

/****************************************************************************/
-- Test users_are().

CREATE FUNCTION ___myusers(ex text) RETURNS NAME[] AS $$
    SELECT COALESCE(ARRAY( SELECT usename FROM pg_catalog.pg_user WHERE usename <> $1 ), '{}'::name[]);;
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    users_are( ___myusers(''), 'whatever' ),
    true,
    'users_are(users, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    users_are( ___myusers('') ),
    true,
    'users_are(users)',
    'There should be the correct users',
    ''
);

SELECT * FROM check_test(
    users_are( array_append(___myusers(''), '__howdy__'), 'whatever' ),
    false,
    'users_are(users, desc) missing',
    'whatever',
    '    Missing users:
        __howdy__'
);

SELECT * FROM check_test(
    users_are( ___myusers(current_user), 'whatever' ),
    false,
    'users_are(users, desc) extras',
    'whatever',
    '    Extra users:
        ' || current_user
);

SELECT * FROM check_test(
    users_are( array_append(___myusers(current_user), '__howdy__'), 'whatever' ),
    false,
    'users_are(users, desc) missing and extras',
    'whatever',
    '    Extra users:
        ' || current_user || '
    Missing users:
        __howdy__'
);

/****************************************************************************/
-- Test groups_are().

CREATE GROUP meanies;
CREATE FUNCTION ___mygroups(ex text) RETURNS NAME[] AS $$
    SELECT COALESCE(ARRAY( SELECT groname FROM pg_catalog.pg_group WHERE groname <> $1 ), '{}'::name[]);;
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    groups_are( ___mygroups(''), 'whatever' ),
    true,
    'groups_are(groups, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    groups_are( ___mygroups('') ),
    true,
    'groups_are(groups)',
    'There should be the correct groups',
    ''
);

SELECT * FROM check_test(
    groups_are( array_append(___mygroups(''), '__howdy__'), 'whatever' ),
    false,
    'groups_are(groups, desc) missing',
    'whatever',
    '    Missing groups:
        __howdy__'
);

SELECT * FROM check_test(
    groups_are( ___mygroups('meanies'), 'whatever' ),
    false,
    'groups_are(groups, desc) extras',
    'whatever',
    '    Extra groups:
        meanies'
);

SELECT * FROM check_test(
    groups_are( array_append(___mygroups('meanies'), '__howdy__'), 'whatever' ),
    false,
    'groups_are(groups, desc) missing and extras',
    'whatever',
    '    Extra groups:
        meanies
    Missing groups:
        __howdy__'
);

/****************************************************************************/
-- Test languages_are().

CREATE FUNCTION ___mylangs(ex text) RETURNS NAME[] AS $$
    SELECT COALESCE(ARRAY( SELECT lanname FROM pg_catalog.pg_language WHERE lanispl AND lanname <> $1 ), '{}'::name[]);;
$$ LANGUAGE SQL;

SELECT * FROM check_test(
    languages_are( ___mylangs(''), 'whatever' ),
    true,
    'languages_are(languages, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    languages_are( ___mylangs('') ),
    true,
    'languages_are(languages)',
    'There should be the correct procedural languages',
    ''
);

SELECT * FROM check_test(
    languages_are( array_append(___mylangs(''), 'plomgwtf'), 'whatever' ),
    false,
    'languages_are(languages, desc) missing',
    'whatever',
    '    Missing languages:
        plomgwtf'
);

SELECT * FROM check_test(
    languages_are( ___mylangs('plpgsql'), 'whatever' ),
    false,
    'languages_are(languages, desc) extras',
    'whatever',
    '    Extra languages:
        plpgsql'
);

SELECT * FROM check_test(
    languages_are( array_append(___mylangs('plpgsql'), 'plomgwtf'), 'whatever' ),
    false,
    'languages_are(languages, desc) missing and extras',
    'whatever',
    '    Extra languages:
        plpgsql
    Missing languages:
        plomgwtf'
);

/****************************************************************************/
-- Test opclasses_are().

SELECT * FROM check_test(
    opclasses_are( 'public', ARRAY['goofy_ops'], 'whatever' ),
    true,
    'opclasses_are(schema, opclasses, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    opclasses_are( 'public', ARRAY['goofy_ops'] ),
    true,
    'opclasses_are(schema, opclasses)',
    'Schema public should have the correct operator classes'
    ''
);

SELECT * FROM check_test(
    opclasses_are( 'public', ARRAY['goofy_ops', 'yops'], 'whatever' ),
    false,
    'opclasses_are(schema, opclasses, desc) + missing',
    'whatever',
    '    Missing operator classes:
        yops'
);

SELECT * FROM check_test(
    opclasses_are( 'public', '{}'::name[], 'whatever' ),
    false,
    'opclasses_are(schema, opclasses, desc) + extra',
    'whatever',
    '    Extra operator classes:
        goofy_ops'
);

SELECT * FROM check_test(
    opclasses_are( 'public', ARRAY['yops'], 'whatever' ),
    false,
    'opclasses_are(schema, opclasses, desc) + extra & missing',
    'whatever',
    '    Extra operator classes:
        goofy_ops
    Missing operator classes:
        yops'
);

CREATE FUNCTION ___myopc(ex text) RETURNS NAME[] AS $$
    SELECT COALESCE(ARRAY(
        SELECT oc.opcname
          FROM pg_catalog.pg_opclass oc
          JOIN pg_catalog.pg_namespace n ON oc.opcnamespace = n.oid
         WHERE n.nspname <> 'pg_catalog'
           AND oc.opcname <> $1
           AND pg_catalog.pg_opclass_is_visible(oc.oid)
    ), '{}'::name[]);;
$$ LANGUAGE SQL;


SELECT * FROM check_test(
    opclasses_are( ___myopc('') ),
    true,
    'opclasses_are(opclasses)',
    'Search path ' || pg_catalog.current_setting('search_path') || ' should have the correct operator classes',
    ''
);

SELECT * FROM check_test(
    opclasses_are( array_append(___myopc(''), 'sillyops'), 'whatever' ),
    false,
    'opclasses_are(opclasses, desc) + missing',
    'whatever',
    '    Missing operator classes:
        sillyops'
);

SELECT * FROM check_test(
    opclasses_are( ___myopc('goofy_ops'), 'whatever' ),
    false,
    'opclasses_are(opclasses, desc) + extra',
    'whatever',
    '    Extra operator classes:
        goofy_ops'
);

SELECT * FROM check_test(
    opclasses_are( array_append(___myopc('goofy_ops'), 'sillyops'), 'whatever' ),
    false,
    'opclasses_are(opclasses, desc) + extra & missing',
    'whatever',
    '    Extra operator classes:
        goofy_ops
    Missing operator classes:
        sillyops'
);

/****************************************************************************/
-- Test rules_are().
SELECT * FROM check_test(
    rules_are( 'public', 'fou', ARRAY['ins_me', 'upd_me'], 'whatever' ),
    true,
    'rules_are(schema, table, rules, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    rules_are( 'public', 'fou', ARRAY['ins_me', 'upd_me'] ),
    true,
    'rules_are(schema, table, rules)',
    'Relation public.fou should have the correct rules',
    ''
);

SELECT * FROM check_test(
    rules_are( 'public', 'fou', ARRAY['ins_me'] ),
    false,
    'rules_are(schema, table, rules) + extra',
    'Relation public.fou should have the correct rules',
    '    Extra rules:
        upd_me'
);

SELECT * FROM check_test(
    rules_are( 'public', 'fou', ARRAY['ins_me', 'upd_me', 'del_me'] ),
    false,
    'rules_are(schema, table, rules) + missing',
    'Relation public.fou should have the correct rules',
    '    Missing rules:
        del_me'
);

SELECT * FROM check_test(
    rules_are( 'public', 'fou', ARRAY['ins_me', 'del_me'] ),
    false,
    'rules_are(schema, table, rules) + extra & missing',
    'Relation public.fou should have the correct rules',
    '    Extra rules:
        upd_me
    Missing rules:
        del_me'
);

SELECT * FROM check_test(
    rules_are( 'fou', ARRAY['ins_me', 'upd_me'], 'whatever' ),
    true,
    'rules_are(table, rules, desc)',
    'whatever',
    ''
);

SELECT * FROM check_test(
    rules_are( 'fou', ARRAY['ins_me', 'upd_me'] ),
    true,
    'rules_are(table, rules)',
    'Relation fou should have the correct rules',
    ''
);

SELECT * FROM check_test(
    rules_are( 'fou', ARRAY['ins_me'] ),
    false,
    'rules_are(table, rules) + extra',
    'Relation fou should have the correct rules',
    '    Extra rules:
        upd_me'
);

SELECT * FROM check_test(
    rules_are( 'fou', ARRAY['ins_me', 'upd_me', 'del_me'] ),
    false,
    'rules_are(table, rules) + missing',
    'Relation fou should have the correct rules',
    '    Missing rules:
        del_me'
);

SELECT * FROM check_test(
    rules_are( 'fou', ARRAY['ins_me', 'del_me'] ),
    false,
    'rules_are(table, rules) + extra & missing',
    'Relation fou should have the correct rules',
    '    Extra rules:
        upd_me
    Missing rules:
        del_me'
);

/****************************************************************************/
-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
