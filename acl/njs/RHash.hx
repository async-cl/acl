
package acl.njs;

using acl.Core;
import scuts.core.Validation;
import scuts.core.Option;
using scuts.core.Options;
import js.Node;

/**
 * ...
 * @author ritchie
 */
 
 typedef TRHash<T> = {
 	_name:String
 }

 enum TRHashReply {
 	HNew;
 	HUpdated;
 }
   
 // A Redis Hash
 
class RHash {

	static var redis = Node.require('redis');
	static var client:Dynamic;

	public static function init(?port:Int,?host:String,?options:Dynamic) {
		trace("initing client");
		client = redis.createClient(port,host,options);
	}

	public static function create<T>(name:String):TRHash<T> {
		return {
			_name:name
		};
	}
	
	public static function set<T>(h:TRHash<T>,key:String,o:T):TOutcome<String,TRHashReply> {
		var oc = Core.outcome();
		client.hset(h._name,key,haxe.Serializer.run(o),function(err,r) {
			oc.complete((err != null) ? Failure(err) : Success((r==1) ? HNew  : HUpdated));
		});
		return oc;
	}
	
	public static function get<T>(h:TRHash<T>,key:String):TOutcome<String,Option<T>> {
		var oc = Core.outcome();
		client.hget(h._name,key,function(err,o) {
			oc.complete((err != null) ? Failure(err) : Success((o != null) ? Some(haxe.Unserializer.run(o)) : None));
		});
		return oc;
	}
	
	public static function exists<T>(h:TRHash<T>,key:String):TOutcome<String,Bool> {
		var oc = Core.outcome();
		client.hexists(h._name,key,function(err,res) {
			oc.complete((err != null) ? Failure(err) : Success((res == 1) ? true : false));
		});
		return oc;
	}
	
	public static function remove<T>(h:TRHash<T>,key:String):TOutcome<String,Int> {
		var oc = Core.outcome();
		client.hdel(h._name,key,function(err,nremoved) {
			oc.complete((err != null) ? Failure(err) : Success(nremoved));
		});
		return oc;
	}
		
}

