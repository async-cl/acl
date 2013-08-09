package acl.njs;

/**
 * ...
 * @author ritchie
 */
using scuts.core.Validations;
using scuts.core.Options;
import scuts.core.Pair;

using acl.Core;
using acl.njs.CouchDb;
using acl.njs.Entity;
using acl.njs.entity.ApiEntity;
using acl.njs.CouchEntityDriver;
using acl.njs.Express;
using acl.njs.ExpressApp;
using acl.njs.Session;
using acl.njs.Sys;
using acl.njs.Relations;
import acl.njs.RHash;

typedef TConfig = {
	client_js:String,
	activity_center:String,
	db:TCouchConf,
	httpHost:String,
	httpPort:Int
};  

   
typedef TApp<T> = {
	db:TCouchDb,
	express:TExpressApp,
	config:TConfig,
	session:TSession<T>
};

class App {
    
	static var session:TSession<Dynamic>;
    
	public static function create<T>(configPath):TOutcome<String,TApp<T>> {	
		var config:TConfig = null;
        var sess:TSession<T> = null;
        var express:TExpressApp;
        
		return loadConfig(configPath)
		    .fmap(function(cnf:TConfig) {
			    config = cnf;
			    return Session.init();
		    }).fmap(function(s) {
			    sess = s;
			    trace("init Express");
			    return initExpress(config);
            }).fmap(function(exp:TExpress) {
                express = exp;
                return initDb(config);
            }).fmap(function(couch:TCouchDb) {
                return Core.success({db:couch,
                                express:express,
                                config:config,
                                session:sess});
		    }).fmap(function(app:TApp<T>) {
                RHash.init();
			    moduleInit(app.db);
			    routeInit(app);
                session=sess;
                return Core.success(app);
            });
	}
	
	public static function moduleInit(db:TCouchDb) {
		Entity.init(new CouchEntityDriver(db));
		Relations.init(db);
	}
		
	public static function routeInit<T>(app:TApp<T>) {
        ApiEntity.addRoutes(app);
	}
	
	public static function post<T>(app:TApp<T>,url:String,fn:TExpressReq->TExpressResp->Void) {
		app.express.post(url,fn);
	}
	
	public static function get<T>(app:TApp<T>,url:String,fn:TExpressReq->TExpressResp->Void) {
		app.express.get(url,fn);
	}
	
	public static function loadConfig<T>(configPath:String):TOutcome<String,TConfig> {
        return Sys.readFile(configPath).fmap(function(cnf:String) {
            return Core.success(haxe.Json.parse(cnf));
        });
	}
	
	public static function checkSession<T>(req:TExpressReq):TOutcome<String,TSessionInfo<T>> {
		var sID:TSessionID = App.getsID(req);
	    return Session.get(session,sID).fmap(function(sub:TOption<T>) {
			return (sub.isSome())? Core.success(Pair.create(sID,sub.extract())) : Core.failure("No session");
		});
	}

	public static function initDb(cnf:TConfig,deleteFirst = false):TOutcome<String,TCouchDb> {
        return CouchDb.db(cnf.db,deleteFirst);
	}
	
	static function initExpress(config:TConfig) {
        return ExpressApp.create()
            .addStatic('Public')
            .addJade('Jade')
            .addStylus('Stylus','Public/css')
            .addMount('/_js',config.client_js)
            .addCookies('ritchie','caan')
            .serve(config.httpPort);
	}
	
	public static function getsID(req:TExpressReq):TSessionID {
		#if TEST
			return js.Node.fs.readFileSync("cmd_session.txt");
		#else
    	var sc = req.signedCookies;
    	var caan = Reflect.field(sc,"caan");
    	if (caan != null) {
        	return Reflect.field(caan,"sID");
        }
        return null;
        #end
    }
    
	
}
