
using acl.Core;
using acl.njs.Configs;


class TestConfigs {

    public static function main() {

        Configs.cachedFromDir("/home/ritchie/Projects/caanread/Public/activities/","config.json").onSuccess(function(a) {
            trace(a);
        });

        Configs.cachedFromDir("/home/ritchie/Projects/caanread/Products/").onSuccess(function(a) {
            trace(a);
            Configs.cachedFromDir("/home/ritchie/Projects/caanread/Products/").onSuccess(function(a) {
            });

        });


        
        
    }

}