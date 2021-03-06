\unset ECHO
\i test_setup.sql

SELECT plan(39);

-- This will be rolled back. :-)
SET client_min_messages = warning;
CREATE TABLE public.sometab(
    id    INT NOT NULL PRIMARY KEY,
    name  TEXT DEFAULT '' UNIQUE,
    numb  NUMERIC(10, 2),
    myint NUMERIC(8)
);
RESET client_min_messages;

/****************************************************************************/
-- Test has_unique().

SELECT * FROM check_test(
    has_unique( 'public', 'sometab', 'public.sometab should have a unique constraint' ),
    true,
    'has_unique( schema, table, description )',
    'public.sometab should have a unique constraint',
    ''
);

SELECT * FROM check_test(
    has_unique( 'sometab', 'sometab should have a unique constraint' ),
    true,
    'has_unique( table, description )',
    'sometab should have a unique constraint',
    ''
);

SELECT * FROM check_test(
    has_unique( 'sometab' ),
    true,
    'has_unique( table )',
    'Table sometab should have a unique constraint',
    ''
);

SELECT * FROM check_test(
    has_unique( 'pg_catalog', 'pg_class', 'pg_catalog.pg_class should have a unique constraint' ),
    false,
    'has_unique( schema, table, description ) fail',
    'pg_catalog.pg_class should have a unique constraint',
    ''
);

SELECT * FROM check_test(
    has_unique( 'pg_class', 'pg_class should have a unique constraint' ),
    false,
    'has_unique( table, description ) fail',
    'pg_class should have a unique constraint',
    ''
);

/****************************************************************************/
-- Test col_is_unique().

SELECT * FROM check_test(
    col_is_unique( 'public', 'sometab', 'name', 'public.sometab.name should be a pk' ),
    true,
    'col_is_unique( schema, table, column, description )',
    'public.sometab.name should be a pk',
    ''
);

SELECT * FROM check_test(
    col_is_unique( 'sometab', 'name', 'sometab.name should be a pk' ),
    true,
    'col_is_unique( table, column, description )',
    'sometab.name should be a pk',
    ''
);

SELECT * FROM check_test(
    col_is_unique( 'sometab', 'name' ),
    true,
    'col_is_unique( table, column )',
    'Column sometab(name) should have a unique constraint',
    ''
);

SELECT * FROM check_test(
    col_is_unique( 'public', 'sometab', 'id', 'public.sometab.id should be a pk' ),
    false,
    'col_is_unique( schema, table, column, description ) fail',
    'public.sometab.id should be a pk',
    '        have: {name}
        want: {id}'
);

SELECT * FROM check_test(
    col_is_unique( 'sometab', 'id', 'sometab.id should be a pk' ),
    false,
    'col_is_unique( table, column, description ) fail',
    'sometab.id should be a pk',
    '        have: {name}
        want: {id}'
);

/****************************************************************************/
-- Test col_is_unique() with an array of columns.

SET client_min_messages = warning;
CREATE TABLE public.argh (
    id INT NOT NULL,
    name TEXT NOT NULL,
    UNIQUE (id, name)
);
RESET client_min_messages;

SELECT * FROM check_test(
    col_is_unique( 'public', 'argh', ARRAY['id', 'name'], 'id + name should be a pk' ),
    true,
    'col_is_unique( schema, table, column[], description )',
    'id + name should be a pk',
    ''
);

SELECT * FROM check_test(
    col_is_unique( 'argh', ARRAY['id', 'name'], 'id + name should be a pk' ),
    true,
    'col_is_unique( table, column[], description )',
    'id + name should be a pk',
    ''
);

SELECT * FROM check_test(
    col_is_unique( 'argh', ARRAY['id', 'name'] ),
    true,
    'col_is_unique( table, column[] )',
    'Columns argh(id, name) should have a unique constraint',
    ''
);

/****************************************************************************/
-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
