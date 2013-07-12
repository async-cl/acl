package acl;

/**
 * ...
 * @author ritchie
 */
 
using acl.Core;
using scuts.core.Arrays;
import JQuery;

import jQuery.plugins.jQueryTools.Validator;

typedef TJq = JQuery;
typedef TJqEvent = JQuery.JQueryEvent;
typedef TJqTabs = jQuery.plugins.jQueryTools.Tabs;
typedef TJqOverlay = jQuery.plugins.jQueryTools.Overlay;
typedef TJqValidator = Validator;
typedef TJqValidatorApi = ValidatorAPI;


typedef TJqFileUpload = { > TJq,
	function fileupload(options:Dynamic):TJq;
}

enum EMixedRefs {
	S(selector:String); //self named
	N(name:String,selector:String); // explicitly named
}

class J {
	
	public static var _= JQuery._static;
	
	public static var cur(get, null) : TJq;

	public static var div(get,null):TJq;
	public static var span(get,null):TJq;

	public static inline function id(id:String) {
		return J.q('#'+id);
	}
		
	private static inline function get_cur() : JQuery {
		return untyped __js__("$(this)");
	}

	private static inline function get_div() : JQuery {
		return J.q('<div></div>');
	}

	private static inline function get_span() : JQuery {
		return J.q('<span></span>');
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
	
	public static function validator(jq:TJq,?options:Dynamic):TJqValidatorApi {	
		var v = Validator.validator(jq,options);
        return Validator.getValidatorAPI(v);
	}

    public static function getCookie(name) {
        return untyped __js__('$.cookie(name)');
    }
}
