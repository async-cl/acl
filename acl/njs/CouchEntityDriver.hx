package acl.njs;

using scuts.core.Options;
using scuts.core.Promises;
using scuts.core.Validations;
using scuts.core.Functions;

using acl.Core;
using acl.njs.CouchDb;
using acl.njs.Entity;
using acl.njs.entity.ApiEntity;


class CouchEntityDriver implements EntityDriver {

	static var _db:TCouchDb;
	static var _event:Event<TEntityEvent<Dynamic>> = Core.event();
	
   	public function new(db:TCouchDb) {
   		trace("init Couch Entity Driver");
   		_db = db;
   	}
		
	public function delete<T>(entity:TEntityRef,?info:T):TOutcome<String,String> {
        trace("yes doing delete with "+entity);
		return _db.delete(entity._id,entity._rev).fmap(function(v) {
			_event.emit(AfterDelete(entity,info));
			return Core.success("ok");
		});
	}
	
	public function on<T>(fn:TEntityEvent<T>->Void) {
		_event.on(cast fn);
	}
	
	public function insert(entity:TEntity,?id:String,?info:Dynamic):TOutcome<String,TEntityRef> {
		var isFirstTime = entity._id == null && entity._rev == null;
		return _db.insert_(entity,id).fmap(function(er) {
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
	public function insert_<T:TEntity>(entity:T):TOutcome<String,T> {
    	return insert(entity).fmap(function(er:TEntityRef) {
    		return Entity.get(er._id);
    	});
    }
    
	public function get<T>(id:TEntityID):TOutcome<String,T> {
		return _db.get_(cast id);
	}
	
	public function link(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,TEntityRef> {
		return Relations.link(relation,parent._id,child._id);
	}
	
	public function unlink(relation:TRelation,parent:TEntityBase,child:TEntityBase):TOutcome<String,String> {
		return Relations.unlink(relation,parent._id,child._id);
	}
	
	public function children<T>(relation:TRelation,parent:TEntityBase):TOutcome<String,Array<T>> {
		return Relations.linked_(relation,parent._id);
	}
	
	public function inverse<T>(relation:TRelation,child:TEntityBase):TOutcome<String,Array<T>> {
		return Relations.inverse_(relation,child._id);
	}
	
	public function view<T>(view:String,?params:TEntityKeys,includeDocs:Bool):TOutcome<String,Array<T>> {
		return _db.view_('wise',view,params,includeDocs);
	}

	public function attach(entityRef:TEntityRef,name:String,data:Dynamic,mimeType:String):TOutcome<String,TEntityRef> {
    	return _db.attach(cast entityRef._id,cast entityRef._rev,name,data,mimeType);
    }
    



}