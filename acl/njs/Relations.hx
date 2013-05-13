package acl.njs ;

using scuts.core.Promises;
using scuts.core.Validations;
using scuts.core.Functions;

/**
 * ...
 * @author Ritchie Turner
 */
 
 using acl.Core;
 using acl.njs.CouchDb;
 using scuts.core.Options;
 
 import acl.njs.Sys.Assert in A;
 
class Relations {

	static var db:TCouchDb;
															
	public static function init(tdb:TCouchDb) {
		trace("init Relations");
		db = tdb;
	}
	
	public static function create(name:String):TRelation {
		return {
			name:name
		};
	}
	
	public static function link(r:TRelation,parentID:TEntityID,childID:TEntityID):TOutcome<String,TEntityRef> {
		A.ok(childID,"childID must be set");		
		return db.insert_({id1:parentID,id2:childID,rel:r.name,docType:"relation"});
	}
	
	public static function linkWithInsert(r:TRelation,parentID:TEntityID,child:TEntity):TOutcome<String,TEntityRef> {
		//first insert the child object ...
		return db.insert_(child).fmap(function(childIDRev) {
			// then relate the child to the parent
			return link(r,parentID,childIDRev._id);
		});
	}
	
	/**
		Remove the relation to the child object. Note, this does not delete the child, just the relation.
	*/
	public static function unlink(r:TRelation,parentID:TEntityID,childID:TEntityID):TOutcome<String,String> {
		var oc = Core.outcome();
		db.view("wise","rel-child-parent",KEY([r.name,parentID,childID])).onComplete(function(v) {
			if (v.isSuccess()) {
				var z = v.extract();
				if (z.body.rows.length == 1) {
					var rel = z.body.rows[0].value;
					db.delete(rel._id,rel._rev).onComplete(function(f) {
						if (f.isSuccess()) 
							oc.complete(Success("ok"));
						else
							oc.complete(Failure(f.extractFailure()));
						return null;
					});
				} else {
					oc.complete(Failure("Can't find child in relation"));
				}
			} else {
				oc.complete(Failure(v.extractFailure()));
			}
			return null;
		});
		return oc;
	}
	
	public static function linked<T>(r:TRelation,parentID:TEntityID):TOutcome<String,TReplyRows<T>> {
		return db.view("wise","rel-parent-child",KEY([r.name,parentID]),true);
	}
	
	public static function linked_<T>(r:TRelation,parentID:TEntityID):TOutcome<String,Array<T>> {
		return linked(r,parentID).map(Validations.flatMap._2(function(r:TReplyRows<T>) {
			return Success(r.body.rows.map(function(row) { return row.doc;}));
		}));
	}

}

