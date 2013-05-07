package acl.jq;

/**
 * ...
 * @author Ritchie Turner
 */
 
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

enum ETblField {
    Raw;
    HF(header:String->String,formatter:Dynamic->String);
    TF(header:String,formatter:Dynamic->String);
    F(formatter:Dynamic->String);
    H(header:String->String);
    T(header:String);
}

typedef TblOptions = {
    ?fields:Dynamic,
    ?idField:String,
    ?calculated:Dynamic
};

typedef TTbl = {
	_table:TJq,
    _options:TblOptions,
	_fields:Array<String>,
	?_selectedClass:String,
	?_overClass:String,
}

class Tbl {
  
    static function makeTd(p:Dynamic,fields:Array<String>) { return 
    	fields
        .map(function(f) {
        	var fld = Reflect.field(p,f);
        	var name = f;
            var val = fld._2;
            return '<td aclFld="${name}">${val}</td>';
        }).join("");
    }
    
    static function makeTh(p:Dynamic,fields:Array<String>) { return 
    	"<thead><tr>" +
        fields.map(function(f) {
            return '<th>${Reflect.field(p,f)._1}</th>';
        })
        .join("") +
        "</tr></thead>";
    }
    
    static function makeTr(p:Dynamic,?idField:String) {
        var id = Reflect.field(p,idField)._2; // extract second item of tuple
        var idstr = if (idField != null) 'id="${id}"' else "";
        return '<tr ${idstr}>';
    }
   
    static function createRow(rec:Dynamic,options:TblOptions,allFields:Array<String>) {
        if (options.calculated != null) {
            Reflect.fields(options.calculated).foldLeft(rec,function(acc,calcName) {
                Reflect.setField(acc,calcName,Reflect.field(options.calculated,calcName)(rec));
                    allFields.push(calcName);
                    return acc;
                });
        }
        var fieldModifiers = options.fields;
        
        return allFields.foldLeft({},function(acc,mf) {
                var val = Reflect.field(rec,mf);
                var z:ETblField = Reflect.field(fieldModifiers,mf);
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
      
    public static function create<T,F>(parent:TJq,ps:Array<T>,options:TblOptions):TTbl {
        var allFields = Reflect.fields(ps[0]);
        
        var modified = ps.map(function(rec) {
            return createRow(rec,options,allFields);
        });

        var requiredFieldsInOrder = Reflect.fields(options.fields);
        return {
        	_table:J.q('<table class="aclTbl">' + 
                makeTh(modified[0],requiredFieldsInOrder) +
                "<tbody>" +
                modified.map(function(p) {
                    return makeTr(p,options.idField) + makeTd(p,requiredFieldsInOrder) + "</tr>";
                }).join("") +
                "</tbody>" +
                '</table>').appendTo(parent),
            _fields:requiredFieldsInOrder,
            _options:options
        };
    }

    static function onEnter(e) {
        var table:TTbl = e.data.table;
        J.cur.addClass(table._overClass);
    }
    
    static function onLeave(e) {
    var table:TTbl = e.data.table;
    J.cur.removeClass(table._overClass);
    }
    
    static function onClick(e) {
        var table:TTbl = e.data.table;
        J.cur.siblings("tr").removeClass(table._selectedClass);
        J.cur.addClass(table._selectedClass);
    }
    
    static function _addSelection<T>(table:TTbl) {
        table._table.find('tbody tr')
        .unbind('click',onClick)
        .unbind('mouseenter',onEnter)
        .unbind('mouseleave',onLeave)
        .mouseenter({table:table},onEnter)
        .mouseleave({table:table},onLeave)
        .click({table:table},onClick);
    }
    
    public static function addSelection<T>(table:TTbl,overClass:String,selectedClass:String) {
        table._selectedClass = selectedClass;
        table._overClass = overClass;
        _addSelection(table);   
        return table;
    }
    
    /**
        Return the jquery table object
    */
    public static function table<T>(table:TTbl,fn:TJq->Void) {
        fn(table._table);
        return table;
    }
    
    public static function updateRow<T>(table:TTbl,id:String,values:Dynamic) {
		var row = J.q('tbody tr[id="${id}"]',table._table);
		table._fields.each(function(f) {
            var newValue = Reflect.field(values,f);
            if (newValue != null) {
                trace('updating ${f} to ${newValue}');
			    J.q('td[aclFld="${f}"]',row).html(newValue);
            }
		});
    }
    
    public static function removeRow<T>(table:TTbl,id:String):TTbl {
        J.q('tbody tr[id="${id}"]',table._table).remove();
        return table;
    }
    
    public static function appendRow<T>(table:TTbl,record:Dynamic) {
        var rec = createRow(record,table._options,Reflect.fields(record));
        J.q('tbody',table._table).append(makeTr(rec,table._options.idField) + makeTd(rec,table._fields) + "</tr>");
        _addSelection(table);
        return table;
    }
    
}
