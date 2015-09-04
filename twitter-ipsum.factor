! Copyright (C) 2015 Nathan Holland.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs hashtables kernel lists locals
       math math.ranges random sequences splitting ;
IN: twitter-ipsum

<PRIVATE

:: last2 ( seq -- second-to-last last )
    seq length 2 - seq nth
    seq length 1 - seq nth ;

ERROR: sequence-too-short seq minimum-size ;
:: triples ( seq -- seq-of-triples )
    seq length 3 < [ seq 3 sequence-too-short ] when

    0 seq length 3 - 1 <range>
    [| i |
        i seq nth
        i 1 + seq nth
        i 2 + seq nth
        3array
    ] map ;

: sample-single ( seq -- el )
    dup length 1 - random-unit * >integer swap nth ;

:: sample-section ( seq n -- seq' )
    seq length n < [ seq n too-many-samples ] when
    seq length n - random-unit * >integer dup n + seq subseq ;

PRIVATE>

: generate-markov-chains ( words -- chains )
    [let triples :> sets
    [let sets length <hashtable> :> chains
        sets
        [| s |
            2 s nth
            s first2 2array
            chains set-at
        ] each

        chains
    ] ] ;

TUPLE: markov-text-generator words chains ;
:: <markov-text-generator> ( str -- markov-text-generator )
    markov-text-generator new
    str " " split >>words
    dup words>> generate-markov-chains >>chains ;

:: generate-text ( size generator -- string )
    2 size 1 <range>
    generator words>> 2 sample-section
    [| words _ |
        words last2 2array
        generator chains>> at*
        [ words swap cons ] [ drop words generator words>> sample-single cons ] if
    ] foldl " " join ;
