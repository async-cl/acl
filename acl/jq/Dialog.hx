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
using acl.jq.Tiles;
using caan.Session;

typedef TDialog<T> = {
    container:TJq,
    outcome:TOutcome<String,T>,
    data:Dynamic
}

class Dialog {
    
    public static function create<T>(onLoad:TDialog<T>->Void):TDialog<T> {
        
        var container = J.q('<div style="display:none" />');
        container.appendTo('body');
        
        var dialog = {
            container:container,
            outcome:null,
            data:null
        };
        
        var conf = {
                top: 260,
                mask: {
                    color: '#fff',
                    loadSpeed: 200
                    //opacity: 0.5
                },
                // disable this for modal dialog-type of overlays
                closeOnClick: false,
                load: false,
                onBeforeLoad:function() {
                    onLoad(dialog);
                },
                onClose:function(e:TJqEvent) {
                    trace("close target "+e.target);
                }
                
            };
        
        TJqOverlay.overlay(container,conf);
        return dialog;
    }
    
    public static function empty<T>(dlg:TDialog<T>):TDialog<T> {
        J.q(dlg.container).empty();
        return dlg;
    }
    
    /**
        Remove the inserted dom container element.
    */
    public static function dispose<T>(dlg:TDialog<T>){
        dlg.container.remove();
        dlg.container = null;
    }
    
    public static function open<T>(dlg:TDialog<T>,?data:Dynamic):TOutcome<String,T> {
        var overlay = TJqOverlay.getOverlayAPI(dlg.container);        
        
        dlg.data = data;
        dlg.outcome = Core.outcome();
        
        overlay.load();
        return dlg.outcome;
    }
    
    public static function close<T>(dlg:TDialog<T>):TDialog<T> {
        var overlay = TJqOverlay.getOverlayAPI(dlg.container);
        overlay.close();
        return dlg;
    }
    
    public static function addClass<T>(dlg:TDialog<T>,cls:String):TDialog<T> {
        dlg.container.addClass(cls);
        return dlg;
    }
    
    public static function onceOnly<T>(dlg:TDialog<T>,fn:TDialog<T>->Void):TDialog<T> {
        fn(dlg);
        return dlg;
    }
    
    public static function makeYesNo(question:String):TDialog<String> { return
        addClass(Dialog.create(function(dlg) { 
           dlg.container.empty();
           dlg.container.html(question);
           dlg.container.append('<span><button yesno="yes">Yes</button><button yesno="no">No</button></span>');
           J.q('button[yesno="yes"]',dlg.container).click(function(e) {
                close(dlg);
                dlg.outcome.complete(Success("yes"));
            });
           J.q('button[yesno="no"]',dlg.container).click(function(e) {
                close(dlg);
                dlg.outcome.complete(Failure("no"));
            });
            
        }),'dialogYesNo');
    }
    
}
