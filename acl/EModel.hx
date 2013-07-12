package acl;

using scuts.core.Iterables;
using scuts.core.Arrays;
using scuts.core.Options;
using scuts.core.Hashs;
using scuts.core.Promises;
using scuts.core.Validations;
import scuts.core.Pair;

using acl.Core;
using acl.Event;
using acl.EClient;

enum EEvent<T:TEntityBase> {
    Add(cls:T);
    Remove(cls:T);
    Update(cls:T);
}
 
typedef TEModel<T:TEntityBase> = {
    _events:Event<EEvent<T>>,
    _cache:Map<String,T>
}

// Entity Model

class EModel {

    public static function create<T:TEntity>(data:Array<T>):TEModel<T> {
    trace("ARR:"+data);
        return {
            _events:Core.event(),
            _cache:data.foldLeft(new Map<String,T>(),function(acc,s) {
                    acc.set(cast s._id,s);
                    return acc;
                })
        };
    }

    public static function on<T:TEntityBase>(model:TEModel<T>,fn:EEvent<T>->Void) {
        model._events.on(fn);
    }
    
    public static function get<T:TEntity>(model:TEModel<T>,key:String):T {
        return model._cache.get(key);
    }
    
    public static function set<T:TEntity>(model:TEModel<T>,key:String,cls:T) {
        model._cache.set(key,cls);
        model._events.emit(Update(Core.copy(cls)));
    }
    
    /**
        Note that altering the elements of this array changes the model.
    */
    public static function toArray<T:TEntity>(model:TEModel<T>) {
        return model._cache.mapToArray(function(k,v) {
            return v;
        });
    }
    
    public static function
    snapshot<T:TEntity>(model:TEModel<T>):Array<T> {
        return toArray(model).map(function(el) {
            return Core.copy(el);
        });
    }

    /**
        Link a child to a parent
    */
    public static function
    link<T:TEntity>(model:TEModel<T>,relation:String,parent:TEntityBase,child:T):TOutcome<String,TEntityRef> {
        return EClient.entityLink(relation,parent,child);
    }
    
    public static function
    addClassWithImage<T:TEntity>(model:TEModel<T>,file:Dynamic,data:Dynamic):TOutcome<String,T> {
        return Core.outcome();
    }
   
    public static function
    unlink<T:TEntity>(model:TEModel<T>,relation,parent:TEntityBase,child:T):TOutcome<String,TEntityRef> {
        return EClient.entityUnlink(relation,parent,child);
    }
    
    public static function
    update<T:TEntity>(model:TEModel<T>,entity:T):TOutcome<String,TEntityRef> {
        return EClient.entityInsert(entity).fmap(function(idrev) {
            entity._rev = idrev._rev;
            model._cache.set(idrev._id,entity);
            model._events.emit(Update(Core.copy(entity)));
            return Core.success(idrev);
        });
    }

    public static function
    delete<T:TEntity>(model:TEModel<T>,entity:T):TOutcome<String,String> {
        return EClient.entityDelete(entity).fmap(function(ok) {
            model._cache.remove(entity._id);
            model._events.emit(Remove(entity));
            return Core.success("ok");
        });
    }
    
    public static function
    updateWithImage<T:TEntity>(model:TEModel<T>,file:Dynamic,data:T,imageName:String):TOutcome<String,T> {
        return EClient.entityInsertWithImage(file,data,imageName).fmap(function(cls) {
        trace('updating cache ${cls._id},${cls._rev}');
            model._cache.set(cls._id,cls);
            model._events.emit(Update(Core.copy(cls)));
            return Core.success(cls);
        });
    }
   

}
