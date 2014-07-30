redis_pool
==========
Generally, when using connection pool, we should accquire a connection first, and use the client to exectute command.
here we directly execute command after creating pool.

when create a pool for redis:
pool.execcmd("set", "user1", "lily" fuction(err, result){} );

other than:
pool.acquire(    function(err, client){
  client.set("user1", "lily", function(err, result){};
  });
  
  
when create a pool for mysql:
pool.execcmd("query","select * from table_XX", function(err, result){});

