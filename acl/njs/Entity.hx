package acl.njs;


using scuts.core.Validations;
using scuts.core.Promises;
using scuts.core.Functions;
using scuts.core.Options;

using acl.Core;
using acl.njs.Express; 
using acl.njs.Session;
using acl.Http;
using acl.njs.RHash;
using acl.njs.Relations;
using acl.njs.CouchDb;


/**
 * ...
 * @author Ritchie Turner
 */
class Entity {
	static var _db:TCouchDb;
	
   	public static function init(db:TCouchDb) {
   		trace("init Entity");
   		_db = db;
   	}
	
	public static function ref(entity:TEntity):TEntityRef {
		return {_id:entity._id,_rev:entity._rev};
	}
	
	public static function delete(entity:TEntityRef):TOutcome<String,String> {
		return _db.delete(cast entity._id,cast entity._rev).fmap(function(v) {
			return Core.success("ok");
		});
	}
	
	public static function insert(entity:TEntity,?id:String):TOutcome<String,TEntityRef> {
		return _db.insert_(entity,id);
	}

	/**
		Good for getting attachment info in one fell swoop.
	*/
	public static function insert_<T:TEntity>(s:T):TOutcome<String,T> {
    	return Core.chain()
    	.link(function(d) {
    		return insert(s);
    	}).link(function(er:TEntityRef) {
    		return Entity.get(er._id);
    	}).dechain();
    }
    
	public static function get<T:TEntity>(id:TEntityID):TOutcome<String,T> {
		return _db.get_(cast id);
	}
	
	public static function link(relation:TRelation,parent:TEntityRef,child:TEntityRef):TOutcome<String,TEntityRef> {
		return Relations.link(relation,parent._id,child._id);
	}
	
	public static function view<T:TEntity>(view:String,?params:TCouchKeys,includeDocs=false):TOutcome<String,Array<T>> {
		return _db.view_('wise',view,params,includeDocs);
	}

	public static function attach(entityRef:TEntityRef,name:String,data:Dynamic,mimeType:String):TOutcome<String,TEntityRef> {
    	return _db.attach(cast entityRef._id,cast entityRef._rev,name,data,mimeType);
    }
}
