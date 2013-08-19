
using acl.Core;
using acl.njs.Configs;


class TestConfigs {

    public static function main() {

        Configs.cacheCreate().onSuccess(function(cache) {
        
            cache.get("/home/ritchie/Projects/caanread/Public/activities/","config.json").onSuccess(function(a) {
                trace(a);
            });

            cache.get("/home/ritchie/Projects/caanread/Products/").onSuccess(function(a) {
                trace(a);
                cache.get("/home/ritchie/Projects/caanread/Products/").onSuccess(function(a) {
                });
            });
        });


        
        
    }

}