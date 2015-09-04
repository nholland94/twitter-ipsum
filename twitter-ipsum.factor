! Copyright (C) 2015 Nathan Holland.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs base64 hashtables http http.client
       json.reader kernel lists locals math math.ranges random
       sequences splitting urls.secure ;
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

: encode-url-parameters ( object -- string )
    [ "=" join ] map "&" join ;

: generate-twitter-auth-token ( key secret -- token )
    2array ":" join >base64 ;

: twitter-api-url ( path -- url )
    "https://api.twitter.com" swap 2array concat ;

:: request-twitter-bearer-token ( key secret -- bearer-token )
    "grant_type=client_credentials"
    "/oauth2/token" twitter-api-url <post-request>

    "Basic " key secret generate-twitter-auth-token 2array concat
    "Authorization" set-header
    "application/x-www-form-urlencoded;charst=UTF8" "Content-Type" set-header
    29 "Content-Length" set-header

    http-request drop body>> json>
    "access_token" swap at ;

TUPLE: twitter-api-client bearer-token ;
: <twitter-api-client> ( key secret -- twitter-api-client )
    twitter-api-client new
    [ request-twitter-bearer-token ] dip swap >>bearer-token ;

: twitter-bearer-token-authorization-header ( client -- string )
    "Bearer " swap bearer-token>> 2array concat ;

: twitter-get-request ( client url -- response data )
    <get-request>
    swap twitter-bearer-token-authorization-header
    "Authorization" set-header
    http-request ;

: get-twitter-rate-limit-status ( client -- rate-limit-status )
    "/1.1/application/rate_limit_status.json" twitter-api-url
    twitter-get-request drop body>> json> ;

: get-tweets-for-user ( client username -- tweets )
    [let :> username
        "/1.1/statuses/user_timeline.json?" twitter-api-url
        {
            { "screen_name" username }
            { "exclude_replies" "true" }
            { "include_rts" "false" }
        }
        encode-url-parameters
        2array concat
        twitter-get-request drop body>> json>
    ] ;

PRIVATE>

: generate-markov-chains ( words -- chains )
    [let triples :> sets sets length <hashtable> :> chains
        sets
        [| s |
            2 s nth
            s first2 2array
            chains set-at
        ] each

        chains
    ] ;

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
        [ words swap cons ]
        [ drop words generator words>> sample-single cons ]
        if
    ] foldl " " join ;
