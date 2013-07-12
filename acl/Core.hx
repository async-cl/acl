
package acl;

import scuts.core.Validation;
using scuts.core.Validations;
using scuts.core.Promise;
using scuts.core.Promises;


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
@:coreType abstract TEntityRev from String { }


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
	
	public static inline function outcome<F,S>():TOutcome<F,S> {
		return new TPromise<TVal<F,S>>();
	}	
	
	public static inline function entityRef(entity:TEntity) {
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
	
	public static function fmap<F,S,T>(p:TOutcome<F,S>,fn:S->TOutcome<F,T>):TOutcome<F,T> {
		return p.flatMap(function(v) {
			return if (v.isSuccess()) fn(v.extract()) else Core.failure(v.extractFailure());
		});		
	}
	
	
	public static function map_<F,S,T>(p:TOutcome<F,S>,fn:S->T):TOutcome<F,T> {
		return p.map(function(v) {
			return if (v.isSuccess()) Success(fn(v.extract())) else Failure(v.extractFailure());
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

	public static function chain<F,F2,S,T,D>(?start:TOutcome<F,S>,?data:D):TChain<F2,T,D> {
		if (start == null) start = cast Core.success("dummy");
		var data = (data == null) ? cast {} : data;
		return cast {prm:start,data:data};
	}
	
	static function linker<F,F2,S,D,T>(chain:TChain<F,S,D>,fn:S->D->TOutcome<F2,T>,?name:String) {
		return  {
			prm:chain.prm.flatMap(function(v) {
				if (v.isSuccess()) {
					var d = v.extract();
					if (name != null) {
						Reflect.setField(chain.data,name,d);
					}
					return fn(d,chain.data);
				} else
					return cast Core.failure(v.extractFailure());	
			}),
			data:chain.data,
		};
	}
	
	public static function link<F,F2,S,T,D>(chain:TChain<F,S,D>,?name:String,fn:S->TOutcome<F2,T>):TChain<F2,T,D> {
		return linker(chain,function(s,data) {
			return fn(s);
		},name);
	}
	
	public static function linkD<F,F2,S,T,D>(chain:TChain<F,S,D>,?name:String,fn:S->D->TOutcome<F2,T>):TChain<F2,T,D> {
		return linker(chain,fn,name);
	}
	
	public static function value<F,S,D>(chain:TChain<F,S,D>,fn:S->Void):TChain<F,S,D> {
		chain.prm.onComplete(function(v) {
			if (v.isSuccess())	{
				fn(v.extract());
			}
			return null;
		});
		return chain;
	}
	
	/**
		Tap into the chain and get any data.
	*/
	public static function tap<F,S,D>(chain:TChain<F,S,D>,fn:S->D->Void):TChain<F,S,D> {
		return {
			prm:chain.prm.map(function(v) {
				if (v.isSuccess()) {
					fn(v.extract(),chain.data);
				}
				return v;
			}),
			data:chain.data	
		};
	}
	
	public static function dechain<F,F2,S,D>(chain:TChain<F,S,D>,?fn:S->Dynamic):TOutcome<F2,S> {
		if (fn != null)
			value(chain,fn);
	
		return cast chain.prm;
	}
	
	public static function finalData<F,S,D>(chain:TChain<F,S,D>,?fn:S->D->Void):TOutcome<F,D> {
		var oc  = new TPromise<TVal<F,D>>();
		value(chain,function(val) {
			if (fn != null)
				fn(val,chain.data);
			oc.complete(Success(chain.data));
			return null;
		});
		return oc;
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

}

