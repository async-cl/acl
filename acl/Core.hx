
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

typedef  TCouchObj = {
	?_id:String,
	?_rev:String,
	docType:String
};

typedef TCouchIDRev = {
	id:String,
	rev:String
};

typedef TRelation = {
 	name:String
 };
 
typedef TCombineVal<T> = Iterable<TVal<String,T>>;
typedef TCombineIn<T> = Iterable<TOutcome<String,T>>;
typedef TCombineOut<T> = TOutcome<String,TCombineVal<T>>;

class Core {
	
	static var errorEvents = new Event<Dynamic>();
	
	public static function err(e:Dynamic) {
		errorEvents.inform(e);
	}
	
	public static function errListener(fn:Dynamic->Void) {
		errorEvents.await(fn);
	}
	
	public static function makeApply(o:Dynamic,method:String):Dynamic {
		return function(a:Array<Dynamic>) {
			return Reflect.callMethod(o,Reflect.field(o,method),a);
		}
	}
	
	public static function promise<T>():TPromise<T> {
		return new TPromise<T>();
	}
	
	public static function event<T>():TEvent<T> {
		return new acl.Event<T>();
	}
	
	public static function outcome<F,S>():TOutcome<F,S> {
		return new TPromise<TVal<F,S>>();
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
	
	public static function validate<F,S,T>(p:TOutcome<F,S>,fn:S->TOutcome<F,T>):TOutcome<F,T> {

		var oc = new TPromise<TVal<F,T>>();

		if(p.isCancelled()) {
			oc.cancel();
		} else {
			p.onComplete(function(v) {
				if (v.isSuccess()) {
					var next = fn(v.extract());
					if (next != null)
						next.onComplete(oc.complete);
				} else {
					trace("cancelling due to failure "+v);
					oc.cancel();
				}
				return null;
			});
		
		}
		return oc;
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
	public static function tap<F,S,D>(chain:TChain<F,S,D>,fn:D->Void):TChain<F,S,D> {
		fn(chain.data);
		return chain;	
	}
	
	public static function dechain<F,F2,S,D>(chain:TChain<F,S,D>,?fn:S->Dynamic):TOutcome<F2,S> {
		if (fn != null)
			value(chain,fn);
	
		return cast chain.prm;
	}
	
	public static function finalData<F,S,D>(chain:TChain<F,S,D>,fn:S->D->Void):TOutcome<F,D> {
		var oc  = new TPromise<TVal<F,D>>();
		value(chain,function(val) {
			fn(val,chain.data);
			oc.complete(Success(chain.data));
			return null;
		});
		return oc;
	}

	public static function combine<F,S>(outcomes:TCombineIn<S>):TCombineOut<S> {
		var oc:TCombineOut<S> = Core.outcome();
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
}
