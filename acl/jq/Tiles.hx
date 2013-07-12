
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
using acl.jq.RecordMapper;

typedef TTileActions = {
	name:String,
	image:String,
	action:TJqEvent->Void
}

typedef TTiles = {
	_recordMapper:TRecordMapper,
	_renderWith:TJq->Dynamic->Void,
	_actions:Map<String,TTileActions>,
	?_selectedClass:String,
	?_overClass:String,
	?_parent:TJq,
	?_tileClass:String,
 }
 
class Tiles {
	
	public static function create():TTiles {
		return {
			_recordMapper:null,
			_renderWith:null,
			_tileClass:"aclTile",
			_actions:new Map()
		};	
	}

	public static function withRenderer(tiles:TTiles,fn:TJq->Dynamic->Void) {
		tiles._renderWith = fn;
		return tiles;
	}
	
	public static function withRecordMapper(tiles:TTiles,rm:TRecordMapper) {
		tiles._recordMapper = rm;
		return tiles;
	}
	
	public static function render(tiles:TTiles,data:Array<Dynamic>,parent:TJq):TJq {
        tiles._parent = parent;
        return reRender(tiles,data);
	}

	public static inline function getTile(tiles:TTiles,id:String) {
		return J.q('div[tile_id="${id}"]',tiles._parent);
	}
	
    public static function delete(tiles:TTiles,tileID:String) {
        getTile(tiles,tileID).remove();    
    }
        
    /**
        Assumes parent has been set. Must render() first.
    */
    public static function reRender(tiles:TTiles,data:Array<Dynamic>):TJq {
        tiles._recordMapper.map(data).each(function(r) {
            var id = Reflect.field(r,"_id")._2;
            var tile = getTile(tiles,id);
            var actions = [for (k in tiles._actions.keys()) tiles._actions.get(k)];
            var tileExists = tile.length == 1;
            if (tileExists) {
                tile.empty();
                tiles._renderWith(tile,r);
                renderActions(id,actions,tile);
            } else {
                var tile = J.q('<div tile_id="${id}" class="${tiles._tileClass}"></div>') ;
                tiles._renderWith(tile,r);
                renderActions(id,actions,tile);
                tiles._parent.append(tile);
            }
        });
        
        if (tiles._selectedClass != null)
            _addSelection(tiles);   
        
        return J.q('div.${tiles._tileClass}',tiles._parent);
    }
	
	static function actionElement(tile_id,action,image) {
        var img = '<img src="${image}" style="width:32px;height:32px"/>';
        return J.q('<a href="javascript:void(0);" tile_id="${tile_id}" action="${action}">${img}</a>');
    }
    
	static function renderActions(tileID:String,actions:Array<TTileActions>,tile:TJq) {
        var ac = J.q('.tileActions',tile);
        ac = if (ac.length == 0) J.q('<div class="tileActions" />').appendTo(tile) else ac;
		actions.each(function(a) {
			actionElement(tileID,a.name,a.image)
				.appendTo(ac)
               // .unbind("click",a.action)
				.click(a.action);
		});
	}
    
	static function onEnter(e) {
        var tiles:TTiles = e.data.tiles;
        J.cur.addClass(tiles._overClass);
    }
    
    static function onLeave(e) {
	    var tiles:TTiles = e.data.tiles;
	    J.cur.removeClass(tiles._overClass);
    }
    
    static function onClick(e) {
        var tiles:TTiles = e.data.tiles;
        J.cur.siblings("."+tiles._tileClass).removeClass(tiles._selectedClass);
        J.cur.addClass(tiles._selectedClass);
    }
    
    static function _addSelection<T>(tiles:TTiles) {
        tiles._parent.find("."+tiles._tileClass)
        .unbind('click',onClick)
        .unbind('mouseenter',onEnter)
        .unbind('mouseleave',onLeave)
        .mouseenter({tiles:tiles},onEnter)
        .mouseleave({tiles:tiles},onLeave)
        .click({tiles:tiles},onClick);
    }
    
    public static function withSelection<T>(tiles:TTiles,overClass:String,selectedClass:String) {
        tiles._selectedClass = selectedClass;
        tiles._overClass = overClass;
        return tiles;
    }
    
    public static function addAction(tiles:TTiles,name:String,image:String,action:TJqEvent->Void) {
        if (!tiles._actions.exists(name))
    	    tiles._actions.set(name,{name:name,image:image,action:action});
    }

}
