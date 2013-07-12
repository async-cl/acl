package acl;

using acl.Core;
using acl.Http;

/**
 * ...
 * @author Ritchie Turner
 */
class EClient {

	//static var server = "http://localhost:8081";
    //static var server = "http://www.caanread.com";
	static var server = "";
    
	static function post(url,prms:Dynamic,urlEncoded=false):Dynamic {
		return Http.post_(server+url,prms,urlEncoded);
	}
	
	static function get(url,prms:Dynamic):Dynamic {
		return Http.get(server+url,prms);
	}

	static function get_(url,prms:Dynamic):Dynamic {
		return Http.get_(server+url,prms);
	}

			
	public static inline var urlEntityInsert = "/wise/e/ins";
	public static inline var urlEntityLink = "/wise/e/lnk";
	public static inline var urlEntityUnlink = "/wise/e/unlnk";
	public static inline var urlEntityDelete = "/wise/e/del";
	public static inline var urlEntities = "/wise/e/v";
	public static inline var urlEntityInsertWithImage = '/wise/e/insi';
	public static inline var urlEntityGet = "/wise/e/get";
	public static inline var urlEntityChildren = "/wise/e/chl";
	public static inline var urlEntityParents = "/wise/e/par";


	public static function entityInsert(entity:TEntity):TOutcome<String,TEntityRef> {
		return post(urlEntityInsert,{e:entity});
	}
	
	public static function entityDelete(entity:TEntityRef):TOutcome<String,String> {
		return post(urlEntityDelete,{er:entity});
	}
	
	public static function entityLink(relation:String,parent:TEntityBase,child:TEntityBase):TOutcome<String,TEntityRef> {
		return post(urlEntityLink,{relation:relation,p:parent,c:child});
	}

	public static function entityUnlink(relation:String,parent:TEntityBase,child:TEntityBase):TOutcome<String,TEntityRef> {
		return post(urlEntityUnlink,{relation:relation,p:parent,c:child});
	}

	public static function entityChildren<T>(relation:String,parent:TEntityBase):TOutcome<String,Array<T>> {
		return post(urlEntityChildren,{relation:relation,id:parent._id});
	}

	public static function entityParents<T>(relation:String,child:TEntityBase):TOutcome<String,Array<T>> {
		return post(urlEntityParents,{relation:relation,id:child._id});
	}

	#if !nodejs
	public static function entityInsertWithImage<T:TEntity>(file:Dynamic,data:T,requiredName:String):TOutcome<String,T> {
		Reflect.setField(data,"__requiredName__",requiredName);
		return Http.fileUpload_(urlEntityInsertWithImage,"onlyImage",file,data);
	}
	#end
	
	public static function entities<T:TEntity>(entityType:String,?prms:TEntityKeys):TOutcome<String,Array<T>> {
		return post(urlEntities,{
			entityType:entityType,
			prms:haxe.Serializer.run(prms)
		});
	}
	
	public static function entityGet<T:TEntity>(id:TEntityID):TOutcome<String,T> {
		return post(urlEntityGet,{id:id});
	}
	
}
