package acl.njs.entity;

using scuts.core.Validations;
using scuts.core.Promises;
using scuts.core.Functions;
using scuts.core.Options;
using scuts.core.Arrays;

using acl.Core;
import acl.njs.Sys.Assert in A;
using acl.njs.Express;
using acl.njs.Entity;

typedef TInsertFile = {
	formFld:String,
	file:TExpressFile,
	requiredName:String
}

/**
 * ...
 * @author Ritchie Turner
 */
class Extras {
	
	public static function getFiles(req:TExpressReq):Array<TInsertFile> {
		if (req.files == null)
			return [];
		

		var formNames = Reflect.fields(req.files);
		var requiredName = Reflect.field(req.body,"__requiredName__");
		Reflect.deleteField(req.body,"__requiredName__");
		
		return formNames.foldLeft([],function(acc,key) {
			acc.push({
				formFld:key,
				file:cast Reflect.field(req.files,key),
				requiredName:requiredName
			});
			return acc;
		});
	}
	
	/**
		Return the newly inserted entity with _attachments info.
	*/
	public static function insertWithImage<T:TEntity>(entity:T,files:Array<TInsertFile>):TOutcome<String,T> {
		
		A.ok(Reflect.field(entity,"docType") != null,"entity must have docType before insertion");
		
		return Core.chain()
		.link(function(d) {
			return Entity.insert(entity);
		}).link(function(ref:TEntityRef) {
			return attachFiles(ref,files);
		}).link(function(ref) {
			return Entity.get(ref._id); // need to get the entity again for the attachment info
		}).dechain();
	}
	
	static function attachFiles(entityRef:TEntityRef,files:Array<TInsertFile>):TOutcome<String,TEntityRef> {
        var oc = Core.outcome();
        var curFile = files[0];
		js.Node.fs.readFile(curFile.file.path,function(err,data) {
           	if (err != null) {
           		oc.complete(Failure(err));
            } else {
            	var name = (curFile.requiredName != null) ? curFile.requiredName : curFile.file.name;
            	trace("inserting file "+name);
				Entity.attach(entityRef,name,data,curFile.file.mime).onSuccess(function(er:TEntityRef) {
					oc.complete(Success(er));
				});
			}
		});
		return oc;
	}
}

		