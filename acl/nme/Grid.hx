package acl.nme;
import acl.nme.Defs;
using acl.nme.Spr;

typedef TGridAttr = { 
	rows:Int,
	cols:Int,
   	cellWidth:Int,
   	cellHeight:Int,
    ?background:Int,
    ?padding:Int
}

typedef TGrid = { > TGridAttr,
	sprite:TSprite
}

class Grid {

  public static function create(parent:TSprite,attr:TGridAttr):TGrid {
  	var s = new TSprite();
	var col = (attr.background == null) ? 0 : attr.background;
   	Spr.size(s,attr.cols*attr.cellWidth,attr.cellHeight*attr.rows,col);
  	parent.addChild(s);
  
	return {
		sprite:s,
		rows: attr.rows,
		cols: attr.cols,
		padding: (attr.padding == null) ? 1 : 0,
		background:col,
		cellHeight: attr.cellHeight,
		cellWidth: attr.cellWidth
	 } ;
  }

  public static inline function gCtx(grid:TGrid):TGraphics {
  	return grid.sprite.graphics;
  }
  
  public static inline function move(grid:TGrid,x:Int,y:Int) {
  	grid.sprite.x = x;
  	grid.sprite.y = y;
  	return grid;
  }
  
  public static function draw(grid:TGrid,lineCol=0x00FF00):TGrid {
    var dims = dimensions(grid),
      g = gCtx(grid);

    // rows
    g.lineStyle(1,lineCol);
    for (r in 0... grid.rows) {
      var y = r * grid.cellHeight;
      g.moveTo(0,y);
      g.lineTo(dims.width,y);
    }

    // cols
    for (c in 0 ...grid.cols) {
      var x = c * grid.cellWidth;
      g.moveTo(x,0);
      g.lineTo(x,dims.height);
    } 
    return grid;
  }
  
  public static function iterate(grid:TGrid,cb:TGrid->Int->Int->Int->Void):TGrid {
    var ith = 0;
    for (row in 0 ... grid.rows) {
      for (col in 0 ...grid.cols) 
        cb(grid,col,row,ith++);
    }
    return grid;
  }

  public static inline function dimensions(grid:TGrid):TDim {
  	return {width:grid.cellWidth * grid.cols,height:grid.cellHeight * grid.rows };
  }
  
  public static inline function cellDimensions(grid:TGrid):TDim {
  	return {width:grid.cellHeight,height:grid.cellHeight};
  }
  
  public static function setCellSprite(grid:TGrid,col:Int,row:Int,child:TSprite):TGrid {
    var
      x = col * grid.cellWidth,
      y = row * grid.cellHeight;

    child.width = grid.cellWidth  - 3 * grid.padding;
    child.height = grid.cellHeight - 3 * grid.padding;
   
    grid.sprite.addChild(child);
    
	child.x = x + grid.padding;
    child.y = y + grid.padding;
    
	return grid;
  }
  
  public static function cellClick(grid:TGrid,handler:Int->Int->Void):TGrid {
  	grid.sprite.addEventListener(TMouseEvent.CLICK,function(e:TMouseEvent) {
		trace("x: "+e.localX +" y:"+e.localY);
		var x =  e.localX /grid.cellWidth;
		var y = e.localY / grid.cellHeight;
		handler(Math.floor(x),Math.floor(y));
	});
	return grid;
  }
  
  

}



