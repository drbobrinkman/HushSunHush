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
	import flash.media.SoundTransform;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
				
	[SWF(width="800", height="450", backgroundColor="#000000", frameRate="30")]
	
	
	
	public class HushSunHush extends Sprite
	{	
		[Embed(source="Winds_v01.mp3")]
		private static var WindSound: Class;
		
		[Embed(source="Waves_v01.mp3")]
		private static var WaveSound: Class;
		
		private var tick:int=0;
		private var tickIndicator:Shape;
		private var planet:Shape;
		private var noteDisplay:Shape;
		private var noteGrid:Shape;
		private var micLevel:Shape;
		private var micCheck:Shape;
		
		private var globalScore:Shape;
		private var yourScore:Shape;
		
		private var whichTeam:int=0;
		
		private var debugTextS:Sprite;
		private var debugText:TextField;
		
		private var curNotes:HushNote = null; //Notes of currently recording measure
		private var prevNotes:HushNote = null; //Notes recorded in previous measure
		
		private var windNotes:HushNote = null;
		private var waveNotes:HushNote = null;
		
		private var windLoader:URLLoader;
		private var waveLoader:URLLoader;
		private var scoreLoader:URLLoader;
		
		public static const MARGIN:Number = 20;
		public static const FPS:Number = 30;
		public static const SECPERFRAME:Number = 6;
		public static const MEASURETICKS:Number = SECPERFRAME*FPS;
		public static const SCREENTICKS:Number = MEASURETICKS*2;
		
		public static const WIDTH:Number = 800;
		public static const HEIGHT:Number = 450;
		
		public static const PERFECT:Number = 0.95;
		public static const GREAT:Number = 0.90;
		public static const GOOD:Number = 0.80;
		
		public static const SOUND_LAG:Number = 8;
		
		public static const MAX_SCORE:Number = 20; //5 notes max, multiplier is 4 max
		/**
		 * Pallette elements:
		 * Violet: 0x630063
		 * Indigo: 0x3e0c38
		 * Seablu: 0x0087ff
		 * teal  : 0x0ce8a7
		 * green : 0x20ff00
		 * */
		
		public static const WINDCOLOR_dk:uint = 0x666666;
		public static const WINDCOLOR_md:uint = 0x999999;
		public static const WINDCOLOR_lt:uint = 0xcccccc;
		public static const WAVECOLOR_dk:uint = 0x001077;
		public static const WAVECOLOR_md:uint = 0x0032aa;
		public static const WAVECOLOR_lt:uint = 0x0054cc;
		public static const TEAL:uint = 0x0ce8a7;
		
		public static const SKYCOLOR:uint = 0x330033;
		public static const PLANTCOLOR:uint = 0x107f00; //based on 0x20ff00
		
		private var mycolor_dk:uint;
		private var mycolor_md:uint;
		private var mycolor_lt:uint;
		private var otcolor_dk:uint;
		private var otcolor_md:uint;
		private var otcolor_lt:uint;
		
		private var SILENCE_CUTOFF:Number = 50.0/1024.0;
		
		public static const M_SAMPLE_RATE:Number = 22050; //Microphone sample rate
		private var mic:Microphone;
		private var micTick:int;
		
		private var current_score:Number = 0.0;
	
		private var theWaveArray:ByteArray;
		private var moddedWaveSound:Sound;
		private var theWindArray:ByteArray;
		private var moddedWindSound:Sound;
		
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
			debugTextS.y = HEIGHT - 15;
			debugTextS.x = WIDTH/2;
			debugText.text = "";//"Hello, world";
			
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
			noteGrid.graphics.lineStyle(2,0xCCCCCC);
			noteGrid.graphics.drawRect(0,0,WIDTH-2*MARGIN,1);
			noteGrid.graphics.drawRect(0,35+2*MARGIN,WIDTH-2*MARGIN,1);
			noteGrid.graphics.lineStyle(1, 0xFFFFFF);
			for(var i:int =0; i<=8; i++){
				if(i%4 == 0){
					noteGrid.graphics.drawRect((i*(WIDTH-2*MARGIN))/8 - Math.floor((i+4)/4),0,3,35+2*MARGIN);
				} else {
					noteGrid.graphics.drawRect((i*(WIDTH-2*MARGIN))/8,0,1,35+2*MARGIN);
				}
			}
			
			noteGrid.x = MARGIN;
			noteGrid.y = 100;
			addChild(noteGrid);
			
			//Indicator of where we are in the measure(s)
			tickIndicator = new Shape();
			tickIndicator.graphics.beginFill(0x2000ff);
			tickIndicator.graphics.lineStyle(1,0x20ff00);
			tickIndicator.graphics.drawRect(0,0,1,35+2*MARGIN);
			tickIndicator.x = MARGIN;
			tickIndicator.y = 100;
			tickIndicator.graphics.endFill();
			addChild(tickIndicator);
		
			
			var micTextS:Sprite = new Sprite();
			addChild(micTextS);
			var micText:TextField = new TextField();
			micText.autoSize = TextFieldAutoSize.LEFT;
			micText.background = false;
			micText.border = false;
			

			micText.defaultTextFormat = format;
			
			micTextS.addChild(micText);
			micText.text = "Click below to set microphone level";
			micTextS.x = MARGIN/2;
			micTextS.y = HEIGHT-MARGIN-17;
			
			micCheck = new Shape();
			micCheck.graphics.beginFill(TEAL);
			micCheck.graphics.drawRect(0,0,WIDTH-2*MARGIN,5);
			micCheck.x = MARGIN;
			micCheck.y = HEIGHT-MARGIN;
			micCheck.graphics.endFill();
			addChild(micCheck);
			
			micLevel = new Shape();
			micLevel.graphics.beginFill(0xdddddd);
			micLevel.graphics.drawRect(0,0,5,9);
			micLevel.x = MARGIN + SILENCE_CUTOFF*(WIDTH-2*MARGIN);
			micLevel.y = HEIGHT-MARGIN-2;
			micLevel.graphics.endFill();
			addChild(micLevel);
			
			stage.addEventListener(MouseEvent.CLICK, changeMicLevel); 
			
			//Be update the screen once per frame
			tickIndicator.addEventListener(Event.ENTER_FRAME,step);
		
			mic = Microphone.getMicrophone();
			mic.addEventListener(StatusEvent.STATUS, this.onMicStatus); 
			micTick = 0;
			mic.rate = M_SAMPLE_RATE/1000; //For some reason the flash API uses kHz instead of Hz
			mic.setSilenceLevel(0); //We need to detect both the start and end of notes
			mic.addEventListener( SampleDataEvent.SAMPLE_DATA, onMicSampleData );
			
			
			var gsTextS:Sprite = new Sprite();
			addChild(gsTextS);
			var gsText:TextField = new TextField();
			gsText.autoSize = TextFieldAutoSize.LEFT;
			gsText.background = false;
			gsText.border = false;
		
			gsText.defaultTextFormat = format;
			
			gsTextS.addChild(gsText);
			gsText.text = "Worldwide total soothing praise:";
			gsTextS.x = MARGIN/2;
			gsTextS.y = MARGIN;
			
			globalScore = new Shape();
			globalScore.graphics.beginFill(TEAL);
			globalScore.graphics.drawRect(0,0,0.25*(WIDTH-2*MARGIN),13);
			globalScore.x = MARGIN;
			globalScore.y = MARGIN+17;
			globalScore.graphics.endFill();
			addChild(globalScore);
			
			
			var ysTextS:Sprite = new Sprite();
			addChild(ysTextS);
			var ysText:TextField = new TextField();
			ysText.autoSize = TextFieldAutoSize.LEFT;
			ysText.background = false;
			ysText.border = false;
			
			ysText.defaultTextFormat = format;
			
			ysTextS.addChild(ysText);
			ysText.text = "Your soothing praise:";
			ysTextS.x = MARGIN/2;
			ysTextS.y = MARGIN+17+17;
			
			yourScore = new Shape();
			yourScore.graphics.beginFill(TEAL);
			yourScore.graphics.drawRect(0,0,0.125*(WIDTH-2*MARGIN),5);
			yourScore.x = MARGIN;
			yourScore.y = MARGIN+17+17+17;
			yourScore.graphics.endFill();
			addChild(yourScore);
			
			loadSongs();
			loadScore();
			
			var theWaveSound:Sound = new WaveSound as Sound;
			theWaveArray = new ByteArray();
			theWaveSound.extract(theWaveArray,(44.100*theWaveSound.length));
			theWaveArray.position = 0;
		
			moddedWaveSound = new Sound();
			moddedWaveSound.addEventListener(SampleDataEvent.SAMPLE_DATA,waveSampler);
			moddedWaveSound.play();
			
			var theWindSound:Sound = new WindSound as Sound;
			theWindArray = new ByteArray();
			theWindSound.extract(theWindArray,(44.100*theWindSound.length));
			theWindArray.position = 0;
			
			moddedWindSound = new Sound();
			moddedWindSound.addEventListener(SampleDataEvent.SAMPLE_DATA,windSampler);
			moddedWindSound.play();
		}

		public function is_loud(wtick:int, notes:HushNote):Boolean{
			var cur:HushNote = notes;
			while(cur != null){
				if(wtick >= cur.start && wtick <= cur.end){
					return true;
				}
				cur = cur.prev;
			}
			
			return false;
		}
		
		public function waveSampler(event:SampleDataEvent):void{	
			var temp:Number;
			var whichTick:int = (tick+SOUND_LAG)%MEASURETICKS;
			var loud:Boolean = is_loud(whichTick,waveNotes);
			
			//This function only returns 2 ticks of data at a time
			for ( var c:int=0; c<2*1470; c++ ) {
				if(theWaveArray.bytesAvailable <= 0){
					theWaveArray.position = 0;
				}
				temp = theWaveArray.readFloat();
				
				if(c == 1470){
					whichTick = whichTick+1;
					loud = is_loud(whichTick,waveNotes);
				}
				
				if(!loud){
					temp = temp * 0.50;
				}
				event.data.writeFloat(temp);
				event.data.writeFloat(temp);
			}
		}
		
		public function windSampler(event:SampleDataEvent):void{	
			var temp:Number;
			var whichTick:int = (tick+SOUND_LAG)%MEASURETICKS;
			var loud:Boolean = is_loud(whichTick,windNotes);
			
			//This function only returns 2 ticks of data at a time
			for ( var c:int=0; c<2*1470; c++ ) {
				if(theWindArray.bytesAvailable <= 0){
					theWindArray.position = 0;
				}
				temp = theWindArray.readFloat();
				
				if(c == 1470){
					whichTick = whichTick+1;
					loud = is_loud(whichTick,windNotes);
				}
				
				if(!loud){
					temp = temp * 0.50;
				}
				event.data.writeFloat(temp);
				event.data.writeFloat(temp);
			}
		}
		
		public function changeMicLevel(event:MouseEvent):void 
		{ 
			if(event.stageX >= MARGIN && event.stageX <= (WIDTH-MARGIN)){
				var tempX:Number = event.stageX - MARGIN;
				tempX = tempX / (WIDTH-2*MARGIN);
				SILENCE_CUTOFF = tempX;
				micLevel.x = MARGIN + SILENCE_CUTOFF*(WIDTH-2*MARGIN);
			}
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
		
		public function loadScore():void
		{		
			var request:URLRequest = new URLRequest("http://hushsunhush.com/get_score.php");
			request.method = URLRequestMethod.GET;
			
			scoreLoader = new URLLoader();
			scoreLoader.addEventListener(Event.COMPLETE,scoreLoaded);
			
			try {
				scoreLoader.load(request);
			} catch (error:Error) {
				trace("Unable to load score.");
			}
		}
		
		public function postScore(pscore:int):void
		{
			var variables:URLVariables = new URLVariables();
			variables.score = pscore;
			variables.team = whichTeam;
			
			var request:URLRequest = new URLRequest("http://hushsunhush.com/put_score.php");
			request.method = URLRequestMethod.GET;
			request.data = variables;
			
			var scorePoster:URLLoader = new URLLoader();
			
			try {
				scorePoster.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			}
		}
		
		public function scoreLoaded(event:Event):void
		{
			var l:URLLoader = URLLoader(event.target);
			var results:Array = l.data.split(" ");
			
			globalScore.graphics.clear();
			globalScore.graphics.beginFill(TEAL);
			var scoreProp:Number = results[0]/MAX_SCORE;
			globalScore.graphics.drawRect(0,0,scoreProp*(WIDTH-2*MARGIN),13);
			globalScore.graphics.endFill();
			
			planet.y = 2*HEIGHT/3 - scoreProp*HEIGHT/3;
			
			//debugText.text = "Score: " + results[0] + ", Players" + results[1];
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
		
		var v1:Vector.<Boolean>;
		var v2:Vector.<Boolean>;
		
		public function match_percentage(notes1:HushNote, notes2:HushNote):Number
		{
			if(v1 == null || v2 == null){
				v1 = new Vector.<Boolean>(180);
				v2 = new Vector.<Boolean>(180);
			}
			
			
			var i:int;
			for(i = 0; i<180; i++){
				v1[i] = false;
				v2[i] = false;
			}
			
			while(notes1 != null){
				for(i=notes1.start; i <= notes1.end; i++){
					v1[i] = true;
				}
				notes1 = notes1.prev;
			}
			
			while(notes2 != null){
				for(i=notes2.start; i <= notes2.end; i++){
					v2[i] = true;
				}
				notes2 = notes2.prev;
			}
			
			var count:Number = 0;
			for(i = 0; i<180; i++){
				if(v1[i] == v2[i]){
					count++;
				}
			}
			
			return count/180.0;
		}
		
		public function scoreNotes(current:HushNote, previous:HushNote, team:HushNote):void
		{
			var thisScore:int = 0;
			
			//One point for each note in current, up to 5			
			var temp:HushNote = current;
			while(temp != null && thisScore < 5){
				temp = temp.prev;
				thisScore++;
			}
			
			//debugText.text = "";
			//Look for good, great, or perfect match with previous
			var matchPct:Number = match_percentage(current,previous);
			if(matchPct >= PERFECT){
				thisScore = thisScore * 2.0;
				//debugText.text += "Perfect ";
			} else if(matchPct >= GREAT){
				thisScore = thisScore * 1.67;
				//debugText.text += "Great   ";
			} else if(matchPct >= GOOD){
				thisScore = thisScore * 1.33;
				//debugText.text += "Good    ";
			} else {
				//debugText.text += "Bad     ";
			}
			
			//Do it again for matching the team song
			matchPct = match_percentage(current,team);
			if(matchPct >= PERFECT){
				thisScore = thisScore * 2.0;
				//debugText.text += "Perfect ";
			} else if(matchPct >= GREAT){
				thisScore = thisScore * 1.67;
				//debugText.text += "Great   ";
			} else if(matchPct >= GOOD){
				thisScore = thisScore * 1.33;
				//debugText.text += "Good    ";
			} else {
				//debugText.text += "Bad     ";
			}
			
			thisScore = Math.round(thisScore); //Round to nearest point value.
			//Max number of points possible is 5*2*2 = 20.
			
			if(current_score == 0.0){
				current_score = thisScore;
			} else {
				current_score = (thisScore + current_score)/2.0;
			}
			postScore(current_score);
			
			yourScore.graphics.clear();
			yourScore.graphics.beginFill(TEAL);
			yourScore.graphics.drawRect(0,0,(current_score/MAX_SCORE)*(WIDTH-2*MARGIN),5);
			yourScore.graphics.endFill();
			
			//debugText.text += thisScore.toString();
		}
		
		public function step ( event:Event ):void
		{
			tick++; //Keep a count of which frame we are on
			tick = tick % (FPS*SECPERFRAME*2);
			
			
			
			var myNotes:HushNote;
			var otNotes:HushNote;
			if(whichTeam == 0){
				myNotes = windNotes;
				otNotes = waveNotes;
			} else {
				myNotes = waveNotes;
				otNotes = windNotes;
			}
			
			/**
			 * Logic for switching measures goes here
			 */
			if(tick % MEASURETICKS == 0){
				if(curNotes != null && curNotes.end == -1){
					curNotes.end = (tick + MEASURETICKS - 1)%(MEASURETICKS);
				}

				scoreNotes(curNotes,prevNotes,myNotes);
				
				prevNotes = curNotes;
				curNotes = null;
				
				loadScore();
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
						
			micCheck.graphics.clear();
			micCheck.graphics.beginFill(TEAL);
			micCheck.graphics.drawRect(0,0,total*(WIDTH-2*MARGIN),5);
			micCheck.x = MARGIN;
			micCheck.y = HEIGHT-MARGIN;
			micCheck.graphics.endFill();
			
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
				
				firstx = firsttick*(WIDTH-2*MARGIN)/SCREENTICKS;
				lastx  = (lasttick+1)*(WIDTH-2*MARGIN)/SCREENTICKS;
				
				ret.graphics.beginFill(color);
				ret.graphics.lineStyle(1,color);
				ret.graphics.drawRect(firstx,vpos,lastx-firstx,5);
				ret.graphics.endFill();
				cur = cur.prev;
			}
			
		}
	}
}