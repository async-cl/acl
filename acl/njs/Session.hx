package acl.njs;

using scuts.core.Promises;
import scuts.core.Pair;
import js.Node;
using acl.njs.RHash;

using acl.Core;

/**
 * ...
 * @author ritchie
 */
 
 typedef TSession<T> = {
 	hash:TRHash<T>
 }
 
 
@:coreType abstract TSessionID from String { }

typedef TSessionInfo<T> = Pair<TSessionID,T>;

class Session {

	static var uuid:Dynamic;

	public static function init<T>(?port:Int,?host:String,?options:Dynamic):TOutcome<String,TSession<T>> {
		var oc = Core.outcome();
		uuid = Node.require('node-uuid');
		RHash.init(port,host,options);
		oc.complete(Success({hash:RHash.create("session")}));
		return oc;
	}
	
	public static function create<T>(sess:TSession<T>,o:T):TOutcome<String,TSessionID> {
		var sID:String = uuid.v1();
		return sess.hash.set(sID,o).map(function(reply) {
			return cast sID;
		});
	}
	
	public static function update<T>(sess:TSession<T>,sID:TSessionID,o:T) {
		return sess.hash.set(cast sID,o);
	}
	
	public static function get<T>(sess:TSession<T>,sID:TSessionID):TOutcome<String,TOption<T>> {
		return sess.hash.get(cast sID);
	}
	
	public static function del<T>(sess:TSession<T>,sID:TSessionID) {
		var s = cast sID;
		return sess.hash.remove(cast sID);
	}
		
}
