package acl.njs;

using acl.Core;
using scuts.core.Promises;
import js.Node;
using acl.njs.RHash;

/**
 * ...
 * @author ritchie
 */
 
 typedef TSession<T> = {
 	hash:TRHash<T>
 }
 
class Session {

	static var uuid:Dynamic;

	public static function init<T>(?port:Int,?host:String,?options:Dynamic):TOutcome<String,TSession<T>> {
		var oc = Core.outcome();
		uuid = Node.require('node-uuid');
		RHash.init(port,host,options);
		oc.complete(Success({hash:RHash.create("session")}));
		return oc;
	}
	
	public static function create<T>(sess:TSession<T>,o:T):TOutcome<String,String> {
		var sID = uuid.v1();
		return sess.hash.set(sID,o).map_(function(reply) {
			return sID;
		});
	}
	
	public static function update<T>(sess:TSession<T>,sID:String,o:T) {
		return sess.hash.set(sID,o);
	}
	
	public static function get<T>(sess:TSession<T>,sID):TOutcome<String,TOption<T>> {
		return sess.hash.get(sID);
	}
	
	public static function del<T>(sess:TSession<T>,sID:String) {
		return sess.hash.remove(sID);
	}
		
}
