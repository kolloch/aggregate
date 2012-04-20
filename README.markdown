Aggregate.js
=============

ATTENTION: Still basically untested.

Making aggregating multiple similar asynchronous requests easy.

During a tick calls to specially wrapped functions are aggregated. The aggregated function is then executed exactly once. The results are demultiplexed to the individual callers.

A typical usage scenario might be fetching data about single users:

    var getUsers = function(ids, callbackWithUserMap) {
      // some database call resulting in
      // callbackWithUserMap(null, {id1: user1, id2: user2});
    }

    // in multiple concurrent requests
    getUsers([1,2,3], callback);
    getUsers([2,3,4], callback);
    getUsers([2,3], callback);

With the help of this libary, the actual get method only gets called once with `[1,2,3,4]` while the results are properly dispatched to the separate callers.

    var aggregate = require('aggregate');

    var getUsers = aggregate(getUsers);

And you get a convenience function for single users for free:

    var getUser = getUsers.forSingleId();

    getUser(3, function(err,user) {
    });

TODO
----

More concrete example with benchmark.

Gotchas
-------

* Only use aggregated functions if you do not need transactional guarantees or similar.

* Logging could be removed to get rid of overhead and unecessary depedencies.

* CoffeeScript required.