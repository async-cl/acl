package acl.njs;

import js.Node;
using acl.Core;
using scuts.core.Validations;
using scuts.core.Validation;
using scuts.core.Strings;
/**
 * ...
 * @author ritchie
 */

typedef TExpressServerAttrs = {
	host:String,
	port:Int,
	?serverName:String
};

typedef TExpressServer = { > TExpressServerAttrs,
	_app:TExpressApp,
	_creds:Dynamic,
	_server:NodeHttpServer,
};


typedef TExpressFile = {
	size:Int,
	path:String,
	name:String,
	type:String,
	length:Int,
	fileName:String,
	mime:String
}	

typedef TExpressReq = {
	var params:Dynamic;
	var query:Dynamic;
	var body:Dynamic;
	var files:Dynamic;	
	function param(name:String):Dynamic;
	function route():String;
	var cookies:String;
	var session:Dynamic;
	var signedCookies:String;
	function get(field:String):String;
	function types(type:String):String;
	function accepted():Array<{value:String,quality:Int,type:String,subtype:String}>;
	function is(type:String):Bool;
	var ip:String;
	var path:String;
	var host:String;
	var fresh:Bool;
	var stale:Bool;
	var xhr:Bool;
	var protocol:String;
	var secure:Bool;
	var subdomains:Array<String>;
	var originalUrl:String;
	var acceptedLanguages:Array<String>;
	var acceptedCharsets:Array<String>;
	function acceptsCharse(charset:String):Void;
	function acceptsLanguage(lang:String):Void;
}

typedef TExpressCookie = {
	?domain:String,
	?path:String,
	?secure:Bool,
	?signed:Bool,
	?expires:Float,
	?httpOnly:Bool
};

typedef TExpressResp = {
	function status(code:Int):Void;
	function set(field:String,value:String):String;
	function get(field:String):String;
	function cookie(name:String,value:String,?options:TExpressCookie):Void;
	function clearCookie(name:String,options:TExpressCookie):Void;
	function redirect(?status:Int,url:String):Void;
	function location(loc:String):Void;
	var charset:String;
	var send:Int->Dynamic->Void;
	function json(status:Int,body:Dynamic):Void;
	function type(type:String):Void;
	function format(obj:Dynamic):Void;
	function attachment(path:String):Void;
	function sendfile(path:String,options:Dynamic,fn:String->Void):Void;
	function download(path:String,options:Dynamic,fn:String->Void):Void;
	function links(links:{next:String,last:String}):Void;
	var locals:Dynamic;
	function render(view:String,locals:Dynamic,?fn:String->String):Void;
}

typedef TExpressApp = {
	function use(?mountpoint:String,d:Dynamic):Void;
	function get(url:String,?handler:TExpressReq->TExpressResp->Void):Dynamic;
	function post(url:String,handler:TExpressReq->TExpressResp->Void):Void;
	function put(url:String,handler:TExpressReq->TExpressResp->Void):Void;
	function set(url:String,val:Dynamic):Void;
	var locals:Dynamic;
	function configure(fn:Void->Void):Void;
}


class Express {

	static var express:Dynamic;

	public static function module() {
		if (express == null)
			express = Node.require("express");
			
		return express;
	}

	/*
		Can't use "static" explicitly
	*/	
	public static function doStatic(s):Dynamic {
		return untyped __js__("acl.njs.Express.express.static(s)");
	}

	public static function create(attrs:TExpressServerAttrs):TExpressServer {
		if (express == null)
			express = Node.require("express");
		
		return {
			_app: untyped __js__("acl.njs.Express.express()"),
			host:attrs.host,
			port:attrs.port,
			_creds:null,
			_server:null,
			serverName:(attrs.serverName == null) ? "Acl HttpServer" : attrs.serverName
		};
	}
	
	public static function start(srv:TExpressServer):TOutcome<String,TExpressServer> {
		var oc = Core.outcome();
		srv._app.set("port",srv.port);
		srv._server = Node.http.createServer(cast srv._app);
		srv._server.listen(cast srv._app.get('port'),function() {
			trace(srv.serverName + " "+ srv._app.get('port'));
			oc.complete(Success(srv));
		});
	    return oc;
	}
	
	public static function get(srv:TExpressServer,url:String,fn:TExpressReq->TExpressResp->Void):TExpressServer {
		srv._app.get(url,fn);
		return srv;
	}
	
	public static function post(srv:TExpressServer,url:String,fn:TExpressReq->TExpressResp->Void):TExpressServer {
		srv._app.post(url,fn);
		return srv;
	}

	public static function put(srv:TExpressServer,url:String,fn:TExpressReq->TExpressResp->Void):TExpressServer {
		srv._app.put(url,fn);
		return srv;
	}

	public static function use(srv:TExpressServer,f:Dynamic,?s:Dynamic) {
		srv._app.use(f,s);
	}	

	public static function set(srv:TExpressServer,k:String,v:Dynamic) {
		srv._app.set(k,v);
	}

	public static function configure(srv:TExpressServer,fn:Void->Void) {
		srv._app.configure(fn);
	}
	
	public static function locals(srv:TExpressServer,l:Dynamic) {
		srv._app.locals = l;
	}
	
	public static function onCompletedReply<F,S>(oc:TOutcome<F,S>,res:TExpressResp) {
		oc.onComplete(function(v) {
			validationReply(v,res);
			return null;
		});
	}
	
	public static inline function validationReply<F,S>(v:TVal<F,S>,res:TExpressResp) {
		res.send(200,haxe.Serializer.run(v));
	}
	
	
}