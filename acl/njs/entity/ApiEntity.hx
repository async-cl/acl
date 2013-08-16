package acl.njs.entity;

using acl.Core;
using acl.EClient;
using acl.njs.Session;
using acl.njs.Entity;

using acl.njs.Express;
using acl.njs.ExpressApp;
using acl.njs.App;
using acl.njs.entity.Extras;
using acl.njs.Relations;


/**
 * ...
 * @author Ritchie Turner
 */
class ApiEntity {
	
	public static function addRoutes<T>(app:TApp<T>) {
		trace("ApiEntity addroutes");
		app.post(EClient.urlEntityInsert,insertEntity);
		app.post(EClient.urlEntityDelete,deleteEntity);
		app.post(EClient.urlEntityLink,linkEntity);
		app.post(EClient.urlEntityUnlink,unlinkEntity);
		app.post(EClient.urlEntities,listEntity);
		app.post(EClient.urlEntityInsertWithImage,insertWithImage);
		app.post(EClient.urlEntityGet,getEntity);
		app.post(EClient.urlEntityChildren,children);
		app.post(EClient.urlEntityParents,parents);
	}
	
	public static function insertEntity<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
            .fmap(function(si:TSessionInfo<Dynamic>) {
			    var e:TEntity = req.body.e;
			    return e.insert();
		    }).onCompletedReply(res);
	}
	
	public static function deleteEntity<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var e:TEntityRef = req.body.er;
			    return e.delete();
		    }).onCompletedReply(res);
	}
	
	public static function linkEntity<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var parent:TEntityBase = req.body.p;
			    var child:TEntityBase = req.body.c;
			    var relationName:String = req.body.relation;
			    var relation = Relations.create(relationName);
			    return Entity.link(relation,parent,child);
		    }).onCompletedReply(res);
	}
	
	public static function unlinkEntity<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var parent:TEntityBase = req.body.p;
			    var child:TEntityBase = req.body.c;
			    var relationName:String = req.body.relation;
			    var relation = Relations.create(relationName);
			    return Entity.unlink(relation,parent,child);
		    }).onCompletedReply(res);
	}
	
	public static function insertWithImage<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var entity:TEntity = req.body;
			    trace("files :"+req.files);
			    var files = Extras.getFiles(req);
			    if (files.length > 0)
				    return entity.insertWithImage(files);
			    else
				    return Entity.insert_(entity);
		    }).onCompletedReply(res);
	}
	
	public static function listEntity<T>(req:TAppReq<T>,res:TExpressResp) {
//		req.checkSession()
//		.link(function(si:TSessionInfo<Dynamic>) {
			var view = req.body.entityType;
			var prms:TEntityKeys = null;
			if (req.body.prms)
				prms = haxe.Unserializer.run(req.body.prms);
				
	    Entity.view(view,prms).onCompletedReply(res);
	}
	
	public static function getEntity<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var id:TEntityID = req.body.id;
			    return Entity.get(id);
		    }).onCompletedReply(res);
	}
	
	public static function children<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		    .fmap(function(si:TSessionInfo<Dynamic>) {
			    var relation:String = req.body.relation,
				parent:TEntityID = req.body.id;
			    return Entity.children(Relations.create(relation),{_id:parent});
		    }).onCompletedReply(res);
	}

	public static function parents<T>(req:TAppReq<T>,res:TExpressResp) {
		req.checkSession()
		.fmap(function(si:TSessionInfo<Dynamic>) {
			var relation:String = req.body.relation,
			child:TEntityID = req.body.id;
			return Entity.inverse(Relations.create(relation),{_id:child});
		}).onCompletedReply(res);
	}

}

