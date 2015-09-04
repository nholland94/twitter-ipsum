! Copyright (C) 2015 Nathan Holland.
! See http://factorcode.org/license.txt for BSD license.
USING: assocs hashtables kernel locals tools.test
       twitter-ipsum twitter-ipsum.private ;
IN: twitter-ipsum.tests

! last2
[ 4 5 ] [ { 1 2 3 4 5 } last2 ] unit-test
[ 2 1 ] [ { 5 4 3 2 1 } last2 ] unit-test

! triples
[ { 1 2 } triples ] must-fail

[ { { 1 2 3 } { 2 3 4 } { 3 4 5 } } ]
[ { 1 2 3 4 5 } triples ]
unit-test

! encode-url-parameters
[ "foo=bar&baz=asdf" ]
[ { { "foo" "bar" } { "baz" "asdf" } } ]
unit-test

! generate-markov-chains
[ t ]
[
    [let { 1 2 3 4 5 } generate-markov-chains :> chains
    [let 3 <hashtable> :> test-chains
        3 { 1 2 } test-chains set-at
        4 { 2 3 } test-chains set-at
        5 { 3 4 } test-chains set-at

        test-chains [ swap chains at = ] assoc-all?
    ] ]
]
unit-test
