
package acl.njs;


/* Depends on Nano 
	npm install nano
*/

import js.Node;

using scuts.core.Options;
using scuts.core.Promises;
using scuts.core.Validations;
using scuts.core.Functions;

using acl.Core;


typedef TCouchIDRev = TEntityRef;
typedef  TCouchObj = TEntity;

typedef TCouchConf = {
	server:String,
	name:String,
	user:String,
	password:String,
};  

typedef TCouch = {
	_user:String,
	_password:String,
	_url:String,
	_cookie:String
};

typedef TCouchDb = {
	_bucket:Dynamic
}

enum TCouchKeys {
	KEY(params:Dynamic);
	KEYS(params:Array<Dynamic>);
}

typedef TCouchHeaders = {
	location:String,
	date:String,
	uri:String
	/*can't spec
	cache-control
	content-type
	status-code
	*/
};

typedef TCouchBody = {
	ok:Bool,
	id:String,
	rev:String
};

typedef TReply = {body:TCouchBody,headers:TCouchHeaders};
typedef TReplyHead = {headers:TCouchHeaders};

typedef TReplyFile = {file:Dynamic};

typedef TCouchRows<T> = {
	id:String,
	key:String,
	value:T,
	?doc:T
};

typedef TCouchRowBody<T> = {
	total_rows:Int,
	offset:Int,
	rows:Array<TCouchRows<T>>
}

typedef TReplyRows<T> = {
	body:TCouchRowBody<T>,
	headers:TCouchHeaders	
};

typedef TReplyGet = {
	body: {
		_id:String,
		_rev:String,
	},
	headers: {
		etag:String,
		date:String,
		uri:String
	}
};

class CouchDb {
	
	static var N:Dynamic->Dynamic = null;

	static function error(funcName:String,err:String) {
		return "CouchDb."+funcName+" "+err;
	}
	
	public static function db(cnf:TCouchConf,deleteDB=false):TOutcome<String,TCouchDb> {
		return Core.chain()
		.link(function(dummy) {
			return CouchDb.connect(cnf.server,cnf.user,cnf.password);
		}).linkD(function(connection,data) {
			data.connection = connection;
			return if (deleteDB) destroy(connection,cnf.name); else Core.success("ok");
		}).linkD(function(res,data) {
			return if (deleteDB && res == "ok") create(data.connection,cnf.name) else cast Core.success("ok");
		}).linkD(function(res,data) {
			return use(data.connection,cnf.name);
		}).dechain();
	}
	
	public static function connect(url:String,?user:String,?password:String):TOutcome<String,TCouch> {
	
		if (N == null) {
			N = Node.require('nano');
		}

		var instance:Dynamic = N(url);
		var oc = new TPromise<TVal<String,TCouch>>();
		var cdb =  {
			_user:user,
			_password:password,
			_url:url,
			_cookie:null,
		};
		
		if (user != null && password != null) {
			instance.auth(user,password,function(err:String,body,headers) {
				if (err != null) {
					oc.complete(Failure(err));
				} else {
					var cookies:Array<String> = Reflect.field(headers,"set-cookie");
					if (headers && cookies != null) {
						cdb._cookie = cookies[0].split(';')[0].split('=')[1];
					}
					oc.complete(Success(cdb));
				}
			});
		} else {
			oc.complete(Success(cdb));
		}
		return oc;
	}
	
	static inline function session(cdb:TCouch):Dynamic {
		var sess = N({url:cdb._url,cookie:'AuthSession='+cdb._cookie});
		return sess;
	}
	
	public static function use(cdb:TCouch,name:String):TOutcome<String,TCouchDb> {
		var oc = new TPromise<TVal<String,TCouchDb>>();
		var sess = session(cdb);
		var db = sess.db.use(name);
		oc.complete((db == null) ? Failure("Couch:: can't use "+name) : Success({_bucket:db})) ;
		return oc;
	}
		
	public static function create(cdb:TCouch,name:String):TOutcome<String,TCouchDb> {
		var oc = new TPromise<TVal<String,TCouchDb>>();
		session(cdb).db.create(name,function(e,s) {
			oc.complete((e != null) ? Failure(error("create",e)) : Success(s));
		});	
		return oc;
	}
	
	public static function insert(db:TCouchDb,obj:Dynamic,?id:String):TOutcome<String,TReply> {
		var oc = new TPromise<TVal<String,TReply>>();
		db._bucket.insert(obj,id,function(e,body,headers) {
			oc.complete((e != null) ? Failure(error("insert",e)) : Success({body:body,headers:headers}));
		});
		return oc;
	}
	
	public static inline function replyToIDRev(reply:TReply):TCouchIDRev {
		return {_id:reply.body.id,_rev:reply.body.rev};
	}
	
	/**
		Do an insert but just return the id,rev of the newly inserted object.
	*/
	public static function insert_(db:TCouchDb,obj:Dynamic,?id:String):TOutcome<String,TCouchIDRev> {
		return insert(db,obj,id).map(Validations.flatMap._2(function(reply:TReply) {
            return Success(replyToIDRev(reply));
        }));
	}
	
	public static function destroy(cdb:TCouch,name:String):TOutcome<String,String> {
		var oc = new TPromise<TVal<String,String>>();
		trace("destroying "+name);
		var sess = session(cdb);
		sess.db.destroy(name,function(err) {
			oc.complete((err != null) ? Failure(error("destroy",err)) : Success("ok"));
		});
		return oc;
	}
	
	public static function delete(db:TCouchDb,id:String,rev:String):TOutcome<String,TReply> {
		var oc = new TPromise<TVal<String,TReply>>();
		db._bucket.destroy(id,rev,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("delete",err)) : Success({body:body,headers:headers}));
		});
		return oc;
	}
	
	public static function get(db:TCouchDb,id:String,?params:Dynamic):TOutcome<String,TReplyGet> {
		var oc = new TPromise<TVal<String,TReplyGet>>();
		db._bucket.get(id,params,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("get",err)) : Success({body:body,headers:headers}));
		});
		return oc;
	}
	
	public static function get_<S>(db:TCouchDb,id:String,?params:Dynamic):TOutcome<String,S> {
		var oc = new TPromise<TVal<String,S>>();
		db._bucket.get(id,params,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("get_",err)) : Success(body));
		});
		return oc;
	}
	
	public static function head(db:TCouchDb,id:String,?params:Dynamic):TOutcome<String,TReplyHead> {
		var oc = new TPromise<TVal<String,TReplyHead>>();
		db._bucket.head(id,params,function(err,body) {
			oc.complete((err != null) ? Failure(error("head",err)) : Success({headers:body}));
		});
		return oc;
	}
	
	public static function list<T>(db:TCouchDb,?params:Dynamic):TOutcome<String,TReplyRows<T>> {
		var oc = new TPromise<TVal<String,TReplyRows<T>>>();
		db._bucket.list(params,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("list",err)) : Success({body:body,headers:headers}));
		});
		return oc;
	}
	
	public static function fetch<T>(db:TCouchDb,ids:Array<String>,?params:Dynamic):TOutcome<String,TReplyRows<T>> {
		if (params == null)
			params = {};
			
		var oc = new TPromise<TVal<String,TReplyRows<T>>>();
		db._bucket.fetch({keys:ids},params,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("fetch",err)) : Success({body:body,headers:headers}));
		});
		return oc;
	}
	
	public static function getAttach(db:TCouchDb,id:String,fileName:String):TOutcome<String,TReplyFile> {
		var oc = new TPromise<TVal<String,TReplyFile>>();
		db._bucket.attachment.get(id,fileName,function(err,body) {
			oc.complete((err != null) ? Failure(error("getAttach",err)) : Success({file:body}));
		});
		return oc;
	}
	

	public static function attach(db:TCouchDb,id:String,rev:String,name:String,data:Dynamic,mimeType):TOutcome<String,TCouchIDRev> {
		var oc = new TPromise<TVal<String,TCouchIDRev>>();
		db._bucket.attachment.insert(id,name,data,mimeType,{rev:rev},function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("putAttach",err)) : Success(replyToIDRev({body:body,headers:headers})));
		});
		return oc;
	}
	
	public static function view<T>(db:TCouchDb,design:String,view:String,?params:TCouchKeys,includeDocs=false):TOutcome<String,TReplyRows<T>> {
		var oc = new TPromise<TVal<String,TReplyRows<T>>>();
	
		var p:Dynamic = if (params == null) {} else switch(params) {
			case KEY(k): {key:k};
			case KEYS(ks): { keys:ks };
		};
	
		if (includeDocs) {
			Reflect.setField(p,"include_docs",true);
		}
		
		db._bucket.view(design,view,p,function(err,body,headers) {
			oc.complete((err != null) ? Failure(error("view '"+view+"'",err)) : Success({body:body,headers:headers}));
		});
		return oc;
	}

	public static function view_<T>(db:TCouchDb,design:String,viewName:String,?params:TCouchKeys,includeDocs=false):TOutcome<String,Array<T>> {
		return 
			view(db,design,viewName,params,includeDocs)
			.map(Validations.flatMap._2(function(rr:TReplyRows<T>) { 
				return Success(rr.body.rows.map(function(r) return if (includeDocs) r.doc else r.value)); 
			}));
	}
			
	public static function createViews(db:TCouchDb,designName:String,views:Dynamic):TOutcome<String,TReply> {
		var design_doc = {views: {}};
        design_doc.views = views;
        return insert(db,design_doc, '_design/'+designName);
    }
	
     /**
         * Read all of the files in the given dir, interpreting them as couchdb views, and insert
         * them into the database.
         */
    public static function viewsFromDir(db:TCouchDb,designDoc:String,dir:String):TOutcome<String,TReply> {
		var async = Node.require("async");
        var views = {};
        var oc = new TPromise<TVal<String,TReply>>();
        
        function readAscii(f:String,cb:String->Void) {
            Node.fs.readFile(dir+'/'+f,'ascii',function(err,contents) {
                Reflect.setField(views,Node.path.basename(f,'.js'), {map: contents});
                cb(err);
            });
        }
        
        Node.fs.readdir(dir,function(err,files) {
            if (err != null) {
            	oc.complete(Failure(error("viewFromDir1",err)));
            	return;
            }

            async.forEach(files,readAscii,function(err) {
                if (err != null) {
                	oc.complete(Failure(error("ViewsFromDir2",err)));
                } else {
                	createViews(db,designDoc,views).onComplete(function(v) {
                		if(v.isSuccess())
                			oc.complete(Success(v.extract()));
                		else {
                			trace("View create failure "+v.extractFailure());
                			oc.complete(Failure(error("viewsFromDir3",v.extractFailure())));
                		}
                		return null;
                	});
                		
                }
            });  
        });
        return oc;
    }

}