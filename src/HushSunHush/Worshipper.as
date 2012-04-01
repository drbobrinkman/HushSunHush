package HushSunHush
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	
	public class Worshipper extends Sprite
	{
		[Embed(source="dude_blue.png")]
		private static var Dude: Class;
		
		[Embed(source="dude_left_blue.png")]
		private static var DudeLeft: Class;
		
		[Embed(source="dude_grey.png")]
		private static var DudeGrey: Class;
		
		[Embed(source="dude_left_grey.png")]
		private static var DudeLeftGrey: Class;
		
		private var fwd:Bitmap;
		private var left:Bitmap;
		private var right:Bitmap;
		
		private var maxX:int;
		private var minX:int;
		private var maxY:int;
		private var minY:int;
		
		private var team:int;
		
		private var state:int; //0 is waiting, 1 is moving left, 2 is moving right
		private var togo:int; //Number of steps to wait, if waiting. Distance to move, if moving.
		
		public function Worshipper(iminX:int, imaxX:int, iminY:int, imaxY:int, iteam:int)
		{
			super();
			
			maxX = imaxX;
			minX = iminX;
			maxY = imaxY;
			minY = iminY;
			team = iteam;
			
			x = minX + (maxX-minX-32)*Math.random();
			y = minY + (maxY-minY-32)*Math.random();
			
			if(team == 0){
				fwd = new DudeGrey() as Bitmap;
			} else {
				fwd = new Dude() as Bitmap;
			}
			fwd.scaleX = 0.25;
			fwd.scaleY = 0.25;
			addChild(fwd);
			
			if(team == 0){
				left = new DudeLeftGrey() as Bitmap;
			} else {
				left = new DudeLeft() as Bitmap;
			}
			
			left.scaleX = 0.25;
			left.scaleY = 0.25;
			addChild(left);
			left.alpha = 0.0;
			if(team == 0){
				right = new DudeLeftGrey() as Bitmap;
			} else {
				right = new DudeLeft() as Bitmap;
			}
			right.scaleX = -0.25;
			right.scaleY = 0.25;
			right.alpha = 0.0;
			right.x = 32;
			
			addChild(right);
		}
		
		public function flipHorizontal(dsp:DisplayObject):void
		{
			var matrix:Matrix = dsp.transform.matrix;
			matrix.a=-1;
			matrix.tx=dsp.width+dsp.x;
			dsp.transform.matrix=matrix;
		}
		
		public function step():void{
			//If we are not visible, do nothing
			if(alpha < 0.1) return;
			
			if(togo == 0){
				var which:int = Math.floor(3.0* Math.random());
				
				//This makes it so the guy always pauses before moving again.
				if(state != 0) which = 0;
				
				state = which;
				if(which == 0){
					//pick number of steps to wait. 30 steps is 1 second.
					togo = Math.floor(3*30.0*Math.random()); //Max 3 seconds
				} else {
					//First, pick target x
					var goalX:int = minX + (maxX-minX-32)*Math.random();
					togo = goalX - x;
					
					if(togo < 0) {
						//In this case, we are going left
						togo = -togo;
						state = 1;
					} else {
						//In this case, we are going right
						state = 2;
					}
				}
			} else {
				fwd.alpha = 0.0;
				left.alpha = 0.0;
				right.alpha = 0.0;
				if(state == 0){
					fwd.alpha = 1.0;
				} else if(state == 1) {
					x = x - 1;
					left.alpha = 1.0;
				} else {
					x = x + 1;
					right.alpha = 1.0;
				}
				
				if(state != 0){
					if(togo % 6 == 0){
						if(togo % 12 == 0){
							y = y + 1;
						} else {
							y = y - 1;
						}
					}
				}
				while(y > maxY) y--;
				while(y < minY) y++;
				
				togo = togo-1;
			}
		}
	}
}