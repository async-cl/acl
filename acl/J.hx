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
	
	/**
		Make an object with names from the given array and populate it with TJq instances
		of the corresponding IDs from the page.
	*/
	public static function makeRefs(refs:Array<String>):Dynamic {
		return refs.foldLeft({},function(acc,el) {
			var ref = J.q(el);
			if (ref.length == 0) {
				Core.err(el+" does not exist on page");
			} else {
				Reflect.setField(acc,el.substr(1),ref);
			}
			return acc;
		});
	}
	

}
