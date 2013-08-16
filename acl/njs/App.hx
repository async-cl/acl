package acl.njs;

/**
 * ...
 * @author ritchie
 */
using scuts.core.Arrays;
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
	httpPort:Int,
    express: {
        root:String,
        mountPoints:Array<String>,
        jade:String,
        stylus:Array<String>,
        cookie:Array<String>
    }
};  
   
typedef TApp<T> = {
	db:TCouchDb,
	express:TExpressApp,
	config:TConfig,
	session:TSession<T>
};


typedef TAppReq<T> = { > TExpressReq,
   acl:TApp<T>
}

typedef TAppRes = TExpressResp;

class App {
    
	public static function create<T>(configPath):TOutcome<String,TApp<T>> {	
		var config:TConfig = null;
        var express:TExpressApp;
        var session:TSession<Dynamic>;
		return loadConfig(configPath)
		    .fmap(function(cnf:TConfig) {
			    config = cnf;
                "Init Session".logHeader();
			    return Session.init();
		    }).fmap(function(s) {
			    session = s;
			    "Init Express".logHeader();
			    return initExpress(config);
            }).fmap(function(exp:TExpress) {
                express = exp;
                var app = {
                    db:null,
                    express:express,
                    config:config,
                    session:session
                };

                exp.use(function(req,res,next) {
                    Reflect.setField(req,"acl",app);
                    next();
                });
                
                return Core.success(app);
            }).fmap(function(app:TApp<T>) {
                // the app without db, do we have a db?
                return if (config.db != null) {
                    "CouchDb".logHeader();
                    CouchDb.db(config.db,false).fmap(function(db) {
                        app.db = db;
                        Entity.init(new CouchEntityDriver(db));
                        Relations.init(db);
                        ApiEntity.addRoutes(app);
                        return Core.success(app);
                    });
                } else Core.success(app);
            });
	}

	public static function post<T>(app:TApp<T>,url:String,fn:TAppReq<T>->TAppRes->Void) {
		app.express.post(url,cast fn);
	}
	
	public static function get<T>(app:TApp<T>,url:String,fn:TAppReq<T>->TAppRes->Void) {
		app.express.get(url,cast fn);
	}
	
	public static function loadConfig<T>(configPath:String):TOutcome<String,TConfig> {
        return Sys.readFile(configPath).fmap(function(cnf:String) {
            return Core.success(haxe.Json.parse(cnf));
        });
	}

	static function initExpress<T>(config:TConfig) {
        var cnf = config.express;
        var exp = ExpressApp.create();
   
        exp.addJade((cnf.jade != null) ? cnf.jade : "Jade");
        
        if (cnf.stylus != null) {
            exp.addStylus(cnf.stylus[0],cnf.stylus[1]);
        } else
            exp.addStylus("Stylus","Public/css");
        
        if (cnf.cookie != null) {
            exp.addCookies(cnf.cookie[0],cnf.cookie[1]);
        }
        
        if (cnf.mountPoints != null) {
            Core.partition(cnf.mountPoints,2).each(function(mp) {
                exp.addMount(mp[0],mp[1]);
            });
        }
        
        exp.addStatic(cnf.root);        
        return exp.serve(config.httpPort);
	}
	
	public static function getsID(req:TAppReq<Dynamic>):TSessionID {
		#if TEST
			return js.Node.fs.readFileSync("cmd_session.txt");
		#else
    	var sc = req.signedCookies;
    	var cookie = Reflect.field(sc,req.acl.config.express.cookie[1]);
    	if (cookie != null) {
        	return Reflect.field(cookie,"sID");
        }
        return null;
        #end
    }

    public static function checkSession<T>(req:TAppReq<T>):TOutcome<String,TSessionInfo<T>> {
		var sID:TSessionID = App.getsID(req);
	    return Session.get(req.acl.session,sID).fmap(function(sub:TOption<T>) {
			return (sub.isSome())? Core.success(Pair.create(sID,sub.extract())) : Core.failure("No session");
		});
    }

    public static function logout<T>(req:TAppReq<T>):TOutcome<String,String> {
        var sID = App.getsID(req);
        return req.acl.session.del(sID).fmap(function(v){
            trace('clearing cookies'+req.session);
            Reflect.deleteField(req.session,"caan");
            req.session = null;
            return Core.success("ok");
        });
    }
	
}
