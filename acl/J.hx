package acl;

/**
 * ...
 * @author ritchie
 */
 
using acl.Core;
import JQuery;
using scuts.core.Arrays;
import JQuery;

typedef TJq = JQuery;

enum EMixedRefs {
	S(selector:String); //self named
	N(name:String,selector:String); // explicitly named
}

class J {
	
	public static var _= JQuery._static;
	
	public static var cur(get, null) : JQuery;

	private static inline function get_cur() : JQuery {
		return untyped __js__("$(this)");
	}

	public static function q(x:Dynamic,?ctx:TJq):TJq {
		return new JQuery(x,ctx);
	}
	
	public static function ready(fn:Void->Void) {
		new JQuery(fn);
	}
	
	static function validRef(ref) {
		var valid = ref.length > 0;
		if (!valid)
			Core.err(ref+" does not exist on page");
		return valid;
	}
	
	/**
		Make an object with names from the given array and populate it with TJq instances
		of the corresponding IDs from the page.
	*/
	public static function makeRefs(refs:Array<String>):Dynamic {
		return refs.foldLeft({},function(acc,el) {
			var ref = J.q(el);
			if (validRef(ref))
				Reflect.setField(acc,el.substr(1),ref);
			return acc;
		});
	}
	
	public static function makeRefsMixed(refs:Array<EMixedRefs>):Dynamic {
		return refs.foldLeft({},function(acc,el) {
			switch(el) {
				case S(selector):
					var ref = J.q(selector);
					if (validRef(ref))
						Reflect.setField(acc,selector.substr(1),ref);
					
				case N(name,selector):
					var ref = J.q(selector);
					if (validRef(ref))
						Reflect.setField(acc,name,ref);
			}
			return acc;
		});
	}
	

}
