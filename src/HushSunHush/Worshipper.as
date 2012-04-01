package HushSunHush
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	
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
		}
		
		public function step(){
			var which:int = Math.floor(3*Math.random());
			fwd.alpha = 0.0;
			left.alpha = 0.0;
			right.alpha = 0.0;
			if(which == 0){
				fwd.alpha = 1.0;
			} else if(which == 1){
				left.alpha = 1.0;
			} else {
				right.alpha = 1.0;
			}
		}
	}
}