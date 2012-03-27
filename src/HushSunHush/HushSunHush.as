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
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
				
	[SWF(width="1280", height="720", backgroundColor="#000000", frameRate="30")]
	
	public class HushSunHush extends Sprite
	{	
		private var tick:int=0;
		private var tickIndicator:Shape;
		private var planet:Shape;
		private var noteDisplay:Shape;
		private var noteGrid:Shape;
		
		private var whichTeam:int=0;
		
		private var debugTextS:Sprite;
		private var debugText:TextField;
		
		private var curNotes:HushNote = null; //Notes of currently recording measure
		private var prevNotes:HushNote = null; //Notes recorded in previous measure
		
		private var windNotes:HushNote = null;
		private var waveNotes:HushNote = null;
		
		private var windLoader:URLLoader;
		private var waveLoader:URLLoader;
		
		public static const MARGIN:Number = 20;
		public static const FPS:Number = 30;
		public static const SECPERFRAME:Number = 6;
		public static const MEASURETICKS:Number = SECPERFRAME*FPS;
		public static const SCREENTICKS:Number = MEASURETICKS*2;
		
		public static const WIDTH:Number = 1280;
		public static const HEIGHT:Number = 720;
		
		public static const WINDCOLOR_dk:uint = 0x666666;
		public static const WINDCOLOR_md:uint = 0x999999;
		public static const WINDCOLOR_lt:uint = 0xcccccc;
		public static const WAVECOLOR_dk:uint = 0x002277;
		public static const WAVECOLOR_md:uint = 0x0033aa;
		public static const WAVECOLOR_lt:uint = 0x0044dd;
		
		public static const SKYCOLOR:uint = 0x330033;
		public static const PLANTCOLOR:uint = 0x009900;
		
		private var mycolor_dk:uint;
		private var mycolor_md:uint;
		private var mycolor_lt:uint;
		private var otcolor_dk:uint;
		private var otcolor_md:uint;
		private var otcolor_lt:uint;
		
		/* TODO: Let user control the silence cutoff (which is same as controlling microphone gain) */
		public static const SILENCE_CUTOFF:Number = 10.0/1024.0;
		
		public static const M_SAMPLE_RATE:Number = 22050; //Microphone sample rate
		private var mic:Microphone;
		private var micTick:int;
		
		public function HushSunHush()
		{
			var child:Shape;
			child = new Shape();
			child.graphics.beginFill(SKYCOLOR);
			child.graphics.drawRect(0,0,1280,720);
			child.graphics.endFill();
			addChild(child);
			
			whichTeam = Math.floor(2.0*Math.random()); //0 is wind, 1 is waves
			if(whichTeam == 0){
				mycolor_dk = WINDCOLOR_dk;
				mycolor_md = WINDCOLOR_md;
				mycolor_lt = WINDCOLOR_lt;
				otcolor_dk = WAVECOLOR_dk;
				otcolor_md = WAVECOLOR_md;
				otcolor_lt = WAVECOLOR_lt;
			} else {
				whichTeam = 1;
				mycolor_dk = WAVECOLOR_dk;
				mycolor_md = WAVECOLOR_md;
				mycolor_lt = WAVECOLOR_lt;
				otcolor_dk = WINDCOLOR_dk;
				otcolor_md = WINDCOLOR_md;
				otcolor_lt = WINDCOLOR_lt;
			}
			
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
			noteDisplay.y = 100+MARGIN;
			addChild(noteDisplay);
			
			noteGrid = new Shape();
			
			//Setup the beat markers		
			for(var i:int =1; i<8; i++){
				noteGrid.graphics.beginFill(0xFFFFFF);
				noteGrid.graphics.lineStyle(1, 0xFFFFFF);
				noteGrid.graphics.drawRect((i*(WIDTH-MARGIN))/8,0,1,35+2*MARGIN);
				noteGrid.graphics.endFill();
			}
			//Border for beat markers
			noteGrid.graphics.lineStyle(2,0xCCCCCC);
			noteGrid.graphics.drawRect(0,0,WIDTH-2*MARGIN,35+2*MARGIN);
			
			noteGrid.x = MARGIN;
			noteGrid.y = 100;
			addChild(noteGrid);
			
			//Indicator of where we are in the measure(s)
			tickIndicator = new Shape();
			tickIndicator.graphics.beginFill(0xCC0000);
			tickIndicator.graphics.lineStyle(1,0xCC0000);
			tickIndicator.graphics.drawRect(0,0,1,35+2*MARGIN);
			tickIndicator.x = MARGIN;
			tickIndicator.y = 100;
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
			
			loadSongs();
		}
		
		public function loadSongs():void
		{
			var variables:URLVariables = new URLVariables();
			variables.channel = "0";
			
			var request:URLRequest = new URLRequest("http://hushsunhush.com/get_song.php");
			request.method = URLRequestMethod.GET;
			request.data = variables;
			
			windLoader = new URLLoader();
			//windLoader.dataFormat = URLLoaderDataFormat.TEXT;
			windLoader.addEventListener(Event.COMPLETE,windLoaded);
			
			try {
				windLoader.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			}
			
			waveLoader = new URLLoader();
			variables.channel = "1";
			waveLoader.addEventListener(Event.COMPLETE,wavesLoaded);
			try {
				waveLoader.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			}
		}
		
		public function windLoaded(event:Event):void
		{
			var l:URLLoader = URLLoader(event.target);
			//debugText.text = "wind " + l.data;
			var results:Array = l.data.split(" ");
			var noteCount:int = results[1];
			
			windNotes = null;
			for(var i:int = 3; i< 3+2*noteCount; i += 2){
				var nxtWindNote:HushNote = new HushNote();
				nxtWindNote.prev = windNotes;
				windNotes = nxtWindNote;
				windNotes.start = results[i];
				windNotes.end = results[i+1];
			}
		}
		
		public function wavesLoaded(event:Event):void
		{
			var l:URLLoader = URLLoader(event.target);
			//debugText.text = "waves " + l.data;
			var results:Array = l.data.split(" ");
			var noteCount:int = results[1];
			
			waveNotes = null;
			for(var i:int = 3; i< 3+2*noteCount; i += 2){
				var nxtWaveNote:HushNote = new HushNote();
				nxtWaveNote.prev = waveNotes;
				waveNotes = nxtWaveNote;
				waveNotes.start = results[i];
				waveNotes.end = results[i+1];
			}
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
			if(tick % MEASURETICKS == 0){
				if(curNotes != null && curNotes.end == -1){
					curNotes.end = (tick + MEASURETICKS - 1)%(MEASURETICKS);
				}
				prevNotes = curNotes;
				curNotes = null;
			}
			
			//Update the position of the beat indicator
			tickIndicator.x = MARGIN + (tick*(WIDTH-2*MARGIN)) / (FPS*SECPERFRAME*2);
			
			noteDisplay.graphics.clear();
			//Draw the notes being recorded in the current measure
			draw_notes(noteDisplay,curNotes,mycolor_lt,tick/MEASURETICKS,0);
			//Draw the previously recorded notes in the other measure
			draw_notes(noteDisplay,curNotes,mycolor_md,1-Math.floor(tick/MEASURETICKS),7);
			//Draw the previously recorded notes in the current measure as a guide
			draw_notes(noteDisplay,prevNotes,mycolor_md,tick/MEASURETICKS,7);
			var myNotes:HushNote;
			var otNotes:HushNote;
			if(whichTeam == 0){
				myNotes = windNotes;
				otNotes = waveNotes;
			} else {
				myNotes = waveNotes;
				otNotes = windNotes;
			}
			draw_notes(noteDisplay,myNotes,mycolor_dk,tick/MEASURETICKS,14);
			draw_notes(noteDisplay,myNotes,mycolor_dk,1-Math.floor(tick/MEASURETICKS),14);
			
			draw_notes(noteDisplay,otNotes,otcolor_dk,tick/MEASURETICKS,28);
			draw_notes(noteDisplay,otNotes,otcolor_dk,1-Math.floor(tick/MEASURETICKS),28);
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
				ret.graphics.drawRect(firstx,vpos,lastx-firstx,5);
				ret.graphics.endFill();
				cur = cur.prev;
			}
			
		}
	}
}