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
		private var planet:Shape;
		private var noteDisplay:Shape;
		
		private var debugTextS:Sprite;
		private var debugText:TextField;
		
		private var curNotes:HushNote = null; //Notes of currently recording measure
		private var prevNotes:HushNote = null; //Notes recorded in previous measure
		
		public static const MARGIN:Number = 20;
		public static const FPS:Number = 30;
		public static const SECPERFRAME:Number = 6;
		public static const MEASURETICKS:Number = SECPERFRAME*FPS;
		public static const SCREENTICKS:Number = MEASURETICKS*2;
		
		public static const WIDTH:Number = 1280;
		public static const HEIGHT:Number = 720;
		
		/* TODO: Let user control the silence cutoff (which is same as controlling microphone gain) */
		public static const SILENCE_CUTOFF:Number = 6.25/1024.0;
		
		public static const M_SAMPLE_RATE:Number = 22050; //Microphone sample rate
		private var mic:Microphone;
		private var micTick:int;
		
		public function HushSunHush()
		{
			debugTextS = new Sprite();
			addChild(debugTextS);
			debugText = new TextField();
			debugText.autoSize = TextFieldAutoSize.LEFT;
			debugText.background = false;
			debugText.border = true;
			
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFFFFFF;
			format.size = 10;
			format.underline = true;
			debugText.defaultTextFormat = format;
			
			debugTextS.addChild(debugText);
			debugText.text = "Hello, world";
			
			planet = new Shape();
			planet.graphics.beginFill(0x00aa00,0.5);
			planet.graphics.drawCircle(WIDTH/2,HEIGHT*3,HEIGHT*3);
			planet.graphics.endFill();
			planet.y = HEIGHT/3;
			addChild(planet);
			
			noteDisplay = new Shape();
			noteDisplay.x = MARGIN;
			noteDisplay.y = 2*MARGIN;
			addChild(noteDisplay);
			
			var child:Shape;
			//Setup the beat markers		
			for(var i:int =1; i<8; i++){
				child = new Shape();
				child.graphics.beginFill(0xFFFFFF);
				child.graphics.lineStyle(1, 0xFFFFFF);
				child.graphics.drawRect(0,0,1,HEIGHT-2*MARGIN);
				child.x = MARGIN + (i*(WIDTH-MARGIN))/8;
				child.y = MARGIN;
				child.graphics.endFill();
				addChild(child);
			}
			//Border for beat markers
			child = new Shape();
			child.graphics.lineStyle(1,0xCCCCCC);
			child.graphics.drawRect(0,0,WIDTH-2*MARGIN,HEIGHT-2*MARGIN);
			child.x = MARGIN;
			child.y = MARGIN;
			addChild(child);
			
			
			
			//Indicator of where we are in the measure(s)
			tickIndicator = new Shape();
			tickIndicator.graphics.beginFill(0xCC0000);
			tickIndicator.graphics.lineStyle(1,0xCC0000);
			tickIndicator.graphics.drawRect(0,0,1,HEIGHT-4*MARGIN);
			tickIndicator.x = MARGIN;
			tickIndicator.y = 2*MARGIN;
			tickIndicator.graphics.endFill();
			addChild(tickIndicator);
			
			//Be update the screen once per frame
			tickIndicator.addEventListener(Event.ENTER_FRAME,step);
		
			mic = Microphone.getMicrophone();
			mic.addEventListener(StatusEvent.STATUS, this.onMicStatus); 
			micTick = 0;
			mic.rate = M_SAMPLE_RATE/1000; //For some reason the flash API uses kHz instead of Hz
			mic.setSilenceLevel(0); //We need to detect both the start and end of notes
			mic.addEventListener( SampleDataEvent.SAMPLE_DATA, onMicSampleData );
		}
		
		
		public function onMicStatus(event:StatusEvent):void 
		{ 
			if (event.code == "Microphone.Unmuted") 
			{ 
				trace("Microphone access was allowed."); 
			}  
			else if (event.code == "Microphone.Muted") 
			{ 
				trace("Microphone access was denied."); 
			} 
		}
		
		public function step ( event:Event ):void
		{
			tick++; //Keep a count of which frame we are on
			tick = tick % (FPS*SECPERFRAME*2);
			
			/**
			 * Logic for switching measures goes here
			 */
			if((tick+1)%(MEASURETICKS) == 0){
				end_note(); //Notes cannot cross measure boundaries
			}
			if(tick % MEASURETICKS == 0){
				prevNotes = curNotes;
				curNotes = null;
			}
			
			//Update the position of the beat indicator
			tickIndicator.x = MARGIN + (tick*(WIDTH-2*MARGIN)) / (FPS*SECPERFRAME*2);
			
			noteDisplay.graphics.clear();
			//Draw the notes being recorded in the current measure
			draw_notes(noteDisplay,curNotes,0x0000cc,tick/MEASURETICKS,0);
			//Draw the previously recorded notes in the other measure
			draw_notes(noteDisplay,prevNotes,0x0000cc,1-Math.floor(tick/MEASURETICKS),0);
			//Draw the previously recorded notes in the current measure as a guide
			draw_notes(noteDisplay,prevNotes,0xaaaaaa,tick/MEASURETICKS,5);
		}
		
		public function onMicSampleData( event:SampleDataEvent ):void
		{
			// Get number of available input samples
			var len:uint = event.data.length/4;
			
			var total:Number = 0;
			
			// Read the input data
			for ( var i:uint = 0; i < len; i++ )
			{
				total += Math.abs(event.data.readFloat());
			}
			
			total = total/len;
						
			if(total > SILENCE_CUTOFF){
				//We hear something. If no current note, create one.
				start_note();
			} else {
				//We hear nothing. If there is a current note, end it.
				end_note();
			}
		}
		
		private function start_note():void
		{
			//Start a new note if either there are no notes yet,
			// or the most recent note has ended.
			if(curNotes == null || curNotes.end != -1){
				var newNote:HushNote = new HushNote();
				newNote.prev = curNotes;
				curNotes = newNote;
				newNote.start = tick%MEASURETICKS;
			}
		}
		
		private function end_note():void
		{
			//If there is a current note in progress, end it.
			if(curNotes != null && curNotes.end == -1){
				curNotes.end = tick%MEASURETICKS;
			}
		}
		
		private function draw_notes(ret:Shape, n:HushNote, color:uint, measure:int, vpos:int):void
		{
	
			var cur:HushNote = n;
			var firsttick:int;
			var lasttick:int;
			var firstx:Number;
			var lastx:Number;
			
			while(cur != null){
				firsttick = cur.start;
				lasttick = cur.end;
				if(lasttick == -1) lasttick = tick%MEASURETICKS;
				
				firsttick = firsttick + measure*MEASURETICKS;
				lasttick = lasttick + measure*MEASURETICKS;
				
				firstx = firsttick*(1280-2*MARGIN)/SCREENTICKS;
				lastx  = lasttick *(1280-2*MARGIN)/SCREENTICKS;
				
				ret.graphics.beginFill(color);
				ret.graphics.lineStyle(1,color);
				ret.graphics.drawRect(firstx,vpos,lastx-firstx,2);
				ret.graphics.endFill();
				cur = cur.prev;
			}
			
		}
	}
}