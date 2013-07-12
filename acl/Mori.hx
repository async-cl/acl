package acl;

/**
 * ...
 * @author Ritchie Turner
 */
 
 
 
 typedef MHash<K,V>= {}
 typedef MVec<T> = {}
 
class Mori {
	
	#if nodejs
	static var M:Dynamic = js.Node.require('mori');
	#end
	
	public static function hash<K,V>(a:Array<Dynamic>):MHash<K,V> {
		return Reflect.callMethod(M,M.hash_map,a);
	}
	
	public static function vector<T>(a:Array<T>):MVec<T> {
		return Reflect.callMethod(M,M.vector,a);
	}
	
	@:overload(function<K,V>(c:MHash<K,V>,k:K) : V {})
	public static function get<Int,V>(c:MVec<V>,k:Int):V {
		return M.get(c,k);
	}

	@:overload(function<K,V>(c:MHash<K,V>,v:V) : MHash<K,V> {})
	public static function conj<Int,V>(c:MVec<V>,v:V): MVec<V> {
		return M.conj(c,v);
	}
	
	@:overload(function<K,V>(c:MHash<K,V>,k:K,v:V) : MHash<K,V> {})
	public static function assoc<Int,V>(c:MVec<V>,k:Int,v:V): MVec<V> {
		return M.assoc(c,k,v);
	}
	
	@:overload(function<K,V>(c:MHash<K,V>) : Int {})
	public static function count<Int,V>(c:MVec<V>):Int {
		return M.count(c);
	}
	
	// sequences
	
	@:overload(function<K,V>(c:MHash<K,V>): V {})
	public static function first<Int,V>(c:MVec<V>):V {
		return M.first(c);
	}
	

}
