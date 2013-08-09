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
	static var _driver:EntityDriver;
	static var _event:Event<TEntityEvent<Dynamic>> = Core.event();
	
   	public static function init(db:EntityDriver) {
   		trace("init Entity");
   		_driver = db;
   	}
		
	public static function delete<T>(entity:TEntityRef,?info:T):TOutcome<String,String> {
		return _driver.delete(entity,info).fmap(function(v) {
			_event.emit(AfterDelete(entity,info));
			return Core.success("ok");
		});
	}
	
	public static function on<T>(fn:TEntityEvent<T>->Void) {
		_event.on(cast fn);
	}
	
	public static function insert<T>(entity:TEntity,?id:String,?info:T):TOutcome<String,TEntityRef> {
		var isFirstTime = entity._id == null && entity._rev == null;
		return _driver.insert(entity,id).fmap(function(er) {
			entity._id = er._id;
			entity._rev = er._rev;
			trace('got post insert event for ${entity.docType} firstTime? ${isFirstTime}');
			_event.emit((isFirstTime) ? AfterCreate(entity,info) : AfterUpdate(entity,info));
			return Core.success(er);
		});
	}

	/**
		Good for getting attachment info in one fell swoop.
	*/
	public static function insert_<T:TEntity>(s:TEntity):TOutcome<String,T> {
    	return insert(s).fmap(function(er:TEntityRef) {
    		return Entity.get(er._id);
    	});
    }
    
	public static function get<T>(id:TEntityID):TOutcome<String,T> {
		return _driver.get(cast id);
	}
	
	public static function link(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,TEntityRef> {
		return Relations.link(relation,parent._id,child._id);
	}
	
	public static function unlink(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,String> {
		return Relations.unlink(relation,parent._id,child._id);
	}
	
	public static function children<T>(relation:TRelation,parent:TEntityBase):TOutcome<String,Array<T>> {
		return Relations.linked_(relation,parent._id);
	}
	
	public static function inverse<T>(relation:TRelation,child:TEntityBase):TOutcome<String,Array<T>> {
		return Relations.inverse_(relation,child._id);
	}
	
	public static function view<T>(view:String,?params:TEntityKeys,includeDocs=false):TOutcome<String,Array<T>> {
		return _driver.view(view,params,includeDocs);
	}

	public static function attach(entityRef:TEntityRef,name:String,data:Dynamic,mimeType:String):TOutcome<String,TEntityRef> {
    	return _driver.attach(cast entityRef,name,data,mimeType);
    }
}
