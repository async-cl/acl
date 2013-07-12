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

typedef TExpress = {
    @:overload(function(path:String,middleware:Dynamic):Void {})
    function use(middleware:Dynamic):Void;
    function locals(obj:Dynamic):Void;
    function set(name:String,obj:Dynamic):Void;
    @:overload(function(name:String):Dynamic {})
    function get(url:String,fn:TExpressReq->TExpressResp->Void):Void;
    function post(url:String,fn:TExpressReq->TExpressResp->Void):Void;
    function put(url:String,fn:TExpressReq->TExpressResp->Void):Void;
};


typedef TExpressServerAttrs = {
	host:String,
	port:Int,
	?serverName:String
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

class Express {

	static var express:Dynamic;

	public static function module():Dynamic {
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

    
    public static function create():TExpress {
        module();
        return untyped __js__("acl.njs.Express.express()");
        
    }
		
}