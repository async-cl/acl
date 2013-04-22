package acl.njs;

using acl.Core;
import scuts.core.Validation;
import js.Node;

/**
 * ...
 * @author ritchie
 */
 
 typedef TSession = {
 	redis:Dynamic,
 }
 
class Session {
	static var uuid:Dynamic;


	public static function init(?port:Int,?host:String,?options:Dynamic):TOutcome<String,TSession> {
		var oc = Core.outcome();
		uuid = Node.require('node-uuid');
		oc.complete(Success({redis:Node.require('redis').createClient(port,host,options)}));
		return oc;
	}
	
	public static function create(sess:TSession,o:Dynamic):TOutcome<String,String> {
		var oc = Core.outcome();
		var sID = uuid.v1();
		sess.redis.set(sID,haxe.Serializer.run(o),function(err) {
			oc.complete((err != null) ? Failure(err) : Success(sID));
		});
		return oc;
	}
	
	public static function update<T>(sess:TSession,sID:String,o:T) {
		var oc = Core.outcome();
		sess.redis.set(sID,haxe.Serializer.run(o),function(err) {
			oc.complete((err != null) ? Failure(err) : Success(sID));
		});
		return oc;
	}
	
	public static function get<T>(sess:TSession,sID):TOutcome<String,T> {
		var oc = Core.outcome();
		sess.redis.get(sID,function(err,o) {
			oc.complete((err != null) ? Failure(err) : Success(haxe.Unserializer.run(o)));
		});
		return oc;
	}
	
	public static function del(sess:TSession,sID:String) {
		var oc = Core.outcome();
		sess.redis.del(sID,function(err) {
			oc.complete((err != "OK") ? Failure(err) : Success(sID));
		});
		return oc;
	}
		
}
