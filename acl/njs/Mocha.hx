package acl.njs;

using acl.Core;
using scuts.core.Validations;
using acl.njs.Sys;

/**
 * ...
 * @author Ritchie Turner
 */
class Mocha {
	
	static var _assert:SysAssert;
	
	public static function init() {
		_assert = Sys.Assert;
	}
	
	public static function describe(thing:String,fn:Void->Void) {
		untyped __js__("describe(thing,fn)");
	}
	
	public static function it(should:String,?fn:Dynamic) {
		untyped __js__("it(should,fn)");
	}
	
	
	public static function beforeEach(fn:Void->Void) {
		untyped __js__("beforeEach(fn)");
	}
	
	public static function beforeEach_(fn:(Void->Void)->Void) {
		untyped __js__("beforeEach(fn)");
	}
	
	public static function before(fn:Void->Void) {
		untyped __js__("before(fn)");
	}
	
	public static function before_(fn:(Void->Void)->Void) {
		untyped __js__("before(fn)");
	}
	
	
    public static function fail(actual:Dynamic,expected:Dynamic,message:Dynamic,operator:Dynamic) {
    	
    }

	public static function qassert<F,S>(prm:TOutcome<F,S>,done:Void->Void,fn:TVal<F,S>->S->Dynamic->Void,actual:S,?msg:String) {
		prm.onComplete(function(v) {
			try {
				fn(v,actual,msg);
			} catch(e:Dynamic) {
				trace(e);
			}
			done();
			return null;
		});
	}
	
	public static function assert<F,S>(prm:TOutcome<F,S>,ifSuccess:S->Void,?ifFail:F->Void) {
		prm.onComplete(function(v) {
			try {
				if (v.isSuccess()){
					ifSuccess(v.extract());
				} else {
					var fail = v.extractFailure();
					if (ifFail != null)
						ifFail(fail);
					else
						_assert.fail(fail,"success","failure",null);
				}
			} catch(e:Dynamic) {
				trace(e);
			}
			return null;
		});
	}
	
	public static function assertFail<F,S>(prm:TOutcome<F,S>,ifFail:F->Void) {
		prm.onComplete(function(v) {
			try {
				if (v.isSuccess()){
					_assert.fail(fail,"failure","success",null);
				} else {
					var fail = v.extractFailure();
					ifFail(fail);
				}
			} catch(e:Dynamic) {
				trace(e);
			}
			return null;
		});
	}
	
	
	
	static function validate<F,S>(_assertion:Dynamic,v:TVal<F,S>,expected:S,?message:Dynamic) {
		if (v.isSuccess())
    		_assertion(v.extract(),expected,message);
    	else
    		_assert.fail(v.extractFailure(),expected,"operation failure",null);
  
	}
	
    public static inline function equal<F,S>(actual:TVal<F,S>,expected:S,message:Dynamic) {
    	validate(_assert.equal,actual,expected,message);	
    }
    
    public static function notEqual<F,S>(actual:TVal<F,S>,expected:S,?message:Dynamic) {
    	validate(_assert.notEqual,actual,expected,message);	
    }
    
    public static inline function deepEqual<F,S>(actual:TVal<F,S>,expected:S,?message:Dynamic) {
    	validate(_assert.deepEqual,actual,expected,message);	
    }
    
    public static function notDeepEqual<F,S>(actual:TVal<F,S>,expected:S,?message:Dynamic) {
    	validate(_assert.notDeepEqual,actual,expected,message);	
    }
    
    public static inline function strictEqual<F,S>(actual:TVal<F,S>,expected:S,?message:Dynamic) {
    	validate(_assert.strictEqual,actual,expected,message);	
    		_assert.strictEqual(actual,expected,message);
    }
    
    public static inline function notStrictEqual<F,S>(actual:TVal<F,S>,expected:S,?message:Dynamic) {
    	validate(_assert.notStrictEqual,actual,expected,message);	
    }
    
    public static inline function throws(block:Dynamic,error:Dynamic,?message:Dynamic) {
    	_assert.throws(block,error,message);
    }
    
    public static inline function doesNotThrow(block:Dynamic,error:Dynamic,?message:Dynamic) {
    	_assert.doesNotThrow(block,error,message);
    }
    
    public static function ifError(value:Dynamic) {
    	_assert.ifError(value);
    }
}
