package
{

		import __AS3__.vec.Vector;
		
		/**
		 * Performs an in-place complex FFT.
		 *
		 * Released under the MIT License
		 *
		 * Copyright (c) 2010 Gerald T. Beauregard
		 *
		 * Permission is hereby granted, free of charge, to any person obtaining a copy
		 * of this software and associated documentation files (the "Software"), to
		 * deal in the Software without restriction, including without limitation the
		 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
		 * sell copies of the Software, and to permit persons to whom the Software is
		 * furnished to do so, subject to the following conditions:
		 *
		 * The above copyright notice and this permission notice shall be included in
		 * all copies or substantial portions of the Software.
		 *
		 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
		 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
		 * IN THE SOFTWARE.
		 */
		public class FFT2
		{
			public static const FORWARD:Boolean = false;
			public static const INVERSE:Boolean = true;
			
			private var m_logN:uint = 0;			// log2 of FFT size
			private var m_N:uint = 0;				// FFT size
			private var m_invN:Number;				// Inverse of FFT length
			
			private var m_X:Vector.<FFTElement>;	// Vector of linked list elements
			
			/**
			 *
			 */
			public function FFT2()
			{
			}
			
			/**
			 * Initialize class to perform FFT of specified size.
			 *
			 * @param	logN	Log2 of FFT length. e.g. for 512 pt FFT, logN = 9.
			 */
			public function init(
				logN:uint ):void
			{
				m_logN = logN
				m_N = 1 << m_logN;
				m_invN = 1.0/m_N;
				
				// Allocate elements for linked list of complex numbers.
				m_X = new Vector.<FFTElement>(m_N);
				for ( var k:uint = 0; k < m_N; k++ )
					m_X[k] = new FFTElement;
				
				// Set up "next" pointers.
				for ( k = 0; k < m_N-1; k++ )
					m_X[k].next = m_X[k+1];
				
				// Specify target for bit reversal re-ordering.
				for ( k = 0; k < m_N; k++ )
					m_X[k].revTgt = BitReverse(k,logN);
			}
			
			/**
			 * Performs in-place complex FFT.
			 *
			 * @param	xRe		Real part of input/output
			 * @param	xIm		Imaginary part of input/output
			 * @param	inverse	If true (INVERSE), do an inverse FFT
			 */
			public function run(
				xRe:Vector.<Number>,
				xIm:Vector.<Number>,
				inverse:Boolean = false ):void
			{
				var numFlies:uint = m_N >> 1;	// Number of butterflies per sub-FFT
				var span:uint = m_N >> 1;		// Width of the butterfly
				var spacing:uint = m_N;			// Distance between start of sub-FFTs
				var wIndexStep:uint = 1; 		// Increment for twiddle table index
				
				// Copy data into linked complex number objects
				// If it's an IFFT, we divide by N while we're at it
				var x:FFTElement = m_X[0];
				var k:uint = 0;
				var scale:Number = inverse ? m_invN : 1.0;
				while (x)
				{
					x.re = scale*xRe[k];
					x.im = scale*xIm[k];
					x = x.next;
					k++;
				}
				
				// For each stage of the FFT
				for ( var stage:uint = 0; stage < m_logN; ++stage )
				{
					// Compute a multiplier factor for the "twiddle factors".
					// The twiddle factors are complex unit vectors spaced at
					// regular angular intervals. The angle by which the twiddle
					// factor advances depends on the FFT stage. In many FFT
					// implementations the twiddle factors are cached, but because
					// vector lookup is relatively slow in ActionScript, it's just
					// as fast to compute them on the fly.
					var wAngleInc:Number = wIndexStep * 2.0*Math.PI/m_N;
					if ( inverse == false ) // Corrected 3 Aug 2011. Had this condition backwards before, so FFT was IFFT, and vice-versa!
						wAngleInc *= -1;
					var wMulRe:Number = Math.cos(wAngleInc);
					var wMulIm:Number = Math.sin(wAngleInc);
					
					for ( var start:uint = 0; start < m_N; start += spacing )
					{
						var xTop:FFTElement = m_X[start];
						var xBot:FFTElement = m_X[start+span];
						
						var wRe:Number = 1.0;
						var wIm:Number = 0.0;
						
						// For each butterfly in this stage
						for ( var flyCount:uint = 0; flyCount < numFlies; ++flyCount )
						{
							// Get the top & bottom values
							var xTopRe:Number = xTop.re;
							var xTopIm:Number = xTop.im;
							var xBotRe:Number = xBot.re;
							var xBotIm:Number = xBot.im;
							
							// Top branch of butterfly has addition
							xTop.re = xTopRe + xBotRe;
							xTop.im = xTopIm + xBotIm;
							
							// Bottom branch of butterly has subtraction,
							// followed by multiplication by twiddle factor
							xBotRe = xTopRe - xBotRe;
							xBotIm = xTopIm - xBotIm;
							xBot.re = xBotRe*wRe - xBotIm*wIm;
							xBot.im = xBotRe*wIm + xBotIm*wRe;
							
							// Advance butterfly to next top & bottom positions
							xTop = xTop.next;
							xBot = xBot.next;
							
							// Update the twiddle factor, via complex multiply
							// by unit vector with the appropriate angle
							// (wRe + j wIm) = (wRe + j wIm) x (wMulRe + j wMulIm)
							var tRe:Number = wRe;
							wRe = wRe*wMulRe - wIm*wMulIm;
							wIm = tRe*wMulIm + wIm*wMulRe;
						}
					}
					
					numFlies >>= 1; 	// Divide by 2 by right shift
					span >>= 1;
					spacing >>= 1;
					wIndexStep <<= 1;  	// Multiply by 2 by left shift
				}
				
				// The algorithm leaves the result in a scrambled order.
				// Unscramble while copying values from the complex
				// linked list elements back to the input/output vectors.
				x = m_X[0];
				while (x)
				{
					var target:uint = x.revTgt;
					xRe[target] = x.re;
					xIm[target] = x.im;
					x = x.next;
				}
			}
			
			/**
			 * Do bit reversal of specified number of places of an int
			 * For example, 1101 bit-reversed is 1011
			 *
			 * @param	x		Number to be bit-reverse.
			 * @param	numBits	Number of bits in the number.
			 */
			private function BitReverse(
				x:uint,
				numBits:uint):uint
			{
				var y:uint = 0;
				for ( var i:uint = 0; i < numBits; i++)
				{
					y <<= 1;
					y |= x & 0x0001;
					x >>= 1;
				}
				return y;
			}
		}
	}

/**
 * A real-time spectrum analyzer.
 * 
 * Released under the MIT License
 *
 * Copyright (c) 2010 Gerald T. Beauregard
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

/*			[SWF(width='600', height='400', frameRate='30', backgroundColor='0xFFFFFF')]
public class HushSunHush2 extends Sprite
{
private const SAMPLE_RATE:Number = 22050;	// Actual microphone sample rate (Hz)
private const LOGN:uint = 11;				// Log2 FFT length
private const N:uint = 1 << LOGN;			// FFT Length
private const BUF_LEN:uint = N;				// Length of buffer for mic audio
private const UPDATE_PERIOD:int = 50;		// Period of spectrum updates (ms)

private var m_fft:FFT2;						// FFT object

private var m_tempRe:Vector.<Number>;		// Temporary buffer - real part
private var m_tempIm:Vector.<Number>;		// Temporary buffer - imaginary part
private var m_mag:Vector.<Number>;			// Magnitudes (at each of the frequencies below)
private var m_freq:Vector.<Number>;			// Frequencies (for each of the magnitudes above) 
private var m_win:Vector.<Number>;			// Analysis window (Hanning)

private var m_mic:Microphone;				// Microphone object
private var m_writePos:uint = 0;			// Position to write new audio from mic
private var m_buf:Vector.<Number> = null;	// Buffer for mic audio

private var m_tickTextAdded:Boolean = false; 

private var m_timer:Timer;					// Timer for updating spectrum


public function HushSunHush2()
{
var i:uint;

// Set up the FFT
m_fft = new FFT2();
m_fft.init(LOGN);
m_tempRe = new Vector.<Number>(N);
m_tempIm = new Vector.<Number>(N);
m_mag = new Vector.<Number>(N/2);
//m_smoothMag = new Vector.<Number>(N/2);

// Vector with frequencies for each bin number. Used 
// in the graphing code (not in the analysis itself).			
m_freq = new Vector.<Number>(N/2);
for ( i = 0; i < N/2; i++ )
m_freq[i] = i*SAMPLE_RATE/N;

// Hanning analysis window
m_win = new Vector.<Number>(N);
for ( i = 0; i < N; i++ )
m_win[i] = (4.0/N) * 0.5*(1-Math.cos(2*Math.PI*i/N));

// Create a buffer for the input audio
m_buf = new Vector.<Number>(BUF_LEN);
for ( i = 0; i < BUF_LEN; i++ )
m_buf[i] = 0.0;

// Set up microphone input
m_mic = Microphone.getMicrophone();
m_mic.rate = SAMPLE_RATE/1000;		
m_mic.setSilenceLevel(0.0);			// Have the mic run non-stop, regardless of the input level
m_mic.addEventListener( SampleDataEvent.SAMPLE_DATA, onMicSampleData );

// Set up a timer to do periodic updates of the spectrum		
m_timer = new Timer(UPDATE_PERIOD);
m_timer.addEventListener(TimerEvent.TIMER, updateSpectrum);
m_timer.start();
}

//
// Called whether new microphone input data is available. See this call
// above:
//    m_mic.addEventListener( SampleDataEvent.SAMPLE_DATA, onMicSampleData );

private function onMicSampleData( event:SampleDataEvent ):void
{
// Get number of available input samples
var len:uint = event.data.length/4;

// Read the input data and stuff it into 
// the circular buffer
for ( var i:uint = 0; i < len; i++ )
{
m_buf[m_writePos] = event.data.readFloat();
m_writePos = (m_writePos+1)%BUF_LEN;
}
}

//
// Called at regular intervals to update the spectrum
//
private function updateSpectrum( event:Event ):void
{
// Copy data from circular microphone audio 
// buffer into temporary buffer for FFT, while
// applying Hanning window.
var i:int;
var pos:uint = m_writePos;
for ( i = 0; i < N; i++ )
{
m_tempRe[i] = m_win[i]*m_buf[pos];
pos = (pos+1)%BUF_LEN;
}

// Zero out the imaginary component
for ( i = 0; i < N; i++ )
m_tempIm[i] = 0.0;

// Do FFT and get magnitude spectrum
m_fft.run( m_tempRe, m_tempIm );
for ( i = 0; i < N/2; i++ )
{
var re:Number = m_tempRe[i];
var im:Number = m_tempIm[i];
m_mag[i] = Math.sqrt(re*re + im*im);
}

// Convert to dB magnitude
const SCALE:Number = 20/Math.LN10;		
for ( i = 0; i < N/2; i++ )
{
// 20 log10(mag) => 20/ln(10) ln(mag)
// Addition of MIN_VALUE prevents log from returning minus infinity if mag is zero
m_mag[i] = SCALE*Math.log( m_mag[i] + Number.MIN_VALUE );
}

// Draw the graph
drawSpectrum( m_mag, m_freq );
}

//
//Draw a graph of the spectrum
//
private function drawSpectrum( 
mag:Vector.<Number>,
freq:Vector.<Number> ):void
{
// Basic constants
const MIN_FREQ:Number = 0;					// Minimum frequency (Hz) on horizontal axis.
const MAX_FREQ:Number = 8000;				// Maximum frequency (Hz) on horizontal axis.
const FREQ_STEP:Number = 500;				// Interval between ticks (Hz) on horizontal axis.
const MAX_DB:Number = -0.0;					// Maximum dB magnitude on vertical axis.
const MIN_DB:Number = -60.0;				// Minimum dB magnitude on vertical axis.
const DB_STEP:Number = 10;					// Interval between ticks (dB) on vertical axis.
const TOP:Number  = 50;						// Top of graph
const LEFT:Number = 60;						// Left edge of graph
const HEIGHT:Number = 300;					// Height of graph
const WIDTH:Number = 500;					// Width of graph
const TICK_LEN:Number = 10;					// Length of tick in pixels
const LABEL_X:String = "Frequency (Hz)";	// Label for X axis
const LABEL_Y:String = "dB";				// Label for Y axis

// Derived constants
const BOTTOM:Number = TOP+HEIGHT;					// Bottom of graph
const DBTOPIXEL:Number = HEIGHT/(MAX_DB-MIN_DB);	// Pixels/tick
const FREQTOPIXEL:Number = WIDTH/(MAX_FREQ-MIN_FREQ);// Pixels/Hz 

//-----------------------			

var i:uint;
var numPoints:uint;

numPoints = mag.length;
if ( mag.length != freq.length )
trace( "mag.length != freq.length" );

graphics.clear();

// Draw a rectangular box marking the boundaries of the graph
graphics.lineStyle( 1, 0x000000 );
graphics.drawRect( LEFT, TOP, WIDTH, HEIGHT );
graphics.moveTo(LEFT, TOP+HEIGHT);

//--------------------------------------------

// Tick marks on the vertical axis			
var y:Number;
var x:Number;
for ( var dBTick:Number = MIN_DB; dBTick <= MAX_DB; dBTick += DB_STEP )
{
y = BOTTOM - DBTOPIXEL*(dBTick-MIN_DB);
graphics.moveTo( LEFT-TICK_LEN/2, y );
graphics.lineTo( LEFT+TICK_LEN/2, y );
if ( m_tickTextAdded == false )
{
// Numbers on the tick marks
var t:TextField = new TextField();
t.text = int(dBTick).toString();
t.width = 0;
t.height = 20;
t.x = LEFT-20;
t.y = y - t.textHeight/2;
t.autoSize = TextFieldAutoSize.CENTER;
addChild(t);
}
} 

// Label for vertical axis
if ( m_tickTextAdded == false )
{
t = new TextField();
t.text = LABEL_Y;
t.x = LEFT-50;
t.y = TOP + HEIGHT/2 - t.textHeight/2;
t.height = 20;
t.width = 50;
//t.rotation = -90;
addChild(t);
}

//--------------------------------------------

// Tick marks on the horizontal axis
for ( var f:Number = MIN_FREQ; f <= MAX_FREQ; f += FREQ_STEP )
{
x = LEFT + FREQTOPIXEL*(f-MIN_FREQ);
graphics.moveTo( x, BOTTOM - TICK_LEN/2 );
graphics.lineTo( x, BOTTOM + TICK_LEN/2 );
if ( m_tickTextAdded == false )
{
t = new TextField();
t.text = int(f).toString();
t.width = 0;
t.x = x;
t.y = BOTTOM+7;
t.autoSize = TextFieldAutoSize.CENTER;
addChild(t);
}
}

// Label for horizontal axis 
if ( m_tickTextAdded == false )
{
t = new TextField();
t.text = LABEL_X;
t.width = 0;
t.x = LEFT+WIDTH/2;
t.y = BOTTOM+30;
t.autoSize = TextFieldAutoSize.CENTER;
addChild(t);
}

m_tickTextAdded = true;

// -------------------------------------------------			
// The line in the graph

// Ignore points that are too far to the left
for ( i = 0; i < numPoints && freq[i] < MIN_FREQ; i++ )
{
}

// For all remaining points within range of x-axis			
var firstPoint:Boolean = true;
for ( ; i < numPoints && freq[i] <= MAX_FREQ; i++ )
{
// Compute horizontal position
x = LEFT + FREQTOPIXEL*(freq[i]-MIN_FREQ);

// Compute vertical position of point
// and clip at top/bottom.
y = BOTTOM - DBTOPIXEL*(mag[i]-MIN_DB);
if ( y < TOP )
y = TOP;
else if ( y > BOTTOM )
y = BOTTOM;

// If it's the first point				
if ( firstPoint )
{
// Move to the point
graphics.moveTo(x,y);
firstPoint = false;
}
else
{
// Otherwise, draw line from the previous point
graphics.lineTo(x,y);
}
}
}			
}
}*/