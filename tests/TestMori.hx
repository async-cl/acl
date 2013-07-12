package tests ;
/**
 * ...
 * @author Ritchie Turner
 */
 
 using acl.Core;
 using acl.Http;
 using acl.Mori;

/**
 * ...
 * @author Ritchie Turner
 */
class TestMori {
	
	static function main() {
		var h:MHash<String,String> = Mori.hash(["first","ritchie","last","turner"]);
		trace("get hash "+h.get("last"));
		
		var v:MVec<Int> = Mori.vector([1,2,3,4]);
		trace("get vector "+v.get(0));
	

		var v2 = v.conj(5);
		
		trace("vector get 4 "+v2.get(4));
	
		
		var h2 = h.assoc("z",5);
		trace(h2.get("z"));
		
		var v3 = v2.assoc(0,100);
		trace(v3.get(0));
		
		trace('sizes vector ${v3.count()} and hash ${h2.count()}');
		
		trace("first vector "+v3.first());
		trace("first hash "+h2.first());
		
	}
	
	
	
	
}
