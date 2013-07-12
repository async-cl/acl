package acl.jq;


using scuts.core.Iterables;
using scuts.core.Arrays;
using scuts.core.Options;
using scuts.core.Hashs;
using scuts.core.Promises;
using scuts.core.Validations;
import scuts.core.Pair;
using scuts.core.Functions;
 
using acl.Core;
using acl.J;

enum RMField {
    Raw;
    HF(header:String->String,formatter:Dynamic->String);
    TF(header:String,formatter:Dynamic->String);
    F(formatter:Dynamic->String);
    H(header:String->String);
    T(header:String);
}

typedef RMOptions = {
    ?fields:Dynamic,
    ?idField:String,
    ?calculated:Dynamic
}

typedef TRecordMapper = { > RMOptions,
	allFields:Array<String>
}

typedef TRecordMapperFld<T> = Pair<String,T>;

/**
 * ...
 * @author Ritchie Turner
 */
 
 
 /**
 	Take a record and map it to a new set of headings->values and calculated fields based on the given
 	RMFields typedef.
 	
 	Take a deep copy of the incoming record first
 */
class RecordMapper {

	public static function create(options:RMOptions):TRecordMapper {
		return  {
			fields:options.fields,
			idField:options.idField,
			calculated:options.calculated,
			allFields:Reflect.fields(options.fields).concat(Reflect.fields(options.calculated)).concat([options.idField])
		};
	}
	
	public static function map(rm:TRecordMapper,records:Array<Dynamic>) {
		return records.map(function(r) {
			return apply(rm,r);
		});
	}

	/**
		Returns a record composed of fields, originalFieldName: Tuple(header,newValue)
	*/
	public static function apply(rm:TRecordMapper,inRec:Dynamic) {
    
    	var rec = Core.copy(inRec);
    
    	// generate calculated field values ...
        if (rm.calculated != null) {
            Reflect.fields(rm.calculated).foldLeft(rec,function(acc,calcName) {
                Reflect.setField(acc,calcName,Reflect.field(rm.calculated,calcName)(rec));
                    return acc;
                });
        }
        
        var fieldModifiers = rm.fields;
        
        return rm.allFields.foldLeft({},function(acc,mf) {
            var val = Reflect.field(rec,mf);
            var z:RMField = Reflect.field(fieldModifiers,mf);
            if (z != null) {
                Reflect.setField(acc,mf,switch(z) {
                    case H(h):Pair.create(h(mf),val);
                    case F(f):Pair.create(mf,f(val));
                    case HF(h,f):Pair.create(h(mf),f(val));
                    case TF(h,f):Pair.create(h,f(val));
                    case Raw : Pair.create(mf,val);
                    case T(s): Pair.create(s,val);
                });
            } else
                Reflect.setField(acc,mf,Pair.create(mf,val));
                
            return acc;
        });
    }
    

}
