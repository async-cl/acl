package acl.njs;

/**
 * ...
 * @author ritchie
 */

using scuts.core.Validation;
using scuts.core.Validations;
using scuts.core.Options;
import scuts.core.Pair;

using acl.Core;
using acl.njs.Express;
using acl.njs.ExpressApp;
using acl.njs.Session;
using acl.njs.Sys;

typedef TExpressApp = TExpress;

class ExpressApp {

    static var stylus:Dynamic = js.Node.require("stylus");

    public static function create():TExpress {
	    var app = Express.create();
	    app.use(Express.module().favicon());
	    app.use(Express.module().logger("dev"));
	    app.use(Express.module().bodyParser());
	    app.use(Express.module().errorHandler());
	    app.locals({ pretty : true});
	    return app;
    }
    
    public static function addStatic(app:TExpressApp,dir) {
        trace("setting static "+Sys.path.join(Sys.dirname,dir));
	    app.use(Express.doStatic(Sys.path.join(Sys.dirname,dir)));
	    return app;
    }
    
    public static function addMount(app:TExpressApp,mountPoint:String,dir:String) {
        trace("mounting "+dir + " on "+mountPoint);
	    app.use(mountPoint,Express.doStatic(dir));
	    return app;
    }
    
    public static function addJade(app:TExpressApp,jadeDir:String) {
	    app.set("views",Sys.dirname + "/" + jadeDir);
	    app.set("view engine","jade");

        trace("setting jade directory to "+jadeDir);
	    return app;
    }
    
    public static function addStylus(app:TExpressApp,from,to) {
	    var compileMethod = function(str,path) {
            trace("stylus to "+path);
		    return stylus(str).set("compress",true).set("filename",path);
	    };

        var cnf = { debug : true,
                    force : true,
                    src : Sys.dirname + "/" + from,
                    dest : Sys.dirname + "/" + to,
                    compress:true
                 //   compile : compileMethod
                  };
        
	    app.use(stylus.middleware(cnf));

        trace("setting stylus mapping from "+cnf.src+" to "+cnf.dest);
        
	    return app;
    }
    
    public static function addCookies(app:TExpressApp,cookiePw:String,cookieKey:String) {
	    app.use(Express.module().cookieParser(cookiePw));
	    app.use(Express.module().cookieSession({
            key : cookieKey,
            cookie : { path : "/",
                       httpOnly : false,
                       maxAge : null
                     }
        }));

        trace("setting cookie pw/key to "+cookiePw+"/"+cookieKey);
        
	    return app;
    }
    
    public static function appName(app:TExpress,name) {
	    app.set("app_name",name);
	    return app;
    }
        
    public static function serve(app:TExpressApp,port:Int,?host:String):TOutcome<String,TExpressApp> {
	    var oc = new scuts.core.Promise();
	    if(host == null) host = "localhost";
	    var server = js.Node.http.createServer(cast app);
	    server.listen(port,null,function() {
		    var n = app.get("app_name");
		    if (n == null) n = "Listening " else n + " listening ";
		    trace(n + "on port " + port);
		    oc.complete(scuts.core.Validation.Success(app));
	    });
	    return oc;
    }

    public static function onCompletedReply<E,T>(oc:TOutcome<E,T>,res) {
	    oc.onComplete(function(v) {
		    res.send(200,haxe.Serializer.run(v));
		    return null;
	    });
    }
    
    public static function validationReply<T>(v:Validation<String,T>,res) {
	    res.send(200,haxe.Serializer.run(v));
    }

}