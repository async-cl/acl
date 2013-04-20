package acl.nme;

import acl.nme.Defs;

/**
 * ...
 * @author ritchie
 */
class U {
	public static function inf(s:TSprite) {
		trace('${s.name} -> dims (${s.x},${s.y},${s.width},${s.height}) - scale (${s.scaleX},${s.scaleY})');
	}	
	
	public static function removeChildren(s:TSprite) {
		while (s.numChildren > 0) {
			s.removeChildAt(0);
		}
	}
	
	public static function memoize(func:Dynamic , hash_size:Int = 100) : Dynamic {
    	var arg_hash = new Map<String,Dynamic>();
    	var f =  function(args:Array<Dynamic>){
	        var arg_string = args.join('|');
	        if (arg_hash.exists(arg_string)) return arg_hash.get(arg_string);
	        else{
	            var ret = Reflect.callMethod({},func,args);
	            if(Lambda.count(arg_hash) < hash_size) arg_hash.set(arg_string, ret);
	            return ret;
	        }
	    }
	    f = Reflect.makeVarArgs(f);
    	return f;
	}
	

}
