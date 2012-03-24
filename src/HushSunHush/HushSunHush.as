/**
 * A flash game for #MolyJam2012, based on http://twitter.com/#!/petermolydeux/status/156103782189633536
 * 
 * Author: Bo Brinkman
 * Date  : 2012-03-23
 * Note  : I'm cheating (starting early). But, on the other hand, I'm going to be watching my
 *         six-month-old daughter all weekend, so I think it comes out in the wash. :)
 * 
 * Released under a Creative Commons 3.0 Unported license. (See http://creativecommons.org/licenses/by/3.0/)
 * This means you are free to share, remix, and make commercial use of this work as long as you
 * give attribution.
 * 
 * Note that some parts of the code of this program are used under open source licenses from
 * other authors. Check each individual file for its license terms.
 **/

package HushSunHush
{
	import __AS3__.vec.Vector;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.text.*;
	import flash.utils.*;
				
	[SWF(width="1280", height="720", backgroundColor="#000055", frameRate="30")]
	
	public class HushSunHush extends Sprite
	{	
		private var tick:int=0;
		private var tickIndicator:Shape;
		
		public static const MARGIN:int = 20;
		public static const FPS:int = 30;
		public static const SECPERFRAME:int = 6;
		public static const WIDTH:int = 1280;
		public static const HEIGHT:int = 720;
		
		public function HushSunHush()
		{
			
			
			for(var i:int =1; i<8; i++){
				var child:Shape = new Shape();
				child.graphics.beginFill(0xFFFFFF);
				child.graphics.lineStyle(1, 0xFFFFFF);
				child.graphics.drawRect(0,0,1,HEIGHT-2*MARGIN);
				child.x = MARGIN + (i*(WIDTH-MARGIN))/8;
				child.y = MARGIN;
				child.graphics.endFill();
				addChild(child);
			}
			var child:Shape = new Shape();
			child.graphics.lineStyle(1,0xCCCCCC);
			child.graphics.drawRect(0,0,WIDTH-2*MARGIN,HEIGHT-2*MARGIN);
			child.x = MARGIN;
			child.y = MARGIN;
			addChild(child);
			
			
			tickIndicator = new Shape();
			tickIndicator.graphics.beginFill(0xCC0000);
			tickIndicator.graphics.lineStyle(1,0xCC0000);
			tickIndicator.graphics.drawRect(0,0,1,HEIGHT-4*MARGIN);
			tickIndicator.x = MARGIN;
			tickIndicator.y = 2*MARGIN;
			tickIndicator.graphics.endFill();
			addChild(tickIndicator);
			
			tickIndicator.addEventListener(Event.ENTER_FRAME,step);
			
		}
		
		public function step ( event:Event ):void
		{
			tick++;
			tick = tick % (FPS*SECPERFRAME*2);
			tickIndicator.x = MARGIN + (tick*(WIDTH-2*MARGIN)) / (FPS*SECPERFRAME*2);
		}
	}
}