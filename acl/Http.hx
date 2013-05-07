
package acl;

using acl.Core;
using scuts.core.Validations;
using scuts.core.Promises;

#if nodejs
import js.Node;
#else
import js.Browser;
#end

class Http {
		
	public static inline function unpack<F,S>(s:String):TVal<F,S> {
		return haxe.Unserializer.run(s);
	}
		
#if nodejs
	static function doRequest(requester:Dynamic,options:Dynamic):{oc:TOutcome<String,String>,req:NodeHttpClientReq} {
		var oc = Core.outcome();
		var req:NodeHttpClientReq = requester(options,function(response:NodeHttpClientResp) {
	        var buffer = new StringBuf();
        
			response.on("data", function (chunk) {
			    buffer.add(chunk);
			  });
			response.on("end",function() {
			    oc.complete(Success(buffer.toString()));
			  });
		});

		req.on("error",function(e) {
			var err = e.toString();
			oc.complete(Failure(err));
		});		
		
		return {oc:oc,req:req};
	}
      
    static function getPort(protocol:String,port:String):Int {
		if (port != null) {
		    var p = -1;
		    try {
			  p = Std.parseInt(port);
			} catch(e:Dynamic) {
			
			}
			return p;
		}
		    
		if (protocol == "http:" && port == null)
		    return 80;
		if (protocol == "https:" && port == null)
			return 443;

		trace("don't have a default port!");
		return -1;
    }
    
    static function nodeGet(url:String,?params:Dynamic,?headers:Dynamic):TOutcome<String,String> {
    	var
		  pu = Node.url.parse(url),
		  requester = (pu.protocol == "http:") ? Node.http.request : Node.https.request;
		   
		if (headers == null)
		    headers = {};
		  
		var request = doRequest(requester,{
		  host:pu.hostname,
		  port:getPort(pu.protocol,pu.port),
		  method:"GET",
		  path:pu.path+"?"+Node.querystring.stringify(params),
		  headers:headers
		});

		request.req.end();
		return request.oc;
		
    }
    
    static function nodePost(url:String,payload:Dynamic,urlEncoded=true,?headers:Dynamic):TOutcome<String,String> {  
		 var
		  pu = Node.url.parse(url),
		  requester = (pu.protocol == "http:") ? Node.http.request : Node.https.request;

		  
		if (headers == null)
			headers = {};
		      
		if (urlEncoded)
		    Reflect.setField(headers,'Content-Type','application/x-www-form-urlencoded');
		else {
			// set headers accordingly externally
		}

		var request = doRequest(requester,{
			  host:pu.hostname,
			  port:getPort(pu.protocol,pu.port),
			  method:"POST",
			  path:pu.path,
			  headers:headers
		    }); 

		if (urlEncoded) {
		    request.req.write(Node.querystring.stringify(payload));
		} else {
			request.req.write(payload);
		}

		request.req.end();
		return request.oc;
	}
	
#else

	static function haxeRequest(url:String,post=false,?params:Dynamic,?headers:Dynamic):TOutcome<String,String> {
		var oc = Core.outcome();
		var hr = new haxe.Http(url);
		hr.onData = function(d) {
			oc.complete(Success(cast d));
		};
		hr.onError =function(e) {
			oc.complete(Failure(e));
		};
		
		if (post) {
			hr.setPostData(params);
		} else {
			if (params != null) {
				for (f in Reflect.fields(params)) {
					hr.setParameter(f,Reflect.field(params,f));	
				}
			}
		}
		
		if (headers != null) {
			for (f in Reflect.fields(headers)) {
				hr.setHeader(f,Reflect.field(headers,f));	
			}
		}

		hr.request(post);
		return oc;
	}
	
	public static function fileUpload<T>(form, action_url):TOutcome<String,T> {
		var oc = Core.outcome();
        trace('creating iframe');
        var iframe = Browser.document.createElement("iframe");
        iframe.setAttribute("id", "upload_iframe");
        iframe.setAttribute("name", "upload_iframe");
        iframe.setAttribute("width", "0");
        iframe.setAttribute("height", "0");
        iframe.setAttribute("border", "0");
        iframe.setAttribute("style", "width: 0; height: 0; border: none;");
        
        // Add to document...
        form.parentNode.appendChild(iframe);
        Reflect.field(Browser.window.frames,"upload_iframe").name = "upload_iframe";
        
        var iframeId = Browser.document.getElementById("upload_iframe");
        
        // Add event...
        var eventHandler = function (e) {
            
            //iframeId.removeEventListener("load", eventHandler, false);
            
            // Message from server...
            var content = null;
            untyped {
                if (iframeId.contentDocument) {
                    content = iframeId.contentDocument.body.innerHTML;
                } else if (iframeId.contentWindow) {
                    content = iframeId.contentWindow.document.body.innerHTML;
                } else if (iframeId.document) {
                    content = iframeId.document.body.innerHTML;
                }
            }
            
            oc.complete(Http.unpack(content));

            function cleanup() {
                iframeId.parentNode.removeChild(iframeId);
                trace('removed iframid');
            }
            
            // Del the iframe...
            Browser.window.setTimeout(cleanup, 250);
        }
        
        if (iframeId.addEventListener != null) 
        	iframeId.addEventListener("load", eventHandler, true);
        
        // Set properties of form...
        form.setAttribute("target", "upload_iframe");
        form.setAttribute("action", action_url);
        form.setAttribute("method", "post");
        form.setAttribute("enctype", "multipart/form-data");
        form.setAttribute("encoding", "multipart/form-data");
        
        // Submit the form...
        form.submit();
        return oc;
	}
	

#end

	public static function get(url:String,?params:Dynamic,?headers:Dynamic):TOutcome<String,String> {
		#if nodejs
			return nodeGet(url,params,headers);
		#else
			return haxeRequest(url,false,params,headers);		
		#end
		
	}

	public static function post(url:String,payload:Dynamic,urlEncoded=true,?headers:Dynamic):TOutcome<String,String> {  
		#if nodejs
			return nodePost(url,payload,urlEncoded,headers);
		#else
			return haxeRequest(url,true,payload,headers);		
		#end		
	}
	
	static function mapStruct<T>(httpVal:TVal<String,String>):TVal<String,T> {
		return httpVal.flatMap(function(packed:String) {
			return unpack(packed);
		});
	}

		
	public static function get_<T>(url:String,?params:Dynamic,?headers:Dynamic):TOutcome<String,T> {
		#if nodejs
			return nodeGet(url,params,headers).map(mapStruct);
		#else
			return haxeRequest(url,false,params,headers).map(mapStruct);
		#end
	}

	/**
		Post and return typed json stuctures.
	*/
	public static function post_<T>(url:String,payload:Dynamic,urlEncoded=false,?headers:Dynamic):TOutcome<String,T> {  
		if (headers == null) headers = {};
		Reflect.setField(headers,'Content-Type','application/json');
		payload = haxe.Json.stringify(payload);
		Reflect.setField(headers,"Content-Length",payload.length);
			
		#if nodejs
			return nodePost(url,payload,false,headers).map(mapStruct);
		#else
			return haxeRequest(url,true,payload,headers).map(mapStruct);
		#end		
	}
}
