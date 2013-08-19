package acl.njs;


using scuts.core.Iterables;
using scuts.core.Arrays;
using scuts.core.Options;
using scuts.core.Hashs;
using scuts.core.Promises;
using scuts.core.Validations;
import scuts.core.Pair;

using acl.Core;
using acl.njs.Sys;

/**
 * General purpose multiple file json reader.
 * Provide a directory of json files of the same type and this reads and
 * caches files.
 *
 * @author Ritchie Turner
 */

typedef TConf<T> = Pair<String,T>;

typedef TConfCache<T> = {
    var cache:Map<String,Array<TConf<T>>>;
}

class Configs {

    public static function cacheCreate<T>():TOutcome<String,TConfCache<T>> {
        return Core.success({
            cache:new Map()
        });
    }
    
    public static function get<T>(cache:TConfCache<T>,dir:String,?fileName:String):TOutcome<String,Array<TConf<T>>> {
        var dirReader = if (fileName != null) perDir.bind(_,fileName); else fromDir ;
            
        var prm:TOutcome<String,Array<TConf<T>>> = Core.outcome();
        switch(cache.cache.getOption(dir)) {
        case None:
            dirReader(dir).onSuccess(function(a:Array<TConf<T>>) {
                cache.cache.set(dir,a);
                prm.complete(Success(a));
            });
        case Some(cached):
            trace("using cached");
            prm.complete(Success(cast cached));
        }
        return prm;
    }
    
    public static function fromDir<T>(dir:String):TOutcome<String,Array<TConf<T>>> {
        return reader(dir,function(dir,name) {
            return Sys.readFile(dir+"/"+name);
        });
    }

    public static function perDir<T>(dir:String,fileName:String):TOutcome<String,Array<TConf<T>>> {
        return reader(dir,function(dir,name) {
            return Sys.readFile(dir+"/"+name+"/"+fileName);
        });
    }
    
    static function
    reader<T>(dir:String,readWith:String->String->TOutcome<String,String>):TOutcome<String,Array<TConf<T>>> {
       return Sys.readdir(dir).fmap(function(entries) {
           return Core.combine(entries.map(function(name) {
               return readWith(dir,name).fmap(function(conf:String) {
                   return Core.success(Pair.create(name,haxe.Json.parse(conf)));
               });
           }));                     
       }).fmap(function(confs) {
           return Core.success(confs.map(function(c) {
               return c.option();
           }).toArray().catOptions());
       });
   }
}
