\unset ECHO
\i test_setup.sql

SELECT plan(20);

/****************************************************************************/

-- Set up some functions that are used only by this test, and aren't available
-- in PostgreSQL 8.2 or older

CREATE OR REPLACE FUNCTION quote_literal(polygon)
RETURNS TEXT AS 'SELECT '''''''' || textin(poly_out($1)) || '''''''''
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION quote_literal(integer[])
RETURNS TEXT AS 'SELECT '''''''' || textin(array_out($1)) || '''''''''
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION quote_literal(inet[])
RETURNS TEXT AS 'SELECT '''''''' || textin(array_out($1)) || '''''''''
LANGUAGE SQL IMMUTABLE STRICT;

/****************************************************************************/
-- Test cmp_ok().
SELECT * FROM check_test(
    cmp_ok( 1, '=', 1, '1 should = 1' ),
    true,
    'cmp_ok( int, =, int )',
    '1 should = 1',
    ''
);

SELECT * FROM check_test(
    cmp_ok( 1, '<>', 2, '1 should <> 2' ),
    true,
    'cmp_ok( int, <>, int )',
    '1 should <> 2',
    ''
);

SELECT * FROM check_test(
    cmp_ok( '((0,0),(1,1))'::polygon, '~=', '((1,1),(0,0))'::polygon ),
    true,
    'cmp_ok( polygon, ~=, polygon )'
    '',
    ''
);

SELECT * FROM check_test(
    cmp_ok( ARRAY[1, 2], '=', ARRAY[1, 2]),
    true,
    'cmp_ok( int[], =, int[] )',
    '',
    ''
);

SELECT * FROM check_test(
    cmp_ok( ARRAY['192.168.1.2'::inet], '=', ARRAY['192.168.1.2'::inet] ),
    true,
    'cmp_ok( inet[], =, inet[] )',
    '',
    ''
);

SELECT * FROM check_test(
    cmp_ok( 1, '=', 2, '1 should = 2' ),
    false,
    'cmp_ok() fail',
    '1 should = 2',
    '    ''1''
        =
    ''2'''
);

SELECT * FROM check_test(
    cmp_ok( 1, '=', NULL, '1 should = NULL' ),
    false,
    'cmp_ok() NULL fail',
    '1 should = NULL',
    '    ''1''
        =
    NULL'
);

/****************************************************************************/
-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;

-- Spam fingerprints: Contains an exact font color, and the words in the title are the same as in the body.
-- rule that extracts the existing google ad ID, a string, get from original special features script.
