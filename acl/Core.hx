
package acl;

using scuts.core.Validation;
using scuts.core.Validations;
using scuts.core.Promises;
using scuts.core.Strings;

typedef TPromise<T> = scuts.core.Promise<T>;
typedef TEvent<T> = acl.Event<T>;
typedef TVal<F,S> = scuts.core.Validation<F,S>
typedef TOutcome<F,S> = TPromise<TVal<F,S>>;
typedef TOption<T> = scuts.core.Option<T>;

typedef TChain<F,S,D> = {
	prm:TOutcome<F,S>,
	data:D
};

enum TRHashReply {
 	HNew;
 	HUpdated;
 }

@:coreType abstract TEntityID from String  to String { }
@:coreType abstract TEntityRev from String to String { }

typedef TEntityBase = {
	?_id:TEntityID
}

typedef TEntityRef = { > TEntityBase,
	?_rev:TEntityRev
}

typedef TEntity = { > TEntityRef,
	docType:String
}

enum TEntityKeys {
	KEY(params:Dynamic);
	KEYS(params:Array<Dynamic>);
}

typedef TRelation = {
 	name:String
};

enum TEntityEvent<T> {
	AfterCreate(entity:TEntity,info:T);
	AfterUpdate(entity:TEntity,info:T);
	AfterDelete(entity:TEntityRef,info:T);
}

interface EntityDriver {
    function delete(entity:TEntityRef,?info:Dynamic):TOutcome<String,String> ;
    function insert(entity:TEntity,?id:String,?info:Dynamic):TOutcome<String,TEntityRef> ;
    function insert_<T:TEntity>(entity:T):TOutcome<String,T> ;
    function get<T>(id:TEntityID):TOutcome<String,T>;
    function on<T>(fn:TEntityEvent<T>->Void):Void;
    function link(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,TEntityRef> ;
    function unlink(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,String> ;
    function children<T>(relation:TRelation,parent:TEntityBase):TOutcome<String,Array<T>> ;
    function inverse<T>(relation:TRelation,child:TEntityBase):TOutcome<String,Array<T>> ;
    function view<T>(view:String,?params:TEntityKeys,includeDocs:Bool):TOutcome<String,Array<T>> ;
    function attach(entityRef:TEntityRef,name:String,data:Dynamic,mimeType:String):TOutcome<String,TEntityRef> ;
}

typedef TCombineVal<F,S> = Iterable<TVal<F,S>>;
typedef TCombineIn<F,S> = Iterable<TOutcome<F,S>>;
typedef TCombineOut<F,S> = TOutcome<F,TCombineVal<F,S>>;

class Core {

	static var errorEvents = new Event<Dynamic>();

	public static function err(e:Dynamic) {
		errorEvents.emit(e);
	}

	public static inline function copy(obj:Dynamic) {
		return haxe.Json.parse(haxe.Json.stringify(obj));
	}	
	
	public static function errListener(fn:Dynamic->Void) {
		errorEvents.on(fn);
	}
	
	public static function makeApply(o:Dynamic,method:String):Dynamic {
		return function(a:Array<Dynamic>) {
			return Reflect.callMethod(o,Reflect.field(o,method),a);
		}
	}
	
	public static inline function promise<T>():TPromise<T> {
		return new TPromise<T>();
	}
	
	public static inline function event<T>():TEvent<T> {
		return new acl.Event<T>();
	}
	
	public static function outcome<F,S>(?val:TVal<F,S>):TOutcome<F,S> {
		var p = new TPromise<TVal<F,S>>();
        if (val != null)
            p.complete(val);
        return p;
	}	
	
	public static inline function entityRef(entity:TEntity):TEntityRef {
		return {_id:entity._id,_rev:entity._rev};
	}
	public static function failure<F,S>(?f:F):TOutcome<F,S> {
		var oc = new TPromise<TVal<F,S>>();
		oc.complete(Failure(f));
		return oc;
	}
	
	public static function success<F,S>(?s:S):TOutcome<F,S> {
		var oc = new TPromise<TVal<F,S>>();
		oc.complete(Success(s));
		return oc;
	}

	public static function print(d:Dynamic) {
		trace(d);
		return null;
	}

    public static function map<F,S,T>(p:TOutcome<F,S>,fn:S->T):TOutcome<F,T> {
		return p.map(function(v) {
			return if (v.isSuccess()) Success(fn(v.extract())) else Failure(v.extractFailure());
		});
	}
	
	public static function fmap<F,S,S2>(p:TOutcome<F,S>,fn:S->TOutcome<F,S2>):TOutcome<F,S2> {
		return p.flatMap(function(v) {
			return if (v.isSuccess()) fn(v.extract()) else Core.failure(v.extractFailure());
		});		
	}

    public static function fmapFail<F,S,F2>(p:TOutcome<F,S>,fn:F->TOutcome<F2,S>):TOutcome<F2,S> {
		return p.flatMap(function(v) {
			return if (v.isFailure()) fn(v.extractFailure()) else Core.success(v.extract());
		});
	}

	public static function mapFail<F,S,F2>(p:TOutcome<F,S>,fn:F->F2):TOutcome<F2,S> {
		return p.flatMap(function(v) {
			return if (v.isFailure()) Core.failure(fn(v.extractFailure())) else Core.success(v.extract());
		});
	}

    public static function onFail<F,S>(p:TOutcome<F,S>,fn:F->Void) {
        p.onComplete(function(v) {
            if (v.isFailure()) {
                fn(v.extractFailure());
            }
            return v;
        });
    }
    
	public static function onSuccess<F,S,T>(p:TOutcome<F,S>,fn:S->Void,?fail:F->Void) {
		p.onComplete(function(v) {
			if (v.isSuccess())
				fn(v.extract());
			else 
				if (fail != null)
					fail(v.extractFailure());
			return null;
		});
	}

	public static function combine<F,S>(outcomes:TCombineIn<F,S>):TCombineOut<F,S> {
		var oc:TCombineOut<F,S> = Core.outcome();
		outcomes.combineIterable()
		.onComplete(function(i) {
			oc.complete(Success(i));
			return null;
		}).onCancelled(function() {
			oc.cancel();
			return null;
		});
		return oc;
	}

	public static function combineMap<F,S,A,B>(outcomes:Iterable<TOutcome<F,S>>,fn:Iterable<TVal<F,S>>->B):TPromise<B> {
		return outcomes.combineIterableWith(fn);
	}
	
	/**
		Call the given function only after any other calls to the same function have completed
        in sequence.
	*/
	public static function serializeCall<F,S>(fn:Void->TOutcome<F,S>) {
		var Q:Array<TOutcome<F,S>> = [];
		var processing = false;
		
		function recur() {
			fn().onComplete(function(v) {
				var oc = Q.shift();
				oc.complete(v);
				if (Q.length > 0)
					recur();
				else
					processing = false;
				return null;
			});
		}
		
		return function() {
			var oc = Core.outcome();
			Q.push(oc);
			if (!processing) {
				processing = true;
				recur();
			}
			return oc;
		};
	}
		
	public static function mapOutcome<F,S>(o:TOption<S>,f:F):TOutcome<F,S> {
		return switch(o) {
			case Some(s): Core.success(s);
			case None: Core.failure(f);
		};
	}

    public static function partition<T>(a:Array<T>,num:Int) {
        var p = [];
        var ntimes = Math.floor(a.length / num);
        for (i in 0...ntimes)
            p.push(a.slice(i*num,num));
        return p;
    }


    public static function logHeader(text:String) {
        var t = "\n"+text; 
        trace(t);
        trace("-".times(t.length+1));
    }

    public static function onCompletedReply<E,T>(oc:TOutcome<E,T>,res) {
	    oc.onComplete(function(v) {
		    res.send(200,haxe.Serializer.run(v));
		    return null;
	    });
    }
    
    public static function validationReply<T>(v:Validation<String,T>,res) {
	    res.send(200,haxe.Serializer.run(v));
    }

}

