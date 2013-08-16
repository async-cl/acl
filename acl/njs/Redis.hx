
package acl.njs;

using scuts.core.Options;
using scuts.core.Promises;
using scuts.core.Validations;
using scuts.core.Functions;

using acl.Core;


typedef TRedisErr = Null<String>;
typedef TRedisClient = {};


typedef TRedis = {
    client:TRedisClient;
}

class Redis {
    static var redis = js.Node.require('redis');

   	public static function client(port,host,options):TRedis {
        return redis.createClient(port,host,options);
    }

    public static function set(r:TRedis,k:String,v:Dynamic) {
        var oc = Core.outcome();
        r.set(k,v,function(err) {
            oc.complete((err == null) ? Success(1): Failure(err));
        });
    }

    public static function () {
        
        
    }
}
