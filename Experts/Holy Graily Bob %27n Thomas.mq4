//+-------------------------------------------------------------------+
//|                                    Holy Graily Bob 'n Thomas.mq4  |
//|                                    Copyright 2012, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+

//This EA is inspired by Thomas' MTF HGI at http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=27&t=5313

#define  version "Version 1a"

#property copyright "Copyright 2012, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"
#define  up "Up"
#define  down "Down"
#define  ranging "Ranging"
#define  none "None"
#define  both "Both"
#define  buy "Buy"
#define  sell "Sell"

//Using hgi_lib
//The HGI library functionality was added by tomele. Many thanks Thomas.
#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

//Hgi status constants
#define  hgiup ": Up"
#define  hgidown ": Down"
#define  hgiranging ": Ranging"
#define  hginosignal ": no relevant signal"//For the trading time frame. The HTF's will have a signal

//HGI trading status
#define  tradablelong ": Tradable long."
#define  tradableshort ": Tradable short."
#define  untradable ": Untradable."


#define  AllTrades 10 //Tells CloseAllTrades() to close/delete everything
#define  million 1000000;

//Define the FifoBuy/SellTicket fields
#define  TradeOpenTime 0
#define  TradeTicket 1
#define  TradeProfitCash 2 //Cash profit
#define  TradeProfitPips 3 //Pips profit

//Define the GridBuy/SellTicket fields
#define  TradeOpenPrice 0
//#define  TradeTicket 1 /// can use the one above.



//Pending trade price line
#define  pendingpriceline "Pending price line"
//Hidden sl and tp lines. If used, the bot will close trades on a touch/break of these lines.
//Each line is named with its appropriate prefix and the ticket number of the relevant trade
#define  TpPrefix "Tp"
#define  SlPrefix "Sl"


//Error reporting
#define  slm " stop loss modification failed with error "
#define  tpm " take profit modification failed with error "
#define  ocm " order close failed with error "
#define  odm " order delete failed with error "
#define  pcm " part close failed with error "
#define  spm " shirt-protection close failed with error "
#define  slim " stop loss insertion failed with error "
#define  tpim " take profit insertion failed with error "
#define  tpsl " take profit or stop loss insertion failed with error "
#define  oop " pending order price modification failed with error "

/*


  
Matt Kennel has provided the code for bool O_R_CheckForHistory(int ticket). Cheers Matt, You are a star.

Code for adding debugging Sleep
Alert("G");
int x = 0;
while (x == 0) Sleep(100);

Standard order loop code
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

Code from George, to detect the shift of an order open time
int shift = iBarShift(NULL,Period(),OrderOpenTime(), false);

To calculate what percentage a small number is of a larger one:
(Given amount Divided by Total amount) x100 = %
as in UpperWickPercentage = (UpperWick / CandleSize) * 100; where CandleSize is the size of the the candle and UpperWick the size of the top of the body to the High.

Example of iHighest and iLowest
double high = iHigh( Symbol(), TradingTimeFrame, iHighest( Symbol(), TradingTimeFrame, MODE_HIGH, 24, 1 ) );
double low = iLow( Symbol(), TradingTimeFrame, iLowest( Symbol(), TradingTimeFrame, MODE_LOW, 24, 1 ) );

   Full snippet to force closure of all open trades. Use whichever part is most appropriate.
   if (ForceTradeClosure)
   {
      CloseAllTrades();
      if (ForceTradeClosure)
      {
         CloseAllTrades();
         if (ForceTradeClosure)
         {
            return;
         }//if (ForceTradeClosure)                     
      }//if (ForceTradeClosure)         
   }//if (ForceTradeClosure)      

*/


extern string  gen="----General inputs----";
extern double  Lot=0.01;
extern double  RiskPercent=0;//Set to zero to disable and use Lot
extern double  LotsPerDollopOfCash=0.01;//Over rides Lot. Zero input to cancel.
extern double  SizeOfDollop=1000;
extern bool    UseBalance=false;
extern bool    UseEquity=true;
extern int     MaxTradesAllowed=1;//For multi-trade EA's
extern bool    StopTrading=false;
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern int     TakeProfitPips=100;
extern int     StopLossPips=100;
extern int     MagicNumber=0;
extern string  TradeComment="HGB 'n T";
extern bool    IsGlobalPrimeOrECNCriminal=false;
extern double  MaxSlippagePips=5;
//We need more safety to combat the cretins at Crapperquotes managing to break Matt's OR code occasionally.
//EA will make no further attempt to trade for PostTradeAttemptWaitMinutes minutes, whether OR detects a receipt return or not.
extern int     PostTradeAttemptWaitSeconds=600;//Defaults to 10 minutes
////////////////////////////////////////////////////////////////////////////////////////
datetime       TimeToStartTrading=0;//Re-start calling LookForTradingOpportunities() at this time.
double         TakeProfit, StopLoss;
datetime       OldBarsTime;
double         dPriceFloor = 0, dPriceCeiling = 0;//Next x0 numbers
double         PriceCeiling100 = 0, PriceFloor100 = 0;// Next 'big' numbers

string         GvName="Under management flag";//The name of the GV that tells the EA not to send trades whilst the manager is closing them.
//'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
string         LocalGvName = "Local closure in operation " + Symbol();
//'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
string         NuclearGvName = "Nuclear option closure in operation " + Symbol();

//For FIFO
int            FifoTicket[];//Array to store trade ticket numbers in FIFO mode, to cater for
                            //US citizens and to make iterating through the trade closure loop 
                            //quicker.
//An array to store ticket numbers of trades that need closing, should an offsetting OrderClose fail
double         ForceCloseTickets[];
bool           RemoveExpert=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1="================================================================";
extern string  hgii="---- HGI Inputs ----";
extern string  ttf="-- Trading time frame --";
/*
Note to coders about TradingTimeFrame. Be consistent in your calls to indicators etc and always use TradingTimeFrame i.e.
double v = iClose(Symbol(), TradingTimeFrame, shift) instead of Close[shift].
This allows the user to change time frames without disturbing the ea. There is a line of code in OnInit(), just above the call
to DisplayUserFeedback() that forces the EA to wait until the open of a new TradingTimeFrame candle; you might want to comment
this out during your EA development.
*/
extern ENUM_TIMEFRAMES TradingTimeFrame=PERIOD_M15;//Defaults to current chart
extern bool    EveryTickMode=false;
extern bool    TradeTrendArrows=true;
extern bool    TradeBlueWavyLines=true;
extern bool    HgiCloseOnOppositeSignal=true;
extern bool    HgiCloseOnYellowWavy=true;
////////////////////////////////////////////////////////////////////////////////////////
string         TradeHgiStatus;//Constants defined at top of file
string         TradingTimeFrameDisplay="";
//A variable to hold the trading status of the combined HGI time frames
string         HgiTradingStatus="";
////////////////////////////////////////////////////////////////////////////////////////

//Higher time frames
extern string  hsep1="---- Higher time frames ----";
extern int     HtfMinimumAlignment=3;//The number of HTF HGI that must line up before trading is allowed
////////////////////////////////////////////////////////////////////////////////////////
int            BuysAligned=0, SellsAligned=0;
////////////////////////////////////////////////////////////////////////////////////////
extern string  htf1="-- Higher time frame 1 --";
extern ENUM_TIMEFRAMES HigherTimeFrame1=PERIOD_H1;//Defaults to current chart
////////////////////////////////////////////////////////////////////////////////////////
string         HtfHgiStatus1;//Constants defined at top of file
string         HtfHgiTimeFrameDisplay1="";
////////////////////////////////////////////////////////////////////////////////////////

string         hsep2="----";
extern string  htf2="-- Higher time frame 2 --";
extern ENUM_TIMEFRAMES HigherTimeFrame2=PERIOD_H4;//Defaults to current chart
////////////////////////////////////////////////////////////////////////////////////////
string         HtfHgiStatus2;//Constants defined at top of file
string         HtfHgiTimeFrameDisplay2="";
////////////////////////////////////////////////////////////////////////////////////////

string         hsep3="----";
extern string  htf3="-- Higher time frame 3 --";
extern ENUM_TIMEFRAMES HigherTimeFrame3=PERIOD_D1;//Defaults to current chart
////////////////////////////////////////////////////////////////////////////////////////
string         HtfHgiStatus3;//Constants defined at top of file
string         HtfHgiTimeFrameDisplay3="";
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1a="================================================================";
extern string  sfs="----SafetyFeature----";
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Use the next input 
//in combination with TooClose() to abort the trade if the previous one closed within the time limit.
extern int     MinMinutesBetweenTradeOpenClose=1;//For spotting possible rogue trades
extern int     MinMinutesBetweenTrades=1;//Minimum time to pass after a trade closes, until the ea can open another.
////////////////////////////////////////////////////////////////////////////////////////
bool           SafetyViolation;//For chart display
bool           RobotSuspended=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep2="================================================================";
//Hidden tp/sl inputs.
extern string  hts="----Stealth stop loss and take profit inputs----";
extern int     PipsHiddenFromCriminal=0;//Added to the 'hard' sl and tp and used for closure calculations
                                         ////////////////////////////////////////////////////////////////////////////////////////
double         HiddenStopLoss,HiddenTakeProfit;
double         HiddenPips=0;//Added to the 'hard' sl and tp and used for closure calculations
                             ////////////////////////////////////////////////////////////////////////////////////////

string   sep3="================================================================";
//Bob's H4 240 trend filter. Market above the ma = buy only; below ma = sell only
extern string  mai="---- Moving average ----";
extern ENUM_TIMEFRAMES MaTF=PERIOD_CURRENT;//Defaults to current chart
extern int     MaShift=0;
extern int     MaPeriod=0;//Zero value to disable
extern ENUM_MA_METHOD MaMethod= MODE_EMA;
extern ENUM_APPLIED_PRICE MaAppliedPrice=PRICE_CLOSE;
////////////////////////////////////////////////////////////////////////////////////////
double         MaVal;
string         MaTrend;//up, down or none constants
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep7="================================================================";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string  trh            = "----Trading hours----";
extern string  tr1            = "tradingHours is a comma delimited list";
extern string  tr1a="of start and stop times.";
extern string  tr2="Prefix start with '+', stop with '-'";
extern string  tr2a="Use 24H format, local time.";
extern string  tr3="Example: '+07.00,-10.30,+14.15,-16.00'";
extern string  tr3a="Do not leave spaces";
extern string  tr4="Blank input means 24 hour trading.";
extern string  tradingHours="";
////////////////////////////////////////////////////////////////////////////////////////
double         TradeTimeOn[];
double         TradeTimeOff[];
// trading hours variables
int            tradeHours[];
string         tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool           TradeTimeOk;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep1de="================================================================";
extern string  fssmt="---- Inputs applied to individual days ----";
extern int     FridayStopTradingHour=14;//Ignore signals at and after this time on Friday.
                                        //Local time input. >23 to disable.
extern int     SaturdayStopTradingHour=24;//For those in Upside Down Land.  
extern bool    TradeSundayCandle=false;
extern int     MondayStartHour=8;//24h local time     
extern bool    TradeThursdayCandle=true;//Thursday tends to be a reversal day, so avoid it.                               

//This code by tomele. Thank you Thomas. Wonderful stuff.
extern string  sep7b="================================================================";
extern string  roll="---- Rollover time ----";
extern bool    DisableEaDuringRollover=true;
extern string  ro1 = "Use 24H format, SERVER time.";
extern string  ro2 = "Example: '23.55'";
extern string  RollOverStarts="23.55";
extern string  RollOverEnds="00.15";
////////////////////////////////////////////////////////////////////////////////////////
bool           RolloverInProgress=false;//Tells DisplayUserFeedback() to display the rollover message
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep8="================================================================";
extern string  bf="----Trading balance filters----";
extern bool    UseZeljko=false;
extern bool    OnlyTradeCurrencyTwice=false;
////////////////////////////////////////////////////////////////////////////////////////
bool           CanTradeThisPair;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep9="================================================================";
extern string  pts="----Swap filter----";
extern bool    CadPairsPositiveOnly=false;
extern bool    AudPairsPositiveOnly=false;
extern bool    NzdPairsPositiveOnly=false;
extern bool    OnlyTradePositiveSwap=false;
////////////////////////////////////////////////////////////////////////////////////////
double         LongSwap,ShortSwap;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep10="================================================================";
extern string  amc="----Available Margin checks----";
extern string  sco="Scoobs";
extern bool    UseScoobsMarginCheck=false;
extern string  fk="ForexKiwi";
extern bool    UseForexKiwi=false;
extern int     FkMinimumMarginPercent=1500;
////////////////////////////////////////////////////////////////////////////////////////
bool           EnoughMargin;
string         MarginMessage;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11="================================================================";
extern string  asi="----Average spread inputs----";
bool    RunInSpreadDetectionMode=false;
extern int     TicksToCount=5;//The ticks to count whilst canculating the av spread
extern double  MultiplierToDetectStopHunt=10;
////////////////////////////////////////////////////////////////////////////////////////
double         AverageSpread=0;
string         SpreadGvName;//A GV will hold the calculated average spread
int            CountedTicks=0;//For status display whilst calculating the spread
double         BiggestSpread=0;//Holds a record of the widest spread since the EA was loaded
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep11a="================================================================";
extern string  ccs="---- Chart snapshots ----";
extern bool    TakeSnapshots=true;//Tells ea to take snaps when it opens and closes a trade
extern int     PictureWidth=800;
extern int     PictureHeight=600;

extern string  sep12="================================================================";
extern string  ems="----Email thingies----";
extern bool    EmailTradeNotification=false;
extern bool    SendAlertNotTrade=false;
extern bool    AlertPush=false;// Enable to send push notification on alert
////////////////////////////////////////////////////////////////////////////////////////
bool           AlertSent;//To alert to a trade trigger without actually sending the trade
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep13="================================================================";
extern string  tmm="----Trade management module----";
//Breakeven has to be enabled for JS and TS to work.
extern string  BE="Break even settings";
extern bool    BreakEven=false;
extern int     BreakEvenTargetPips=10;
extern int     BreakEvenTargetProfit=5;
extern bool    PartCloseEnabled=false;
extern double  PartClosePercent=50;//Percentage of the trade lots to close
////////////////////////////////////////////////////////////////////////////////////////
double         BreakEvenPips,BreakEvenProfit;
bool           TradeHasPartClosed=false;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep14="================================================================";
extern string  JSL="Jumping stop loss settings";
extern bool    JumpingStop=false;
extern int     JumpingStopTargetPips=10;
extern bool    AddBEP=true;
////////////////////////////////////////////////////////////////////////////////////////
double         JumpingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

extern string  sep15="================================================================";
extern string  cts="----Candlestick jumping stop----";
extern bool    UseCandlestickTrailingStop=false;
extern int     CstTimeFrame=0;//Defaults to current chart
extern int     CstTrailCandles=1;//Defaults to previous candle
extern bool    TrailMustLockInProfit=true;
////////////////////////////////////////////////////////////////////////////////////////
int            OldCstBars;//For candlestick ts
                           ////////////////////////////////////////////////////////////////////////////////////////

extern string  sep16="================================================================";
extern string  TSL="Trailing stop loss settings";
extern bool    TrailingStop=false;
extern int     TrailingStopTargetPips=20;
////////////////////////////////////////////////////////////////////////////////////////
double         TrailingStopPips;
////////////////////////////////////////////////////////////////////////////////////////

//Enhanced screen feedback display code provided by Paul Batchelor (lifesys). Thanks Paul; this is fantastic.
extern string  se52  ="================================================================";
extern string  oad               ="----Odds and ends----";
extern int     ChartRefreshDelaySeconds=3;
extern int     DisplayGapSize    = 30; // if using Comments
// ****************************** added to make screen Text more readable
extern bool    DisplayAsText     = true;  // replaces Comment() with OBJ_LABEL text
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 100;
extern int     DisplayY          = 0;
extern int     fontSise          = 10;
extern string  fontName          = "Arial";
extern color   colour            = Yellow;
////////////////////////////////////////////////////////////////////////////////////////
int            DisplayCount;
string         Gap,ScreenMessage;
////////////////////////////////////////////////////////////////////////////////////////
//  *****************************

//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn of Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
//string         pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
//double         pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
//And by Steve. I have pinched Tomasso's APTM function for returning the value of factor. Thanks Tommaso
double         factor;//For pips/points stuff. Set up in int init()
////////////////////////////////////////////////////////////////////////////////////////

//Matt's O-R stuff
int            O_R_Setting_max_retries=10;
double         O_R_Setting_sleep_time=4.0; /* seconds */
double         O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.


//Running total of trades
int            LossTrades,WinTrades;
double         OverallProfit;

//Misc
int            OldBars;
string         PipDescription=" pips";
bool           ForceTradeClosure;
int            TurnOff=0;//For turning off functions without removing their code

//Variables for building a picture of the open position
int            MarketTradesTotal=0;//Total of open market trades
//Market Buy trades
bool           BuyOpen=false;
int            MarketBuysCount=0;
double         LatestBuyPrice=0, EarliestBuyPrice=0, HighestBuyPrice=0, LowestBuyPrice=0;
int            BuyTicketNo=-1, HighestBuyTicketNo=-1, LowestBuyTicketNo=-1, LatestBuyTicketNo=-1, EarliestBuyTicketNo=-1;
double         BuyPipsUpl=0;
double         BuyCashUpl=0;
datetime       LatestBuyTradeTime=0;
datetime       EarliestBuyTradeTime=0;

//Market Sell trades
bool           SellOpen=false;
int            MarketSellsCount=0;
double         LatestSellPrice=0, EarliestSellPrice=0, HighestSellPrice=0, LowestSellPrice=0;
int            SellTicketNo=-1, HighestSellTicketNo=-1, LowestSellTicketNo=-1, LatestSellTicketNo=-1, EarliestSellTicketNo=-1;;
double         SellPipsUpl=0;
double         SellCashUpl=0;
datetime       LatestSellTradeTime=0;
datetime       EarliestSellTradeTime=0;

//BuyStop trades
bool           BuyStopOpen=false;
int            BuyStopsCount=0;
double         LatestBuyStopPrice=0, EarliestBuyStopPrice=0, HighestBuyStopPrice=0, LowestBuyStopPrice=0;
int            BuyStopTicketNo=-1, HighestBuyStopTicketNo=-1, LowestBuyStopTicketNo=-1, LatestBuyStopTicketNo=-1, EarliestBuyStopTicketNo=-1;;
datetime       LatestBuyStopTradeTime=0;
datetime       EarliestBuyStopTradeTime=0;

//BuyLimit trades
bool           BuyLimitOpen=false;
int            BuyLimitsCount=0;
double         LatestBuyLimitPrice=0, EarliestBuyLimitPrice=0, HighestBuyLimitPrice=0, LowestBuyLimitPrice=0;
int            BuyLimitTicketNo=-1, HighestBuyLimitTicketNo=-1, LowestBuyLimitTicketNo=-1, LatestBuyLimitTicketNo=-1, EarliestBuyLimitTicketNo=-1;;
datetime       LatestBuyLimitTradeTime=0;
datetime       EarliestBuyLimitTradeTime=0;

/////SellStop trades
bool           SellStopOpen=false;
int            SellStopsCount=0;
double         LatestSellStopPrice=0, EarliestSellStopPrice=0, HighestSellStopPrice=0, LowestSellStopPrice=0;
int            SellStopTicketNo=-1, HighestSellStopTicketNo=-1, LowestSellStopTicketNo=-1, LatestSellStopTicketNo=-1, EarliestSellStopTicketNo=-1;;
datetime       LatestSellStopTradeTime=0;
datetime       EarliestSellStopTradeTime=0;

//SellLimit trades
bool           SellLimitOpen=false;
int            SellLimitsCount=0;
double         LatestSellLimitPrice=0, EarliestSellLimitPrice=0, HighestSellLimitPrice=0, LowestSellLimitPrice=0;
int            SellLimitTicketNo=-1, HighestSellLimitTicketNo=-1, LowestSellLimitTicketNo=-1, LatestSellLimitTicketNo=-1, EarliestSellLimitTicketNo=-1;;
datetime       LatestSellLimitTradeTime=0;
datetime       EarliestSellLimitTradeTime=0;

//Not related to specific order types
int            TicketNo=-1,OpenTrades,OldOpenTrades;
//Variables to tell the ea that it has a trading signal
bool           BuySignal=false, SellSignal=false;
//Variables to tell the ea that it has a trading closure signal
bool           BuyCloseSignal=false, SellCloseSignal=false;
//Variables for storing market trade ticket numbers
datetime       LatestTradeTime=0, EarliestTradeTime=0;//More specific times are in each individual section
int            LatestTradeTicketNo=-1, EarliestTradeTicketNo=-1;
double         PipsUpl;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
double         CashUpl;//For keeping track of the cash PipsUpl of multi-trade/hedged positions
//Variable for the hedging code to tell if there are tp's and sl's set
bool           TpSet=false, SlSet=false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayUserFeedback()
{

   if(IsTesting() && !IsVisualMode()) return;

   string text = "";

   //cpu saving
   static datetime CurrentTime = 0;
   static datetime DisplayNow = 0;
   if (TimeCurrent() < DisplayNow )
      return;
   CurrentTime = TimeCurrent();
   DisplayNow = CurrentTime + ChartRefreshDelaySeconds;

 
 
//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   ScreenMessage="";
   //ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);
   if(SafetyViolation) SM("*************** CANNOT TRADE YET. TOO SOON AFTER CLOSE OF PREVIOUS TRADE***************"+NL);

   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com"+NL);
   SM("Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);
/*
   //Code for time to bar-end display donated by Baluda. Cheers Paul.
   SM( TimeToString( iTime(Symbol(), TradingTimeFrame, 0) + TradingTimeFrame * 60 - CurTime(), TIME_MINUTES|TIME_SECONDS ) 
   + " left to bar end" + NL );
   */
   if(!TradeTimeOk)
   {
      SM(NL);
      SM("---------- OUTSIDE TRADING HOURS. Will continue to monitor opent trades. ----------"+NL+NL);
   }//if (!TradeTimeOk)

   if(RolloverInProgress)
   {
      SM(NL);
      SM("---------- ROLLOVER IN PROGRESS. I am taking no action until "+RollOverEnds+" ----------"+NL+NL);
      return;
   }//if (RolloverInProgress)

   SM(NL);
   
   SM(TradingTimeFrameDisplay + " HGI signal status" +  TradeHgiStatus + NL);
   SM(HtfHgiTimeFrameDisplay1 + " HGI signal status" + HtfHgiStatus1 + NL);
   SM(HtfHgiTimeFrameDisplay2 + " HGI signal status" + HtfHgiStatus2 + NL);
   SM(HtfHgiTimeFrameDisplay3 + " HGI signal status" + HtfHgiStatus3 + NL);
   SM("Combined higher time frames trading status" + HgiTradingStatus + NL);
   

   SM(NL);
   if(MaPeriod>0) SM("Moving average = "+DoubleToStr(MaVal,Digits)+": Trend is "+MaTrend+NL);
   
  
   
   SM(NL);     
   text = "Market trades open = ";
   SM(text + IntegerToString(MarketTradesTotal) + ": Pips UPL = " + DoubleToStr(PipsUpl, 0)
   +  ": Cash UPL = " + DoubleToStr(CashUpl, 2) + NL);
   if (BuyOpen)
      SM("Buy trades = " + IntegerToString(MarketBuysCount)
         + ": Pips upl = " + IntegerToString(BuyPipsUpl)
         + ": Cash upl = " + DoubleToStr(BuyCashUpl, 2)
         + NL);
   if (SellOpen)
      SM("Sell trades = " + IntegerToString(MarketSellsCount)
         + ": Pips upl = " + IntegerToString(SellPipsUpl)
         + ": Cash upl = " + DoubleToStr(SellCashUpl,2)
         + NL);

   text = "No trade signal";
   if (BuySignal)
      text = "We have a buy signal";
   if (SellSignal)
      text = "We have a sell signal";
   SM(text + NL);

   SM(NL);
   SM("Trading time frame: " + TradingTimeFrameDisplay + NL);
   if(TradeLong) SM("Taking long trades"+NL);
   if(TradeShort) SM("Taking short trades"+NL);
   if(!TradeLong && !TradeShort) SM("Both TradeLong and TradeShort are set to false"+NL);
   SM("Lot size: "+DoubleToStr(Lot,2)+" (Criminal's minimum lot size: "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),2)+")"+NL);
   if(!CloseEnough(TakeProfit,0)) SM("Take profit: "+DoubleToStr(TakeProfit,0)+PipDescription+NL);
   if(!CloseEnough(StopLoss,0)) SM("Stop loss: "+DoubleToStr(StopLoss,0)+PipDescription+NL);
   SM("Magic number: "+MagicNumber+NL);
   SM("Trade comment: "+TradeComment+NL);
   if(IsGlobalPrimeOrECNCriminal) SM("IsGlobalPrimeOrECNCriminal = true"+NL);
   else SM("IsGlobalPrimeOrECNCriminal = false"+NL);
   double spread=(Ask-Bid)*factor;
   SM("Average Spread = "+DoubleToStr(AverageSpread,1)+": Spread = "+DoubleToStr(spread,1)+": Widest since loading = "+DoubleToStr(BiggestSpread,1)+NL);
   SM("Long swap "+DoubleToStr(LongSwap,2)+": ShortSwap "+DoubleToStr(ShortSwap,2)+NL);
   SM(NL);

   //Trading hours
   if(tradingHoursDisplay!="") SM("Trading hours: "+tradingHoursDisplay+NL);
   else SM("24 hour trading: "+NL);

   if(MarginMessage!="") SM(MarginMessage+NL);

   //Running total of trades
   SM(Gap+NL);
   SM("Results today. Wins: "+WinTrades+": Losses "+LossTrades+": P/L "+DoubleToStr(OverallProfit,2)+NL);

   SM(NL);

   if(BreakEven)
   {
      SM("Breakeven is set to "+DoubleToStr(BreakEvenPips,0)+PipDescription+": BreakEvenProfit = "+DoubleToStr(BreakEvenProfit,0)+PipDescription);
      SM(NL);
      if(PartCloseEnabled)
      {
         double CloseLots=NormalizeLots(Symbol(),Lot *(PartClosePercent/100));
         SM("Part-close is enabled at "+DoubleToStr(PartClosePercent,2)+"% ("+DoubleToStr(CloseLots,2)+" lots to close)"+NL);
      }//if (PartCloseEnabled)      
   }//if (BreakEven)

   if(UseCandlestickTrailingStop)
   {
      SM("Using candlestick trailing stop"+NL);
   }//if (UseCandlestickTrailingStop)

   if(JumpingStop)
   {
      SM("Jumping stop is set to "+DoubleToStr(JumpingStopPips,0)+PipDescription);
      SM(NL);
   }//if (JumpingStop)

   if(TrailingStop)
   {
      SM("Trailing stop is set to "+DoubleToStr(TrailingStopPips,0)+PipDescription);
      SM(NL);
   }//if (TrailingStop)


   Comment(ScreenMessage);

}//void DisplayUserFeedback()
  
//+--------------------------------------------------------------------+
//| Paul Bachelor's (lifesys) text display module to replace Comment()|
//+--------------------------------------------------------------------+
void SM(string message)
{
   if (DisplayAsText) 
   {
      DisplayCount++;
      Display(message);
   }
   else
      ScreenMessage = StringConcatenate(ScreenMessage,Gap, message);
      
}//End void SM()

//   ************************* added for OBJ_LABEL
void removeAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   if (StringFind(ObjectName(i),"OAM-",0) > -1) 
      ObjectDelete(ObjectName(i));
}//End void removeAllObjects()
//   ************************* added for OBJ_LABEL

void Display(string text)
{
    string lab_str = "OAM-" + IntegerToString(DisplayCount);  
    double ofset = 0;
    string textpart[5];
    uint w,h;
   
    for (int cc = 0; cc < 5; cc++)
    {
       textpart[cc] = StringSubstr(text,cc*63,64);
       if (StringLen(textpart[cc]) ==0) continue;
       lab_str = lab_str + IntegerToString(cc);
     
       ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
       ObjectSet(lab_str, OBJPROP_CORNER, 0);
       ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset);
       ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(int)(fontSise*1.5));
       ObjectSet(lab_str, OBJPROP_BACK, false);
       ObjectSetText(lab_str, textpart[cc], fontSise, fontName, colour);
     
       /////////////////////////////////////////////////
       //Calculate label size
       //Tomele supplied this code to eliminate the gaps in the text.
       //Thanks Thomas.
       TextSetFont(fontName,-fontSise*10,0,0);
       TextGetSize(textpart[cc],w,h);
     
       //Trim trailing space
       if (StringSubstr(textpart[cc],63,1)==" ")
          ofset+=(int)(w-fontSise*0.3);
       else
          ofset+=(int)(w-fontSise*0.7);
       /////////////////////////////////////////////////
         
    }//for (int cc = 0; cc < 5; cc++)
}//End void Display(string text)         


bool ChartForegroundSet(const bool value,const long chart_ID=0)
{
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
   {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
   }//if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
//--- successful execution
   return(true);
}//End bool ChartForegroundSet(const bool value,const long chart_ID=0)
//+--------------------------------------------------------------------+
//| End of Paul's text display module to replace Comment()             |
//+--------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//----


   //Missing indi check
   /*
   if (!indiExists( "IndiName" ))
   {
      Alert("");
      Alert("Download the indi from the thread or from http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=15&t=79&p=803#p803");
      Alert("The required indicator " + "IndiName" + " does not exist on your platform. I am removing myself from your chart.");
      RemoveExpert = true;
      ExpertRemove();
      return(0);
   }//if (! indiExists( "IndiName" ))
   */
  
   
//~ Set up the pips factor. tp and sl etc.
//~ The EA uses doubles and assume the value of the integer user inputs. This: 
//~    1) minimises the danger of the inputs becoming corrupted by restarts; 
//~    2) the integer inputs cannot be divided by factor - doing so results in zero.

   factor=GetPipFactor(Symbol());
   StopLoss=StopLossPips;
   TakeProfit=TakeProfitPips;
   BreakEvenPips=BreakEvenTargetPips;
   BreakEvenProfit = BreakEvenTargetProfit;
   JumpingStopPips = JumpingStopTargetPips;
   TrailingStopPips= TrailingStopTargetPips;
   HiddenPips=PipsHiddenFromCriminal;

   while(IsConnected()==false)
   {
      Comment("Waiting for MT4 connection...");
      Comment("");

      Sleep(1000);
   }//while (IsConnected()==false)


   //Lot size and part-close idiot check for the cretins. Code provided by phil_trade. Many thanks, Philippe.
   //adjust Min_lot
   if (CloseEnough(RiskPercent, 0) )
      if(Lot<MarketInfo(Symbol(),MODE_MINLOT))
      {
         Alert(Symbol()+" Lot was adjusted to Minlot = "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),Digits));
         Lot=MarketInfo(Symbol(),MODE_MINLOT);
      }//if (Lot < MarketInfo(Symbol(), MODE_MINLOT)) 
/*
   //check Partial close parameters
   if (PartCloseEnabled == true)
   {
      if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
      {
         Alert(Symbol()+" PartCloseEnabled is disabled because Lot < Close_Lots + Preserve_Lots or Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots !");
         PartCloseEnabled = false;
      }//if (Lot < Close_Lots + Preserve_Lots || Lot < MarketInfo(Symbol(), MODE_MINLOT) + Close_Lots )
   }//if (PartCloseEnabled == true)
   */

   //Jumping/trailing stops need breakeven set before they work properly
   if ((JumpingStop || TrailingStop) && !BreakEven) 
   {
      BreakEven = true;
      if (JumpingStop) BreakEvenPips = JumpingStopPips;
      if (TrailingStop) BreakEvenPips = TrailingStopPips;
   }//if (JumpingStop || TrailingStop) 
   
   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)
   
   //Reset CriminIsECN if crim is IBFX and the punter does not know or, like me, keeps on forgetting
   string name= TerminalCompany();
   int ispart = StringFind(name,"IBFX",0);
   if(ispart<0) ispart=StringFind(name,"Interbank FX",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;
   ispart=StringFind(name,"Global Prime",0);
   if(ispart>-1) IsGlobalPrimeOrECNCriminal=true;

   //Set up the trading hours
   tradingHoursDisplay=tradingHours;//For display
   initTradingHours();//Sets up the trading hours array

   
   if(TradeComment=="") TradeComment=" ";
   OldBars=Bars;
   TicketNo=-1;
   ReadIndicatorValues();//For initial display in case user has turned of constant re-display
   GetSwap(Symbol());//This will need editing/removing in a multi-pair ea.
   TradeDirectionBySwap();
   TooClose();
   CountOpenTrades();
   OldOpenTrades=OpenTrades;
   TradeTimeOk=CheckTradingTimes();
   
   //The apread global variable
   if (!IsTesting() )
   {
      SpreadGvName=Symbol()+" average spread";
      AverageSpread=GlobalVariableGet(SpreadGvName);//If no gv, then the value will be left at zero.
   }//if (!IsTesting() )
   
   //Chart display
   if (DisplayAsText)
      if (KeepTextOnTop)
         ChartForegroundSet(false,0);// change chart to background
   
   //Ensure that an ea depending on Close[1] for its values does not immediately fire a trade.
   if (!EveryTickMode) OldBarsTime = iTime(Symbol(), TradingTimeFrame, 0);


   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

   //Time frame display
   TradingTimeFrameDisplay = GetTimeFrameDisplay(TradingTimeFrame);
   HtfHgiTimeFrameDisplay1 = GetTimeFrameDisplay(HigherTimeFrame1);
   HtfHgiTimeFrameDisplay2 = GetTimeFrameDisplay(HigherTimeFrame2);
   HtfHgiTimeFrameDisplay3 = GetTimeFrameDisplay(HigherTimeFrame3);
  
   DisplayUserFeedback();


//Call sq's show trades indi
//iCustom(NULL, 0, "SQ_showTrades",Magic, 0,0);


//----
   return(0);
} 
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//----
   Comment("");
   removeAllObjects();

//----
   return;
}

string GetTimeFrameDisplay(int tf)
{

   if (tf == 0)
      tf = Period();
      
   
   if (tf == PERIOD_M1)
      return "M1";
      
   if (tf == PERIOD_M5)
      return "M5";
      
   if (tf == PERIOD_M15)
      return "M15";
      
   if (tf == PERIOD_M30)
      return "M30";
      
   if (tf == PERIOD_H1)
      return "H1";
      
   if (tf == PERIOD_H4)
      return "H4";
      
   if (tf == PERIOD_D1)
      return "D1";
      
   if (tf == PERIOD_W1)
      return "W1";
      
   if (tf == PERIOD_MN1)
      return "Monthly";
      
   return("No recognisable time frame selected");

}//string GetTimeFrameDisplay()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
{

   double slippage=MaxSlippagePips*MathPow(10,Digits)/factor;
   int ticket = -1;


   color col=Red;
   if(type==OP_BUY || type==OP_BUYSTOP || type == OP_BUYLIMIT) col=Green;

   datetime expiry=0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

   //RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.
      
      RefreshRates();
      if(type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if(type == OP_SELL) price = MarketInfo(symbol, MODE_BID);

      
      if(!IsGlobalPrimeOrECNCriminal)
         ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage criminal
      if(IsGlobalPrimeOrECNCriminal)
      {
         ticket=OrderSend(symbol,type,lotsize,price,slippage,0,0,comment,MagicNumber,expiry,col);
         if(ticket>-1)
         {
            ModifyOrderTpSl(ticket,stop,take);
         }//if (ticket > 0)}
      }//if (IsGlobalPrimeOrECNCriminal)

      if(ticket>-1) break;//Exit the trade send loop
      if(cc == RetryCount - 1) return(false);

      //Error trapping for both
      if(ticket<0)
        {
         string stype;
         if(type == OP_BUY) stype = "OP_BUY";
         if(type == OP_SELL) stype = "OP_SELL";
         if(type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if(type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if(type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if(type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   TicketNo=ticket;
   //Make sure the trade has appeared in the platform's history to avoid duplicate trades.
   //My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromCriminal=false;
   while(!TradeReturnedFromCriminal)
     {
      TradeReturnedFromCriminal=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromCriminal)
        {
         Alert(Symbol()," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromCriminal)
     }//while (!TradeReturnedFromCriminal)

   //Got this far, so trade send succeeded
   return(true);

}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrderTpSl(int ticket, double stop, double take)
{
   //Modifies an order already sent if the crim is ECN.

   if (CloseEnough(stop, 0) && CloseEnough(take, 0) ) return; //nothing to do

   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return;//Trade does not exist, so no mod needed
   
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice() && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" ModifyOrder()", " take profit < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice()  && !CloseEnough(stop, 0) ) 
   {
      stop = 0;
      ReportError(" ModifyOrder()", " stop loss < market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   string Reason;
   //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for (int cc = 0; cc < RetryCount; cc++)
   {
      for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
        if (!CloseEnough(take, 0) && !CloseEnough(stop, 0) )
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, take, OrderExpiration(), clrNONE, __FUNCTION__, tpsl)) return;
        }//if (take > 0 && stop > 0)
   
        if (!CloseEnough(take, 0) && CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm)) return;
        }//if (take == 0 && stop != 0)

        if (CloseEnough(take, 0) && !CloseEnough(stop, 0))
        {
           while(IsTradeContextBusy()) Sleep(100);
           if (ModifyOrder(ticket, OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm)) return;
        }//if (take == 0 && stop != 0)
   }//for (int cc = 0; cc < RetryCount; cc++)
   
   
   
}//void ModifyOrderTpSl(int ticket, double tp, double sl)

//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt =0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;
   int c = 0;

   while(!exit_loop) 
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(c=0; c<total; c++) 
        {
         if(BetterOrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true) 
           {
            if(OrderTicket()==ticket) 
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3) 
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++) 
           {
            if(BetterOrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true) 
              {
               if(OrderTicket()==ticket) 
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>O_R_Setting_max_retries) 
        {
         exit_loop=true;
        }
      if(!(success || exit_loop)) 
        {
         Print("Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0) 
     {
      bool s = BetterOrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success) 
     {
      Print("Never found #"+ticket+" in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time, double max_time)
{
   if (IsTesting()) 
   {
      return;   // return immediately if backtesting.
   }

   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t = MathMin(t,max_time);
   int ms = t*1000;
   if (ms < 10) {
      ms=10;
   }//if (ms < 10) {
   
   Sleep(ms);
}//End void O_R_Sleep(double mean_time, double max_time)

////////////////////////////////////////////////////////////////////////////////////////

bool IsTradingAllowed()
{
   //Returns false if any of the filters should cancel trading, else returns true to allow trading
   
      
   //Maximum spread
   if (!IsTesting() )
   {
      double spread = (Ask - Bid) * factor;
      if (spread > AverageSpread * MultiplierToDetectStopHunt) return(false);
   }//if (!IsTesting() )
   
    
   //An individual currency can only be traded twice, so check for this
   CanTradeThisPair = true;
   if (OnlyTradeCurrencyTwice && OpenTrades == 0)
   {
      IsThisPairTradable();      
   }//if (OnlyTradeCurrencyTwice)
   if (!CanTradeThisPair) return(false);
   
   //Swap filter
   if (OpenTrades == 0) TradeDirectionBySwap();
   
   //Order close time safety feature
   if (TooClose()) return(false);

   return(true);


}//End bool IsTradingAllowed()

////////////////////////////////////////////////////////////////////////////////////////
//Balance/swap filters module
void TradeDirectionBySwap()
{

   //Sets TradeLong & TradeShort according to the positive/negative swap it attracts

   //Swap is read in init() and start()


   if (CadPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "CAD" || StringSubstrOld(Symbol(), 0, 3) == "cad" || StringSubstrOld(Symbol(), 3, 3) == "CAD" || StringSubstrOld(Symbol(), 3, 3) == "cad" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (CadPairsPositiveOnly)
   
   if (AudPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "AUD" || StringSubstrOld(Symbol(), 0, 3) == "aud" || StringSubstrOld(Symbol(), 3, 3) == "AUD" || StringSubstrOld(Symbol(), 3, 3) == "aud" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   
   if (NzdPairsPositiveOnly)
   {
      if (StringSubstrOld(Symbol(), 0, 3) == "NZD" || StringSubstrOld(Symbol(), 0, 3) == "nzd" || StringSubstrOld(Symbol(), 3, 3) == "NZD" || StringSubstrOld(Symbol(), 3, 3) == "nzd" )      
      {
         if (LongSwap > 0) TradeLong = true;
         else TradeLong = false;
         if (ShortSwap > 0) TradeShort = true;
         else TradeShort = false;         
      }//if (StringSubstrOld()      
   }//if (AudPairsPositiveOnly)
   
   //OnlyTradePositiveSwap filter
   if (OnlyTradePositiveSwap)
   {
      if (LongSwap < 0) TradeLong = false;
      if (ShortSwap < 0) TradeShort = false;      
   }//if (OnlyTradePositiveSwap)
   

}//void TradeDirectionBySwap()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsThisPairTradable()
{
   //Checks to see if either of the currencies in the pair is already being traded twice.
   //If not, then return true to show that the pair can be traded, else return false
   
   string c1 = StringSubstrOld(Symbol(), 0, 3);//First currency in the pair
   string c2 = StringSubstrOld(Symbol(), 3, 3);//Second currency in the pair
   int c1open = 0, c2open = 0;
   CanTradeThisPair = true;
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      int index = StringFind(OrderSymbol(), c1);
      if (index > -1)
      {
         c1open++;         
      }//if (index > -1)
   
      index = StringFind(OrderSymbol(), c2);
      if (index > -1)
      {
         c2open++;         
      }//if (index > -1)
   
      if (c1open == 1 && c2open == 1) 
      {
         CanTradeThisPair = false;
         return(false);   
      }//if (c1open == 1 && c2open == 1) 
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so ok to trade
   return(true);
   
}//End bool IsThisPairTradable()

bool BalancedPair(int type)
{

   //Only allow an individual currency to trade if it is a balanced trade
   //e.g. UJ Buy open, so only allow Sell xxxJPY.
   //The passed parameter is the proposed trade, so an existing one must balance that

   //This code courtesy of Zeljko (zkucera) who has my grateful appreciation.
   
   string BuyCcy1, SellCcy1, BuyCcy2, SellCcy2;

   if (type == OP_BUY || type == OP_BUYSTOP)
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 0, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 3, 3);
   }//if (type == OP_BUY || type == OP_BUYSTOP)
   else
   {
      BuyCcy1 = StringSubstrOld(Symbol(), 3, 3);
      SellCcy1 = StringSubstrOld(Symbol(), 0, 3);
   }//else

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS)) continue;
      if (OrderSymbol() == Symbol()) continue;
      if (OrderMagicNumber() != MagicNumber) continue;      
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
      }//if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP)
      else
      {
         BuyCcy2 = StringSubstrOld(OrderSymbol(), 3, 3);
         SellCcy2 = StringSubstrOld(OrderSymbol(), 0, 3);
      }//else
      if (BuyCcy1 == BuyCcy2 || SellCcy1 == SellCcy2) return(false);
   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)

   //Got this far, so it is ok to send the trade
   return(true);

}//End bool BalancedPair(int type)

//End Balance/swap filters module
////////////////////////////////////////////////////////////////////////////////////////
double CalculateLotSize(double price1,double price2)
{
   //Calculate the lot size by risk. Code kindly supplied by jmw1970. Nice one jmw.

   if(price1==0 || price2==0) return(Lot);//Just in case

   double FreeMargin= AccountFreeMargin();
   double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double LotStep=MarketInfo(Symbol(),MODE_LOTSTEP);

   double SLPts=MathAbs(price1-price2);
   //SLPts/=Point;//No idea why *= factor does not work here, but it doesn't
   SLPts = int(SLPts * factor * 10);//Code from Radar. Thanks Radar; much appreciated

   double Exposure=SLPts*TickValue; // Exposure based on 1 full lot

   double AllowedExposure=(FreeMargin*RiskPercent)/100;

   int TotalSteps = ((AllowedExposure / Exposure) / LotStep);
   double LotSize = TotalSteps * LotStep;

   double MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   double MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);

   if(LotSize < MinLots) LotSize = MinLots;
   if(LotSize > MaxLots) LotSize = MaxLots;
   return(LotSize);

}//double CalculateLotSize(double price1, double price1)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateStopLoss(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double stop;

   RefreshRates();
   
   double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   double spread = (Ask - Bid) * factor;

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         if (StopLoss < StopLevel) 
            if (StopLossPips > 0)
               StopLoss = StopLevel;
         stop = price - (StopLoss / factor);
         HiddenStopLoss = stop;
      }//if (!CloseEnough(StopLoss, 0) ) 

      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop - (HiddenPips / factor), Digits);
   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(StopLoss, 0) ) 
      {
         if (StopLoss < StopLevel) 
            if (StopLossPips > 0)
               StopLoss = StopLevel;
         stop = price + (StopLoss / factor);
         HiddenStopLoss = stop;         
      }//if (!CloseEnough(StopLoss, 0) ) 
      
      if (HiddenPips > 0 && stop > 0) stop = NormalizeDouble(stop + (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(stop);
   
}//End double CalculateStopLoss(int type)

double CalculateTakeProfit(int type, double price)
{
   //Returns the stop loss for use in LookForTradingOpps and InsertMissingStopLoss
   double take;

   RefreshRates();
   
   double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   double spread = (Ask - Bid) * factor;

   
   if (type == OP_BUY)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price + (TakeProfit / factor);
         HiddenTakeProfit = take;
      }//if (!CloseEnough(TakeProfit, 0) )

               
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take + (HiddenPips / factor), Digits);

   }//if (type == OP_BUY)
   
   if (type == OP_SELL)
   {
      if (!CloseEnough(TakeProfit, 0) )
      {
         if (TakeProfit < StopLevel) 
            if (TakeProfitPips > 0)   
               TakeProfit = StopLevel;
         take = price - (TakeProfit / factor);
         HiddenTakeProfit = take;         
      }//if (!CloseEnough(TakeProfit, 0) )
      
      
      if (HiddenPips > 0 && take > 0) take = NormalizeDouble(take - (HiddenPips / factor), Digits);

   }//if (type == OP_SELL)
   
   return(take);
   
}//End double CalculateTakeProfit(int type)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LookForTradingOpportunities()
{


   RefreshRates();
   double take, stop, price;
   int type;
   string stype;//For the alert
   bool SendTrade = false, result = false;

   double SendLots = Lot;
   //Check filters
   if (!IsTradingAllowed() ) return;
   
   
   /////////////////////////////////////////////////////////////////////////////////////
   
   //Trading decision.
   bool SendLong = false, SendShort = false;

   //Long trade
   
   //Specific system filters
   if (BuySignal) 
      SendLong = true;
   
   //Usual filters
   if (SendLong)
   {
      //User choice of trade direction
      if (!TradeLong) return;

      //Bob's 240 H4 ma trend filter
      if (MaPeriod > 0)
         if (MaTrend != up)
            return;

     
      //Other filters
      
      if (UseZeljko && !BalancedPair(OP_BUY) ) return;
      
      //Change of market state - explanation at the end of start()
      //if (OldAsk <= some_condition) SendLong = false;   
   }//if (SendLong)
   
   /////////////////////////////////////////////////////////////////////////////////////

   if (!SendLong)
   {
      //Short trade
      //Specific system filters
      if (SellSignal) 
         SendShort = true;
      
      if (SendShort)
      {      
         //Usual filters

         //User choice of trade direction
         if (!TradeShort) return;

         //Other filters
         
         //Bob's 240 H4 ma trend filter
         if (MaPeriod > 0)
            if (MaTrend != down)
               return;

         
         if (UseZeljko && !BalancedPair(OP_SELL) ) return;
         
         //Change of market state - explanation at the end of start()
         //if (OldBid += some_condition) SendShort = false;   
      }//if (SendShort)
      
   }//if (!SendLong)
     

////////////////////////////////////////////////////////////////////////////////////////
   
   
   //Long 
   if (SendLong)
   {
       
      type=OP_BUY;
      stype = " Buy ";
      price = Ask;//Change this to whatever the price needs to be
         
      if (!SendAlertNotTrade)
      {
         
         stop = CalculateStopLoss(OP_BUY, price);
         
         
         take = CalculateTakeProfit(OP_BUY, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop + (HiddenPips / factor), Digits) );

         
         
      }//if (!SendAlertNotTrade)
      
      SendTrade = true;
      
   }//if (SendLong)
   
   //Short
   if (SendShort)
   {
      
      type=OP_SELL;
      stype = " Sell ";
      price = Bid;//Change this to whatever the price needs to be

      if (!SendAlertNotTrade)
      {
         
         stop = CalculateStopLoss(OP_SELL, price);
         
         take = CalculateTakeProfit(OP_SELL, price);
         
         
         //Lot size calculated by risk
         if (!CloseEnough(RiskPercent, 0)) SendLots = CalculateLotSize(price, NormalizeDouble(stop - (HiddenPips / factor), Digits) );

        
      }//if (!SendAlertNotTrade)
         
      SendTrade = true;      
   
      
   }//if (SendShort)
   

   if (SendTrade)
   {
      if (!SendAlertNotTrade) 
      { 
         result = SendSingleTrade(Symbol(), type, TradeComment, SendLots, price, stop, take);
         //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so tell the
         //ea not to trade for a while, to give time for the trade receipt to return from the server.
         TimeToStartTrading = TimeCurrent() + PostTradeAttemptWaitSeconds;
         if (result) 
         {
            if (TakeSnapshots)
            {
               DisplayUserFeedback();
               TakeChartSnapshot(TicketNo, " open");
            }//if (TakeSnapshots)

            
            if (EmailTradeNotification) SendMail("Trade sent ", Symbol() + stype + "trade at " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES));
            if (AlertPush) AlertNow(WindowExpertName() + " " + Symbol() + " " + stype + " " + DoubleToStr(price, Digits) );
            bool s = BetterOrderSelect(TicketNo, SELECT_BY_TICKET, MODE_TRADES);
            CheckTpSlAreCorrect(type);
            //The latest garbage from the morons at Crapperquotes appears to occasionally break Matt's OR code, so send the
            //ea to sleep for a minute to give time for the trade receipt to return from the server.
            Sleep(60000);
         }//if (result)          
      }//if (!SendAlertNotTrade) 
      
      if (SendAlertNotTrade && !AlertSent)
      {
         Alert(WindowExpertName(), " ", Symbol(), " ", stype, "trade has triggered. ",  TimeToStr(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) );
         SendMail("Trade alert. ", Symbol() + " " + stype + " trade has triggered. " +  TimeToStr(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS ));
         if (AlertPush) AlertNow(WindowExpertName() + " " + Symbol() + " " + stype + " " + DoubleToStr(price, Digits) );         
         AlertSent=true;
       }//if (SendAlertNotTrade && !AlertSent)
   }//if (SendTrade)
   
   //Actions when trade send succeeds
   if (SendTrade && result)
   {      
      if (!SendAlertNotTrade && !CloseEnough(HiddenPips, 0) ) ReplaceMissingSlTpLines();
   }//if (result)
   
   //Actions when trade send fails
   if (SendTrade && !result)
   {
      OldBarsTime = 0;
   }//if (!result)
   
   
   

}//void LookForTradingOpportunities()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AlertNow(string sAlertMsg)
{

   if(AlertPush)
   {
      if(IsTesting()) Print("Message to Push: ",TimeToStr(Time[0],TIME_DATE|TIME_SECONDS)+" "+sAlertMsg);
      SendNotification(StringConcatenate(TimeToStr(Time[0],TIME_DATE|TIME_SECONDS)," "+sAlertMsg));
   }//if (AlertPush) 
   return;
}//End void AlertNow(string sAlertMsg) 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseOrder(int ticket)
{   
   while(IsTradeContextBusy()) Sleep(100);
   bool orderselect=BetterOrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   if (!orderselect) return(false);

   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, clrBlue);

   //Actions when trade send succeeds
   if (result)
   {
      if (TakeSnapshots)
      {
         DisplayUserFeedback();
         TakeChartSnapshot(TicketNo, " close");
      }//if (TakeSnapshots)
      
      return(true);
   }//if (result)
   
   //Actions when trade send fails
   if (!result)
   {
      ReportError(" CloseOrder()", ocm);
      return(false);
   }//if (!result)
   
   return(0);
}//End bool CloseOrder(ticket)

////////////////////////////////////////////////////////////////////////////////////////
//Indicator module

void CheckForSpreadWidening()
{
   if (CloseEnough(AverageSpread, 0)) return;
   //Detect a dramatic widening of the spread and pause the ea until this passes
   double TargetSpread = AverageSpread * MultiplierToDetectStopHunt;
   double spread = (Ask - Bid) * factor;
   
   if (spread >= TargetSpread)
   {
      if (OpenTrades == 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT");
      if (OpenTrades > 0) Comment(Gap + "PAUSED DURING A MASSIVE SPREAD EVENT. STILL MONITORING TRADES.");
      while (spread >= TargetSpread)
      {
         RefreshRates();
         spread = (Ask - Bid) * factor;
         
         CountOpenTrades();
         //Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
         if (OldOpenTrades != OpenTrades)
         {
            if (IsClosedTradeRogue() )
            {
               RobotSuspended = true;
               return;
            }//if (IsClosedTradeRogue() )      
         }//if (OldOpenTrades != OpenTrades)
         if (ForceTradeClosure) return;//Emergency measure to force a retry at the next tick
         
         OldOpenTrades = OpenTrades;
         
         Sleep(1000);

      }//while (spread >= TargetSpread)      
   }//if (spread >= TargetSpread)
}//End void CheckForSpreadWidening()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateDailyResult()
{
   //Calculate the no of winners and losers from today's trading. These are held in the history tab.

   LossTrades = 0;
   WinTrades = 0;
   OverallProfit = 0;
   
   
   for (int cc = 0; cc <= OrdersHistoryTotal(); cc++)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() < iTime(Symbol(), PERIOD_D1, 0) ) continue;
      
      OverallProfit+= (OrderProfit() + OrderSwap() + OrderCommission() );
      if (OrderProfit() > 0) WinTrades++;
      if (OrderProfit() < 0) LossTrades++;
   }//for (int cc = 0; cc <= tot -1; cc++)
   
   

}//End void CalculateDailyResult()

//+------------------------------------------------------------------+
//| GetSlope()                                                       |
//+------------------------------------------------------------------+
void GetAverageSpread()
{

//   ************************* added for OBJ_LABEL
   DisplayCount = 1;
   removeAllObjects();
//   *************************

   static double SpreadTotal=0;
   AverageSpread=0;

   //Add spread to total and keep track of the ticks
   double Spread=(Ask-Bid)*factor;
   SpreadTotal+=Spread;
   CountedTicks++;

   //All ticks counted?
   if(CountedTicks>=TicksToCount)
   {
      AverageSpread=NormalizeDouble(SpreadTotal/TicksToCount,1);
      //Save the average for restarts.
      GlobalVariableSet(SpreadGvName,AverageSpread);
      RunInSpreadDetectionMode=false;
   }//if (CountedTicks >= TicksToCount)


}//void GetAverageSpread()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMa(string symbol,int tf,int period,int mashift,int method,int ap,int shift)
{
   return(iMA(symbol, tf, period, mashift, method, ap, shift) );
}//End double GetMa(int tf, int period, int mashift, int method, int ap, int shift)

double GetAtr(string symbol, int tf, int period, int shift)
{
   //Returns the value of atr
   
   return(iATR(symbol, tf, period, shift) );   

}//End double GetAtr()

double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1,
                   string d2, string d3, int buffer, int shift)
{

   return(iCustom(symbol, tf, "3 Level", p1, p2, p3, d1, d2, d3, buffer, shift) );

}//double GetSemaphor(string symbol, int tf, double p1, double p2, double p3, string d1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReadIndicatorValues()
{

   int cc = 0;
   
   //Declare a shift for use with indicators.
   int shift = 0;
   if (!EveryTickMode)
   {
      shift = 1;
   }//if (!EveryTickMode)

   
   //Declare a datetime variable to force cca reading only at the open of a new candle.
   static datetime OldCcaReadTime = 0;
   //Accommodate every tick mode
   if (EveryTickMode)
      OldCcaReadTime = 0;
   
   double val = 0;
   
   //Allow easy experimentation.
   //shift = 2;
   
   /////////////////////////////////////////////////////////////////////////////////////
   //Read indicators for the system being coded and put them together into a trade signal
   if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )
   {
      OldCcaReadTime = iTime(Symbol(), TradingTimeFrame, 0);
    
      ///////////////////////////////////////
      //Indi reading code goes here
      
      //The HGI library functionality was added by tomele. Many thanks Thomas.
      SIGNAL signal = 0;
      SLOPE  slope  = 0;

      //Trading time frame HGI
      signal = getHGISignal(Symbol(), TradingTimeFrame, shift);//This library function looks for arrows.
      slope  = getHGISlope (Symbol(), TradingTimeFrame, shift);//This library function looks for wavy lines.

      TradeHgiStatus = hginosignal;
      
      if (signal==TRENDUP && TradeTrendArrows)
      {
         TradeHgiStatus = hgiup;
      }
      else 
      if (signal==TRENDDN && TradeTrendArrows)
      {
         TradeHgiStatus = hgidown;
      }
      else 
      if (slope==TRENDBELOW && TradeBlueWavyLines)
      {
         TradeHgiStatus = hgiup;
      }
      else 
      if (slope==TRENDABOVE && TradeBlueWavyLines)
      {
         TradeHgiStatus = hgidown;
      }
      else
      if (slope==RANGEABOVE || slope==RANGEBELOW)
      {
         TradeHgiStatus = hgiranging;
      }
      
      /*else
      if (signal==RADUP)
      {
         if (RadTradingAllowed)
         TradeHgiStatus = hgiuparrowtradable;
      }
      else 
      if (signal==RADDN)
      {
         if (RadTradingAllowed)
            TradeHgiStatus = hgiuparrowtradable;
      */
 
      //HTF 1
      static datetime OldHtfBarTime=0;//Read the HTF HGI once a minute
      if (OldHtfBarTime != iTime(Symbol(), PERIOD_M1, 0))
      {
         OldHtfBarTime = iTime(Symbol(), PERIOD_M1, 0);
         HtfHgiStatus1 = hginosignal;
         signal = 0;
         slope  = 0;
         cc = 0;
         BuysAligned = 0; SellsAligned = 0;
         
         while (HtfHgiStatus1 == hginosignal)
         {
         
            signal = getHGISignal(Symbol(), HigherTimeFrame1, cc);//This library function looks for arrows.
            slope  = getHGISlope (Symbol(), HigherTimeFrame1, cc);//This library function looks for wavy lines.

            if (signal==TRENDUP)
            {
               HtfHgiStatus1 = hgiup;
               BuysAligned++;
            }
            else 
            if (signal==TRENDDN)
            {
               HtfHgiStatus1 = hgidown;
               SellsAligned++;
            }
            else 
            if (slope==TRENDBELOW)
            {
               HtfHgiStatus1 = hgiup;
               BuysAligned++;
            }
            else 
            if (slope==TRENDABOVE)
            {
               HtfHgiStatus1 = hgidown;
               SellsAligned++;
            }
            else
            if (slope==RANGEABOVE || slope==RANGEBELOW)
            {
               HtfHgiStatus1 = hgiranging;
            }
            
            /*else
            if (signal==RADUP)
            {
               if (RadTradingAllowed)
               HtfHgiStatus1 = hgiuparrowtradable;
            }
            else 
            if (signal==RADDN)
            {
               if (RadTradingAllowed)
                  HtfHgiStatus1 = hgiuparrowtradable;
            */
                   
            //Break the loop if a signal has been found
            if (HtfHgiStatus1 != hginosignal)
               break;
            cc++;
            if (cc >= iBars(Symbol(), HigherTimeFrame1) )
               break;//Just in case
         }//while (HtfHgiStatus1 == hginosignal)
         
         //HTF 2
         HtfHgiStatus2 = hginosignal;
         signal = 0;
         slope  = 0;
         cc = 0;
         while (HtfHgiStatus2 == hginosignal)
         {
         
            signal = getHGISignal(Symbol(), HigherTimeFrame2, cc);//This library function looks for arrows.
            slope  = getHGISlope (Symbol(), HigherTimeFrame2, cc);//This library function looks for wavy lines.

            if (signal==TRENDUP)
            {
               HtfHgiStatus2 = hgiup;
               BuysAligned++;
            }
            else 
            if (signal==TRENDDN)
            {
               HtfHgiStatus2 = hgidown;
               SellsAligned++;
            }
            else 
            if (slope==TRENDBELOW)
            {
               HtfHgiStatus2 = hgiup;
               BuysAligned++;
            }
            else 
            if (slope==TRENDABOVE)
            {
               HtfHgiStatus2 = hgidown;
               SellsAligned++;
            }
            else
            if (slope==RANGEABOVE || slope==RANGEBELOW)
            {
               HtfHgiStatus2 = hgiranging;
            }
            
            /*else
            if (signal==RADUP)
            {
               if (RadTradingAllowed)
               HtfHgiStatus2 = hgiuparrowtradable;
            }
            else 
            if (signal==RADDN)
            {
               if (RadTradingAllowed)
                  HtfHgiStatus2 = hgiuparrowtradable;
            */
                   
            //Break the loop if a signal has been found
            if (HtfHgiStatus2 != hginosignal)
               break;
            cc++;
            if (cc >= iBars(Symbol(), HigherTimeFrame2) )
               break;//Just in case
         }//while (HtfHgiStatus2 == hginosignal)
         
     
         //HTF 3
         HtfHgiStatus3 = hginosignal;
         signal = 0;
         slope  = 0;
         cc = 0;
         while (HtfHgiStatus3 == hginosignal)
         {
         
            signal = getHGISignal(Symbol(), HigherTimeFrame3, cc);//This library function looks for arrows.
            slope  = getHGISlope (Symbol(), HigherTimeFrame3, cc);//This library function looks for wavy lines.

            if (signal==TRENDUP)
            {
               HtfHgiStatus3 = hgiup;
               BuysAligned++;
            }
            else 
            if (signal==TRENDDN)
            {
               HtfHgiStatus3 = hgidown;
               SellsAligned++;
            }
            else 
            if (slope==TRENDBELOW)
            {
               HtfHgiStatus3 = hgiup;
               BuysAligned++;
            }
            else 
            if (slope==TRENDABOVE)
            {
               HtfHgiStatus3 = hgidown;
               SellsAligned++;
            }
            else
            if (slope==RANGEABOVE || slope==RANGEBELOW)
            {
               HtfHgiStatus3 = hgiranging;
            }
            
            /*else
            if (signal==RADUP)
            {
               if (RadTradingAllowed)
               HtfHgiStatus3 = hgiuparrowtradable;
            }
            else 
            if (signal==RADDN)
            {
               if (RadTradingAllowed)
                  HtfHgiStatus3 = hgiuparrowtradable;
            */
                   
            //Break the loop if a signal has been found
            if (HtfHgiStatus3 != hginosignal)
               break;
            cc++;
            if (cc >= iBars(Symbol(), HigherTimeFrame3) )
               break;//Just in case
         }//while (HtfHgiStatus3 == hginosignal)
         
      }//if (OldHtfBarTime != iTime(Symbol(), PERIOD_M1, 0))
      
      //Combined HTF trading status
      HgiTradingStatus = untradable;
      //Long
      if (BuysAligned >= HtfMinimumAlignment)
         HgiTradingStatus = tradablelong;
               
      //Short
      if (SellsAligned >= HtfMinimumAlignment)
         HgiTradingStatus = tradableshort;
               
               
           
     
      //MA
      if(MaPeriod>0)
      {
         static datetime OldM1BarTime;
         if(OldM1BarTime!=iTime(NULL,PERIOD_M1,0))
         {
            OldM1BarTime=iTime(NULL,PERIOD_M1,0);
            //~ TradeLong = false;
            //~ TradeShort = false;
            MaVal=GetMa(Symbol(),MaTF,MaPeriod,MaShift,MaMethod,MaAppliedPrice,0);
            if(Bid>MaVal)
            {
               MaTrend=up;
            }//if (Bid > MaVal) 
   
            if(Bid<MaVal)
            {
               MaTrend=down;
            }//if (Bid < MaVal) 
   
         }//if (OldM1BarTime != iTime(NULL, PERIOD_M1, 0))
      }//if (MaPeriod > 0)
   
      ///////////////////////////////////////
      //Anything else?
      
      
      ///////////////////////////////////////
      
      //Do we have a trade signal
      BuySignal = false;
      SellSignal = false;
      
      //Code to compare all the indi values and generate a signal if they all pass
      if (TradeHgiStatus == hgiup)
         if (HgiTradingStatus == tradablelong)
            BuySignal = true;
      
      if (TradeHgiStatus == hgidown)
         if (HgiTradingStatus == tradableshort)
            SellSignal = true;
      
      //Close trades on an opposite direction signal
      BuyCloseSignal = false;
      SellCloseSignal = false;
      
      if (TradeHgiStatus == hgiup)
         if (HgiCloseOnOppositeSignal)
            SellCloseSignal = true;
      
      if (TradeHgiStatus == hgidown)
         if (HgiCloseOnOppositeSignal)
            BuyCloseSignal = true;
      
      //Yellow wavy on the trade timeframe
      if (HgiCloseOnYellowWavy)
         if (TradeHgiStatus == hgiranging)
         {
            BuyCloseSignal = true;
            SellCloseSignal = true;
         }//if (TradeHgiStatus == hgiranging)
         
      
   }//if (OldCcaReadTime != iTime(Symbol(), TradingTimeFrame, 0) )   
         
   

}//void ReadIndicatorValues()
//End Indicator module
////////////////////////////////////////////////////////////////////////////////////////

bool LookForTradeClosure(int ticket)
{
   //Close the trade if the close conditions are met.
   //Called from within CountOpenTrades(). Returns true if a close is needed and succeeds, so that COT can increment cc,
   //else returns false
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET) ) return(true);
   if (BetterOrderSelect(ticket, SELECT_BY_TICKET) && OrderCloseTime() > 0) return(true);
   
   bool CloseThisTrade = false;
   
   string LineName = TpPrefix + DoubleToStr(ticket, 0);
   //Work with the lines on the chart that represent the hidden tp/sl
   double take = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(take, 0) ) take = OrderTakeProfit();
   LineName = SlPrefix + DoubleToStr(ticket, 0);
   double stop = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(stop, 0) ) stop = OrderStopLoss();
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   {
      //TP
      if (Bid >= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (Bid <= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;

      
      //Close trade on opposite direction signal
      if (BuyCloseSignal)
         CloseThisTrade = true;

      
   }//if (OrderType() == OP_BUY)
   
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   {
      //TP
      if (Bid <= take && !CloseEnough(take, 0) && !CloseEnough(take, OrderTakeProfit()) ) CloseThisTrade = true;
      //SL
      if (Bid >= stop && !CloseEnough(stop, 0)  && !CloseEnough(stop, OrderStopLoss())) CloseThisTrade = true;


      //Close trade on opposite direction signal
      if (SellCloseSignal)
         CloseThisTrade = true;

      
      
      
   }//if (OrderType() == OP_SELL)
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////
   if (CloseThisTrade)
   {
      bool result = false;
      
      if (OrderType() < 2)//Market orders
         result = CloseOrder(ticket);
      else
         result = OrderDelete(ticket, clrNONE);
            
      //Actions when trade close succeeds
      if (result)
      {
         DeletePendingPriceLines();
         TicketNo = -1;//TicketNo is the most recently trade opened, so this might need editing in a multi-trade EA
         OpenTrades--;//Rather than OpenTrades = 0 to cater for multi-trade EA's
         return(true);//Makes CountOpenTrades increment cc to avoid missing out ccounting a trade
      }//if (result)
   
      //Actions when trade close fails
      if (!result)
      {
         return(false);//Do not increment cc
      }//if (!result)
   }//if (CloseThisTrade)
   
   //Got this far, so no trade closure
   return(false);//Do not increment cc
   
}//End bool LookForTradeClosure()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllTrades(int type)
{

   ForceTradeClosure= false;
   
   if (OrdersTotal() == 0) return;
   
   bool result = false;
   for (int pass = 0; pass <= 1; pass++)
   {
      if (OrdersTotal() == 0 || OpenTrades == 0)
         break;
      for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
      {
         if (!BetterOrderSelect(FifoTicket[cc], SELECT_BY_TICKET, MODE_TRADES) ) continue;
         if (OrderMagicNumber() != MagicNumber) continue;
         if (OrderSymbol() != Symbol() ) continue;
         if (OrderType() != type) 
            if (type != AllTrades)
               continue;
         
         while(IsTradeContextBusy()) Sleep(100);
         if (OrderType() < 2)
         {
            result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1000, CLR_NONE);
            if (result) 
            {
               cc++;
               OpenTrades--;
            }//(result) 
            
            if (!result) ForceTradeClosure= true;
         }//if (OrderType() < 2)
         
         if (pass == 1)
            if (OrderType() > 1) 
            {
               result = OrderDelete(OrderTicket(), clrNONE);
               if (result) 
               {
                  cc++;
                  OpenTrades--;
               }//(result) 
            if (!result) ForceTradeClosure= true;
            }//if (OrderType() > 1) 
            
      }//for (int cc = ArraySize(FifoTicket) - 1; cc >= 0; cc--)
   }//for (int pass = 0; pass <= 1; pass++)
   
   //If full closure succeeded, then allow new trading
   if (!ForceTradeClosure) 
   {
      OpenTrades = 0;
      BuyOpen = false;
      SellOpen = false;
   }//if (!ForceTradeClosure) 


}//End void CloseAllTradesFifo()


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTradingTimes() 
{

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    int time = TimeHour( TimeLocal() ) * 60 + TimeMinute( TimeLocal() );
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		i++;		
		if ( i == ArraySize( tradeHours ) ) break;
	}
	if ( i % 2 == 1 ) return ( true );
	return ( false );
}//End bool CheckTradingTimes2() 
//+------------------------------------------------------------------+
//| Initialize Trading Hours Array                                   |
//+------------------------------------------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayResize( tradeHours, 0 );
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( StringSubstrOld( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstrOld( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) 
	{

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = StringSubstrOld( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstrOld ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstrOld( part, 1 );
		double time = StrToDouble( part );
		int hour = MathFloor( time );
		int minutes = MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstrOld( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}//while (i != -1) 

	return ( true );
}//End bool initTradingHours() 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountOpenTrades()
{
   //Not all these will be needed. Which ones are depends on the individual EA.
   //Market Buy trades
   BuyOpen=false;
   MarketBuysCount=0;
   LatestBuyPrice=0; EarliestBuyPrice=0; HighestBuyPrice=0; LowestBuyPrice=million;
   BuyTicketNo=-1; HighestBuyTicketNo=-1; LowestBuyTicketNo=-1; LatestBuyTicketNo=-1; EarliestBuyTicketNo=-1;
   BuyPipsUpl=0;
   BuyCashUpl=0;
   LatestBuyTradeTime=0;
   EarliestBuyTradeTime=TimeCurrent();
   
   //Market Sell trades
   SellOpen=false;
   MarketSellsCount=0;
   LatestSellPrice=0; EarliestSellPrice=0; HighestSellPrice=0; LowestSellPrice=million;
   SellTicketNo=-1; HighestSellTicketNo=-1; LowestSellTicketNo=-1; LatestSellTicketNo=-1; EarliestSellTicketNo=-1;;
   SellPipsUpl=0;
   SellCashUpl=0;
   LatestSellTradeTime=0;
   EarliestSellTradeTime=TimeCurrent();
   
   //BuyStop trades
   BuyStopOpen=false;
   BuyStopsCount=0;
   LatestBuyStopPrice=0; EarliestBuyStopPrice=0; HighestBuyStopPrice=0; LowestBuyStopPrice=million;
   BuyStopTicketNo=-1; HighestBuyStopTicketNo=-1; LowestBuyStopTicketNo=-1; LatestBuyStopTicketNo=-1; EarliestBuyStopTicketNo=-1;;
   LatestBuyStopTradeTime=0;
   EarliestBuyStopTradeTime=TimeCurrent();
   
   //BuyLimit trades
   BuyLimitOpen=false;
   BuyLimitsCount=0;
   LatestBuyLimitPrice=0; EarliestBuyLimitPrice=0; HighestBuyLimitPrice=0; LowestBuyLimitPrice=million;
   BuyLimitTicketNo=-1; HighestBuyLimitTicketNo=-1; LowestBuyLimitTicketNo=-1; LatestBuyLimitTicketNo=-1; EarliestBuyLimitTicketNo=-1;;
   LatestBuyLimitTradeTime=0;
   EarliestBuyLimitTradeTime=TimeCurrent();
   
   /////SellStop trades
   SellStopOpen=false;
   SellStopsCount=0;
   LatestSellStopPrice=0; EarliestSellStopPrice=0; HighestSellStopPrice=0; LowestSellStopPrice=million;
   SellStopTicketNo=-1; HighestSellStopTicketNo=-1; LowestSellStopTicketNo=-1; LatestSellStopTicketNo=-1; EarliestSellStopTicketNo=-1;;
   LatestSellStopTradeTime=0;
   EarliestSellStopTradeTime=TimeCurrent();
   
   //SellLimit trades
   SellLimitOpen=false;
   SellLimitsCount=0;
   LatestSellLimitPrice=0; EarliestSellLimitPrice=0; HighestSellLimitPrice=0; LowestSellLimitPrice=million;
   SellLimitTicketNo=-1; HighestSellLimitTicketNo=-1; LowestSellLimitTicketNo=-1; LatestSellLimitTicketNo=-1; EarliestSellLimitTicketNo=-1;;
   LatestSellLimitTradeTime=0;
   EarliestSellLimitTradeTime=TimeCurrent();
   
   //Not related to specific order types
   MarketTradesTotal = 0;
   TicketNo=-1;OpenTrades=0;
   LatestTradeTime=0; EarliestTradeTime=TimeCurrent();//More specific times are in each individual section
   LatestTradeTicketNo=-1; EarliestTradeTicketNo=-1;
   PipsUpl=0;//For keeping track of the pips PipsUpl of multi-trade/hedged positions
   CashUpl=0;//For keeping track of the cash PipsUpl of multi-trade/hedged positions

   
   //FIFO ticket resize
   ArrayResize(FifoTicket, 0);
   
      
   
   int type;//Saves the OrderType() for consulatation later in the function
   
   
   if (OrdersTotal() == 0) return;
   
   //Iterating backwards through the orders list caters more easily for closed trades than iterating forwards
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      bool TradeWasClosed = false;//See 'check for possible trade closure'

      //Ensure the trade is still open
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_TRADES) ) continue;
      //Ensure the EA 'owns' this trade
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderCloseTime() > 0) continue; 
      
      //The time of the most recent trade
      if (OrderOpenTime() > LatestTradeTime)
      {
         LatestTradeTime = OrderOpenTime();
         LatestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() > LatestTradeTime)
      
      //The time of the earliest trade
      if (OrderOpenTime() < EarliestTradeTime)
      {
         EarliestTradeTime = OrderOpenTime();
         EarliestTradeTicketNo = OrderTicket();
      }//if (OrderOpenTime() < EarliestTradeTime)
      
      //All conditions passed, so carry on
      type = OrderType();//Store the order type
      
      if (!CloseEnough(OrderTakeProfit(), 0) )
         TpSet = true;
      if (!CloseEnough(OrderStopLoss(), 0) )
         SlSet = true;

      OpenTrades++;
      //Store the latest trade sent. Most of my EA's only need this final ticket number as either they are single trade
      //bots or the last trade in the sequence is the important one. Adapt this code for your own use.
      if (TicketNo  == -1) TicketNo = OrderTicket();
      
      //Store ticket numbers for FIFO
      ArrayResize(FifoTicket, OpenTrades + 1);
      FifoTicket[OpenTrades] = OrderTicket();
      
      
      //The next line of code calculates the pips upl of an open trade. As yet, I have done nothing with it.
      //something = CalculateTradeProfitInPips()
      
      double pips = 0;
      
      //Buile up the position picture of market trades
      if (OrderType() < 2)
      {
         CashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
         MarketTradesTotal++;
         pips = CalculateTradeProfitInPips(OrderType());
         PipsUpl+= pips;
         
         //Buys
         if (OrderType() == OP_BUY)
         {
            BuyOpen = true;
            BuyTicketNo = OrderTicket();
            MarketBuysCount++;
            BuyPipsUpl+= pips;
            BuyCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyTradeTime)
            {
               LatestBuyTradeTime = OrderOpenTime();
               LatestBuyPrice = OrderOpenPrice();
               LatestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyTradeTime)
            {
               EarliestBuyTradeTime = OrderOpenTime();
               EarliestBuyPrice = OrderOpenPrice();
               EarliestBuyTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyPrice)
            {
               HighestBuyPrice = OrderOpenPrice();
               HighestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyPrice)
            {
               LowestBuyPrice = OrderOpenPrice();
               LowestBuyTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyPrice)
              
         }//if (OrderType() == OP_BUY)
         
         //Sells
         if (OrderType() == OP_SELL)
         {
            SellOpen = true;
            SellTicketNo = OrderTicket();
            MarketSellsCount++;
            SellPipsUpl+= pips;
            SellCashUpl+= (OrderProfit() + OrderSwap() + OrderCommission()); 
            
            //Latest trade
            if (OrderOpenTime() > LatestSellTradeTime)
            {
               LatestSellTradeTime = OrderOpenTime();
               LatestSellPrice = OrderOpenPrice();
               LatestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellTradeTime)
            {
               EarliestSellTradeTime = OrderOpenTime();
               EarliestSellPrice = OrderOpenPrice();
               EarliestSellTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellPrice)
            {
               HighestSellPrice = OrderOpenPrice();
               HighestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellPrice)
            {
               LowestSellPrice = OrderOpenPrice();
               LowestSellTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellPrice)
              
         }//if (OrderType() == OP_SELL)
         
         
      }//if (OrderType() < 2)
      
      
      //Build up the position details of stop/limit orders
      if (OrderType() > 1)
      {
         //Buystops
         if (OrderType() == OP_BUYSTOP)
         {
            BuyStopOpen = true;
            BuyStopTicketNo = OrderTicket();
            BuyStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyStopTradeTime)
            {
               LatestBuyStopTradeTime = OrderOpenTime();
               LatestBuyStopPrice = OrderOpenPrice();
               LatestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyStopTradeTime)
            {
               EarliestBuyStopTradeTime = OrderOpenTime();
               EarliestBuyStopPrice = OrderOpenPrice();
               EarliestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyStopPrice)
            {
               HighestBuyStopPrice = OrderOpenPrice();
               HighestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyStopPrice)
            {
               LowestBuyStopPrice = OrderOpenPrice();
               LowestBuyStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyStopPrice)
              
         }//if (OrderType() == OP_BUYSTOP)
         
         //Sellstops
         if (OrderType() == OP_SELLSTOP)
         {
            SellStopOpen = true;
            SellStopTicketNo = OrderTicket();
            SellStopsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellStopTradeTime)
            {
               LatestSellStopTradeTime = OrderOpenTime();
               LatestSellStopPrice = OrderOpenPrice();
               LatestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellStopTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellStopTradeTime)
            {
               EarliestSellStopTradeTime = OrderOpenTime();
               EarliestSellStopPrice = OrderOpenPrice();
               EarliestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellStopTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellStopPrice)
            {
               HighestSellStopPrice = OrderOpenPrice();
               HighestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellStopPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellStopPrice)
            {
               LowestSellStopPrice = OrderOpenPrice();
               LowestSellStopTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellStopPrice)
              
         }//if (OrderType() == OP_SELLSTOP)
         
         //Buy limits
         if (OrderType() == OP_BUYLIMIT)
         {
            BuyLimitOpen = true;
            BuyLimitTicketNo = OrderTicket();
            BuyLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestBuyLimitTradeTime)
            {
               LatestBuyLimitTradeTime = OrderOpenTime();
               LatestBuyLimitPrice = OrderOpenPrice();
               LatestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestBuyLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            {
               EarliestBuyLimitTradeTime = OrderOpenTime();
               EarliestBuyLimitPrice = OrderOpenPrice();
               EarliestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestBuyLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestBuyLimitPrice)
            {
               HighestBuyLimitPrice = OrderOpenPrice();
               HighestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestBuyLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestBuyLimitPrice)
            {
               LowestBuyLimitPrice = OrderOpenPrice();
               LowestBuyLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestBuyLimitPrice)
              
         }//if (OrderType() == OP_BUYLIMIT)
         
         //Sell limits
         if (OrderType() == OP_SELLLIMIT)
         {
            SellLimitOpen = true;
            SellLimitTicketNo = OrderTicket();
            SellLimitsCount++;
            
            //Latest trade
            if (OrderOpenTime() > LatestSellLimitTradeTime)
            {
               LatestSellLimitTradeTime = OrderOpenTime();
               LatestSellLimitPrice = OrderOpenPrice();
               LatestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() > LatestSellLimitTradeTime)  
 
            //Furthest back in time
            if (OrderOpenTime() < EarliestSellLimitTradeTime)
            {
               EarliestSellLimitTradeTime = OrderOpenTime();
               EarliestSellLimitPrice = OrderOpenPrice();
               EarliestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenTime() < EarliestSellLimitTradeTime)
            
            //Highest trade price
            if (OrderOpenPrice() > HighestSellLimitPrice)
            {
               HighestSellLimitPrice = OrderOpenPrice();
               HighestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > HighestSellLimitPrice)
            
            //Lowest trade price
            if (OrderOpenPrice() < LowestSellLimitPrice)
            {
               LowestSellLimitPrice = OrderOpenPrice();
               LowestSellLimitTicketNo = OrderTicket();
            }//if (OrderOpenPrice() > LowestSellLimitPrice)
              
         }//if (OrderType() == OP_SELLLIMIT)
         
      
      }//if (OrderType() > 1)
      
      
      
      
      
      if (CloseEnough(OrderStopLoss(), 0) && !CloseEnough(StopLoss, 0)) InsertStopLoss(OrderTicket());
      if (CloseEnough(OrderTakeProfit(), 0) && !CloseEnough(TakeProfit, 0)) InsertTakeProfit(OrderTicket() );
   
      //Replace missing tp and sl lines
      if (HiddenPips > 0) ReplaceMissingSlTpLines();
      
      TradeWasClosed = LookForTradeClosure(OrderTicket() );
      if (TradeWasClosed) 
      {
         if (type == OP_BUY) BuyOpen = false;//Will be reset if subsequent trades are buys that are not closed
         if (type == OP_SELL) SellOpen = false;//Will be reset if subsequent trades are sells that are not closed
         cc++;
         continue;
      }//if (TradeWasClosed)

      //Profitable trade management
      if (OrderProfit() > 0) 
      {
         TradeManagementModule(OrderTicket() );
      }//if (OrderProfit() > 0) 
      
               
      
   }//for (int cc = OrdersTotal() - 1; cc <= 0; c`c--)
   
   //Sort ticket numbers for FIFO
   if (ArraySize(FifoTicket) > 0)
      ArraySort(FifoTicket, WHOLE_ARRAY, 0, MODE_DESCEND);
      
   
   
    
}//End void CountOpenTrades();
//+------------------------------------------------------------------+


void InsertStopLoss(int ticket)
{
   //Inserts a stop loss if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if StopLoss > 0 && OrderStopLoss() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (OrderStopLoss() > 0) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double stop;
   
   if (OrderType() == OP_BUY)
   {
      stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(stop, 0) ) return;
   
   //In case some errant behaviour/code creates a sl the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && stop > OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && stop < OrderOpenPrice() ) 
   {
      stop = 0;
      ReportError(" InsertStopLoss()", " stop loss > market ");
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 

   
   if (!CloseEnough(stop, OrderStopLoss())) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(stop, OrderStopLoss())) 

}//End void InsertStopLoss(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InsertTakeProfit(int ticket)
{
   //Inserts a TP if the ECN crim managed to swindle the original trade out of the modification at trade send time
   //Called from CountOpenTrades() if TakeProfit > 0 && OrderTakeProfit() == 0.
   
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET)) return;
   if (OrderCloseTime() > 0) return;//Somehow, we are examining a closed trade
   if (!CloseEnough(OrderTakeProfit(), 0) ) return;//Function called unnecessarily.
   
   while(IsTradeContextBusy()) Sleep(100);
   
   double take;
   
   if (OrderType() == OP_BUY)
   {
      take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
   }//if (OrderType() == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
   }//if (OrderType() == OP_SELL)
   
   if (CloseEnough(take, 0) ) return;
   
   //In case some errant behaviour/code creates a tp the wrong side of the market, which would cause an instant close.
   if (OrderType() == OP_BUY && take < OrderOpenPrice()  && !CloseEnough(take, 0) ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_BUY && take < OrderOpenPrice() ) 
   
   if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   {
      take = 0;
      ReportError(" InsertTakeProfit()", " take profit < market ");
      return;
   }//if (OrderType() == OP_SELL && take > OrderOpenPrice() ) 
   
   
   if (!CloseEnough(take, OrderTakeProfit()) ) 
   {
      bool result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (!CloseEnough(take, OrderTakeProfit()) ) 

}//End void InsertTakeProfit(int ticket)
////////////////////////////////////////////////////////////////////////////////////////
//Pending trade price lines module.
//Doubles up by providing missing lines for the stealth stuff
void DrawPendingPriceLines()
{
   //This function will work for a full pending-trade EA.
   //The pending tp/sl can be used for hiding the stops in a market-trading ea
   
   /*
   ObjectDelete(pendingpriceline);
   ObjectCreate(pendingpriceline, OBJ_HLINE, 0, TimeCurrent(), PendingPrice);
   if (PendingBuy) ObjectSet(pendingpriceline, OBJPROP_COLOR, Green);
   if (PendingSell) ObjectSet(pendingpriceline, OBJPROP_COLOR, Red);
   ObjectSet(pendingpriceline, OBJPROP_WIDTH, 1);
   ObjectSet(pendingpriceline, OBJPROP_STYLE, STYLE_DASH);
   */
   string LineName = TpPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenTakeProfit = 0;
   if (TicketNo > -1 && OrderTakeProfit() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL)
      {
         HiddenTakeProfit = NormalizeDouble(OrderTakeProfit() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderTakeProfit() > 0)
   
   if (HiddenTakeProfit > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenTakeProfit);
      ObjectSet(LineName, OBJPROP_COLOR, Green);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenTakeProfit > 0)
   
   
   LineName = SlPrefix + DoubleToStr(TicketNo, 0);//TicketNo is set by the calling function - either CountOpenTrades or DoesTradeExist
   HiddenStopLoss = 0;
   if (TicketNo > -1 && OrderStopLoss() > 0)
   {
      if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() + (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)
      
      if (OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         HiddenStopLoss = NormalizeDouble(OrderStopLoss() - (HiddenPips / factor), Digits);
      }//if (OrderType() == OP_BUY)      
   }//if (TicketNo > -1 && OrderStopLoss() > 0)
   
   if (HiddenStopLoss > 0 && ObjectFind(LineName) == -1)
   {
      ObjectDelete(LineName);
      ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), HiddenStopLoss);
      ObjectSet(LineName, OBJPROP_COLOR, Red);
      ObjectSet(LineName, OBJPROP_WIDTH, 1);
      ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
   }//if (HiddenStopLoss > 0)
   
   

}//End void DrawPendingPriceLines()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePendingPriceLines()
{

   //ObjectDelete(pendingpriceline);
   string LineName=TpPrefix+DoubleToStr(TicketNo,0);
   ObjectDelete(LineName);
   LineName=SlPrefix+DoubleToStr(TicketNo,0);
   ObjectDelete(LineName);

}//End void DeletePendingPriceLines()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReplaceMissingSlTpLines()
{

   if(OrderTakeProfit()>0 || OrderStopLoss()>0) DrawPendingPriceLines();

}//End void ReplaceMissingSlTpLines()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOrphanTpSlLines()
{

   if (ObjectsTotal() == 0) return;
   
   for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   {
      string name = ObjectName(cc);
      
      if ((StringSubstrOld(name, 0, 2) == TpPrefix || StringSubstrOld(name, 0, 2) == SlPrefix) && ObjectType(name) == OBJ_HLINE)
      {
         int tn = StrToDouble(StringSubstrOld(name, 2));
         if (tn > 0) 
         {
            if (!BetterOrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            {
               ObjectDelete(name);
            }//if (!BetterOrderSelect(tn, SELECT_BY_TICKET, MODE_TRADES) || OrderCloseTime() > 0)
            
         }//if (tn > 0) 
         
         
      }//if (StringSubstrOld(name, 0, 1) == TpPrefix)
      
   }//for (int cc = ObjectsTotal() - 1; cc >= 0; cc--)
   
   
}//End void DeleteOrphanTpSlLines()

//END Pending trade price lines module
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//TRADE MANAGEMENT MODULE

void ReportError(string function, string message)
{
   //All purpose sl mod error reporter. Called when a sl mod fails
   
   int err=GetLastError();
   if (err == 1) return;//That bloody 'error but no error' report is a nuisance
   
      
   Alert(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   Print(WindowExpertName(), " ", OrderTicket(), " ", function, message, err,": ",ErrorDescription(err));
   
}//void ReportError()

bool ModifyOrder(int ticket, double price, double stop, double take, datetime expiry, color col, string function, string reason)
{
   //Multi-purpose order modify function
   
   bool result = OrderModify(ticket, price ,stop , take, expiry, col);

   //Actions when trade close succeeds
   if (result)
   {
      return(true);
   }//if (result)
   
   //Actions when trade close fails
   if (!result)
      ReportError(function, reason);

   //Got this far, so modify failed
   return(false);
   
}// End bool ModifyOrder()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakEvenStopLoss(int ticket) // Move stop loss to breakeven
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
      
   double NewStop;
   bool result;
   bool modify=false;
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   double target = OrderOpenPrice();
   
   if (OrderType()==OP_BUY)
   {
      if (HiddenPips > 0) target-= (HiddenPips / factor);
      if (OrderStopLoss() >= target) return;
      if (Bid >= OrderOpenPrice () + (BreakEvenPips / factor))          
      {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()+(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, TimeCurrent(), NewStop);         
         }//if (HiddenPips > 0)
         modify = true;   
      }//if (Bid >= OrderOpenPrice () + (Point*BreakEvenPips) && 
   }//if (OrderType()==OP_BUY)               			         
    
   if (OrderType()==OP_SELL)
   {
     if (HiddenPips > 0) target+= (HiddenPips / factor);
      if (OrderStopLoss() <= target && OrderStopLoss() > 0) return;
     if (Ask <= OrderOpenPrice() - (BreakEvenPips / factor)) 
     {
         //Calculate the new stop
         NewStop = NormalizeDouble(OrderOpenPrice()-(BreakEvenProfit / factor), Digits);
         if (HiddenPips > 0)
         {
            if (ObjectFind(LineName) == -1)
            {
               ObjectCreate(LineName, OBJ_HLINE, 0, TimeCurrent(), 0);
               ObjectSet(LineName, OBJPROP_COLOR, Red);
               ObjectSet(LineName, OBJPROP_WIDTH, 1);
               ObjectSet(LineName, OBJPROP_STYLE, STYLE_DOT);
            }//if (ObjectFind(LineName == -1) )
         
            ObjectMove(LineName, 0, Time[0], NewStop);
         }//if (HiddenPips > 0)         
         modify = true;   
     }//if (Ask <= OrderOpenPrice() - (Point*BreakEvenPips) && (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))     
   }//if (OrderType()==OP_SELL)

   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      if (NewStop == OrderStopLoss() ) return;
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      
      while (IsTradeContextBusy() ) Sleep(100);
      if (PartCloseEnabled && OrderComment() == TradeComment) bool success = PartCloseOrder(OrderTicket() );
   }//if (modify)
   
} // End BreakevenStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseOrder(int ticket)
{
   //Close PartClosePercent of the initial trade.
   //Return true if close succeeds, else false
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) return(true);//in case the trade closed
   
   bool Success = false;
   double CloseLots = NormalizeLots(OrderSymbol(),OrderLots() * (PartClosePercent / 100));
   
   Success = OrderClose(ticket, CloseLots, OrderClosePrice(), 1000, Blue); //fxdaytrader, NormalizeLots(...
   if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   if (!Success) 
   {
       //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
       while(IsTradeContextBusy()) Sleep(100);
       RefreshRates();
       if (OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
       if (OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
       //end mod.  
       //original:
       if (Success) TradeHasPartClosed = true;//Warns CountOpenTrades() that the OrderTicket() is incorrect.
   
       if (!Success) 
       {
         ReportError(" PartCloseOrder()", pcm);
         return (false);
       } 
   }//if (!Success) 
      
   //Got this far, so closure succeeded
   return (true);   

}//bool PartCloseOrder(int ticket)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void JumpingStopLoss(int ticket) 
{
   // Jump sl by pips and at intervals chosen by user .

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;

   //if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   double NewStop;
   bool modify=false;
   bool result;
   
   
    if (OrderType()==OP_BUY)
    {
       if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
       // Increment sl by sl + JumpingStopPips.
       // This will happen when market price >= (sl + JumpingStopPips)
       //if (Bid>= sl + ((JumpingStopPips*2) / factor) )
       if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
       if (Bid >=  sl + ((JumpingStopPips * 2) / factor) )//George{
       {
          NewStop = NormalizeDouble(sl + (JumpingStopPips / factor), Digits);
          if (AddBEP) NewStop = NormalizeDouble(NewStop + (BreakEvenProfit / factor), Digits);
          if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
          if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
       }// if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())     
    }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - JumpingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - ((JumpingStopPips*2) / factor)) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl - ((JumpingStopPips * 2) / factor) )//George
          {
             NewStop = NormalizeDouble(sl - (JumpingStopPips / factor), Digits);
             if (AddBEP) NewStop = NormalizeDouble(NewStop - (BreakEvenProfit / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }// close if (Bid>= sl + (JumpingStopPips / factor) && sl>= OrderOpenPrice())         
       }//if (OrderType()==OP_SELL)



   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);      
   }//if (modify)

} //End of JumpingStopLoss sub

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   //if (CloseEnough(sl, 0) ) return;//No line, so nothing to do
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop;
   bool modify=false;
   bool result;
   
    if (OrderType()==OP_BUY)
       {
          if (sl < OrderOpenPrice() ) return;//Not at breakeven yet
          // Increment sl by sl + TrailingStopPips.
          // This will happen when market price >= (sl + JumpingStopPips)
          //if (Bid>= sl + (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMax(OrderStopLoss(), OrderOpenPrice());
          if (Bid >= sl + (TrailingStopPips / factor) )//George
          {
             NewStop = NormalizeDouble(sl + (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (NewStop - OrderStopLoss() >= Point) modify = true;//George again. What a guy
          }//if (Bid >= MathMax(sl,OrderOpenPrice()) + (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_BUY)
       
       if (OrderType()==OP_SELL)
       {
          if (sl > OrderOpenPrice() ) return;//Not at breakeven yet
          // Decrement sl by sl - TrailingStopPips.
          // This will happen when market price <= (sl - JumpingStopPips)
          //if (Bid<= sl - (TrailingStopPips / factor) ) Original code
          if (CloseEnough(sl, 0) ) sl = MathMin(OrderStopLoss(), OrderOpenPrice());
          if (CloseEnough(sl, 0) ) sl = OrderOpenPrice();
          if (Bid <= sl  - (TrailingStopPips / factor))//George
          {
             NewStop = NormalizeDouble(sl - (TrailingStopPips / factor), Digits);
             if (HiddenPips > 0) ObjectMove(LineName, 0, Time[0], NewStop);
             if (OrderStopLoss() - NewStop >= Point || OrderStopLoss() == 0) modify = true;//George again. What a guy   
          }//if (Bid <= MathMin(sl, OrderOpenPrice() ) - (TrailingStopPips / factor) )//George
       }//if (OrderType()==OP_SELL)


   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
   }//if (modify)
      
} // End of TrailingStopLoss sub
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CandlestickTrailingStop(int ticket)
{

   //Security check
   if (!BetterOrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
      return;
   
   //Trails the stop at the hi/lo of the previous candle shifted by the user choice.
   //Only tries to do this once per bar, so an invalid stop error will only be generated once. I could code for
   //a too-close sl, but cannot be arsed. Coders, sort this out for yourselves.
   
   if (OldCstBars == iBars(NULL, CstTimeFrame)) return;
   OldCstBars = iBars(NULL, CstTimeFrame);

   if (OrderProfit() < 0) return;//Nothing to do
   string LineName = SlPrefix + DoubleToStr(OrderTicket(), 0);
   double sl = ObjectGet(LineName, OBJPROP_PRICE1);
   if (CloseEnough(sl, 0) ) sl = OrderStopLoss();
   double NewStop;
   bool modify=false;
   bool result;
   

   if (OrderType() == OP_BUY)
   {
      if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
      {
         NewStop = NormalizeDouble(iLow(NULL, CstTimeFrame, CstTrailCandles), Digits);
         //Check that the new stop is > the old. Exit the function if not.
         if (NewStop < OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop < OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop - (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
         modify = true;   
      }//if (iLow(NULL, CstTimeFrame, CstTrailCandles) > sl)
   }//if (OrderType == OP_BUY)
   
   if (OrderType() == OP_SELL)
   {
      if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
      {
         NewStop = NormalizeDouble(iHigh(NULL, CstTimeFrame, CstTrailCandles), Digits);
         
         //Check that the new stop is < the old. Exit the function if not.
         if (NewStop > OrderStopLoss() || CloseEnough(NewStop, OrderStopLoss()) ) return;
         //Check that the new stop locks in profit, if the user requires this.
         if (TrailMustLockInProfit && NewStop > OrderOpenPrice() ) return;
         
         if (HiddenPips > 0) 
         {
            ObjectMove(LineName, 0, Time[0], NewStop);
            NewStop = NormalizeDouble(NewStop + (HiddenPips / factor), Digits);
         }//if (HiddenPips > 0) 
         modify = true;   
      }//if (iHigh(NULL, CstTimeFrame, CstTrailCandles) < sl)
   }//if (OrderType() == OP_SELL)
   
   //Move 'hard' stop loss whether hidden or not. Don't want to risk losing a breakeven through disconnect.
   if (modify)
   {
      while (IsTradeContextBusy() ) Sleep(100);
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), NewStop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slm);
      if (!result) 
      {
         OldCstBars = 0;
      }//if (!result) 
      
   }//if (modify)

}//End void CandlestickTrailingStop()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManagementModule(int ticket)
{

   // Call the working subroutines one by one. 

   //Candlestick trailing stop
   if(UseCandlestickTrailingStop) CandlestickTrailingStop(ticket);

   // Breakeven
   if(BreakEven) BreakEvenStopLoss(ticket);

   // JumpingStop
   if(JumpingStop) JumpingStopLoss(ticket);

   //TrailingStop
   if(TrailingStop) TrailingStopLoss(ticket);


}//void TradeManagementModule()
//END TRADE MANAGEMENT MODULE
////////////////////////////////////////////////////////////////////////////////////////



double CalculateTradeProfitInPips(int type)
{
   //This code supplied by Lifesys. Many thanks Paul.
   
   //Returns the pips Upl of the currently selected trade. Called by CountOpenTrades()
   double profit;
   // double point = BrokerPoint(OrderSymbol() ); // no real use
   double ask = MarketInfo(OrderSymbol(), MODE_ASK);
   double bid = MarketInfo(OrderSymbol(), MODE_BID);

   if (type == OP_BUY)
   {
      profit = bid - OrderOpenPrice();
   }//if (OrderType() == OP_BUY)

   if (type == OP_SELL)
   {
      profit = OrderOpenPrice() - ask;
   }//if (OrderType() == OP_SELL)
   //profit *= PFactor(OrderSymbol()); // use PFactor instead of point. This line for multi-pair ea's
   profit *= factor; // use PFactor instead of point.

   return(profit); // in real pips
}//double CalculateTradeProfitInPips(int type)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseEnough(double num1,double num2)
{
/*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetPipFactor(string Xsymbol)
{
   //Code from Tommaso's APTM. Thanks Tommaso.
   
   static const string factor1000[]={"SEK","TRY","ZAR","MXN"};
   static const string factor100[]         = {"JPY","XAG","SILVER","BRENT","WTI"};
   static const string factor10[]          = {"XAU","GOLD","SP500","US500Cash","US500","Bund"};
   static const string factor1[]           = {"UK100","WS30","DAX30","NAS100","CAC40","FRA40","GER30","ITA40","EUSTX50","JPN225","US30Cash","US30"};

   int j = 0;
   
   int xFactor=10000;       // correct xFactor for most pairs
   if(MarketInfo(Xsymbol,MODE_DIGITS)<=1) xFactor=1;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==2) xFactor=10;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==3) xFactor=100;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==4) xFactor=1000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==5) xFactor=10000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==6) xFactor=100000;
   else if(MarketInfo(Xsymbol,MODE_DIGITS)==7) xFactor=1000000;
   for(j=0; j<ArraySize(factor1000); j++)
   {
      if(StringFind(Xsymbol,factor1000[j])!=-1) xFactor=1000;
   }
   for(j=0; j<ArraySize(factor100); j++)
   {
      if(StringFind(Xsymbol,factor100[j])!=-1) xFactor=100;
   }
   for(j=0; j<ArraySize(factor10); j++)
   {
      if(StringFind(Xsymbol,factor10[j])!=-1) xFactor=10;
   }
   for(j=0; j<ArraySize(factor1); j++)
   {
      if(StringFind(Xsymbol,factor1[j])!=-1) xFactor=1;
   }

   return (xFactor);
}//End int GetPipFactor(string Xsymbol)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSwap(string symbol)
{
   LongSwap=MarketInfo(symbol,MODE_SWAPLONG);
   ShortSwap=MarketInfo(symbol,MODE_SWAPSHORT);

}//End void GetSwap()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TooClose()
{
   //Returns false if the previously closed trade and the proposed new trade are sufficiently far apart, else return true. Called from IsTradeAllowed().
   
   SafetyViolation = false;//For chart feedback
         
   if (OrdersHistoryTotal() == 0) return(false);
   
   for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS, MODE_HISTORY) ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderType() > 1) continue;
      
      
      //Examine the OrderCloseTime to see if it closed far enought back in time.
      if (TimeCurrent() - OrderCloseTime() < (MinMinutesBetweenTrades * 60))
      {
         SafetyViolation = true;
         return(true);//Too close, so disallow the trade
      }//if (OrderCloseTime() - TimeCurrent() < (MinMinutesBetweenTrades * 60))
      break;      
   }//for (int cc = OrdersHistoryTotal() - 1; cc >= 0; cc--)
   
   //Got this far, so there is no disqualifying trade in the history
   return(false);
   
}//bool TooClose()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsClosedTradeRogue()
{
   //~ Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue. Examine trades closed within the last 5 minutes.
   
   //~ If it is a rogue:
   //~ * Show a warning alert.
   //~ * Send an email alert.
   //~ * Suspend the robot
   
   if (OrdersHistoryTotal() == 0) return(false);
   
   datetime latestTime = TimeCurrent() - ( 5 * 60 );
  
   datetime duration = -1; //impossible value
  
   //We cannot guarantee that the most recent trade shown in our History tab is actually the most recent on the crim's server - CraptT4 again. pah has supplied this code to ensure that we are examining the latest trade. Many thanks, Paul.
   
   // look for trades that closed within the last 5 minutes
   // otherwise we will always find the last rogue trade
   // even when that happened some time ago and can be ignored
   
   for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   {
      if ( ! BetterOrderSelect(i, SELECT_BY_POS, MODE_HISTORY) ) continue;
       
      if ( OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() ) continue;
        
      if ( OrderCloseTime() >= latestTime )
      {
         latestTime = OrderCloseTime();
         duration    = OrderCloseTime() - OrderOpenTime();
      }//if ( OrderCloseTime() >= latestTime )
       
   }//for ( int i = OrdersHistoryTotal()-1; i >= 0; i-- )
   
  
   bool rogue = ( duration >= 0 ) && ( duration < ( MinMinutesBetweenTradeOpenClose * 60) );
  
   if (rogue)
   {
      RobotSuspended = true;
      Alert(Symbol(), " ", WindowExpertName() , " possible rogue trade.");
      SendMail("Possible rogue trade warning ", Symbol() + " " + WindowExpertName() + " possible rogue trade.");
      Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIS EA IMMEDIATELY ****************** ");
      return(true);//Too close, so disallow the trade
   
   }//if (rogue)
   
   //Got this far, so there is no rogue trade
   return(false);
   


}//bool IsClosedTradeRogue()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawTrendLine(string name,datetime time1,double val1,datetime time2,double val2,color col,int width,int style,bool ray)
{
//Plots a trendline with the given parameters

   ObjectDelete(name);

   ObjectCreate(name,OBJ_TREND,0,time1,val1,time2,val2);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_WIDTH,width);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_RAY,ray);

}//End void DrawLine()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawHorizontalLine(string name,double price,color col,int style,int width)
{

   ObjectDelete(name);

   ObjectCreate(name,OBJ_HLINE,0,TimeCurrent(),price);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawLine(string name, double price, color col)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVerticalLine(string name,color col,int style,int width)
{
//ObjectCreate(vline,OBJ_VLINE,0,iTime(NULL, TimeFrame, 0), 0);
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,iTime(NULL,0,0),0);
   ObjectSet(name,OBJPROP_COLOR,col);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,width);

}//void DrawVerticalLine()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MarginCheck()
{

   EnoughMargin = true;//For user display
   MarginMessage = "";
   if (UseScoobsMarginCheck && OpenTrades > 0)
   {
      if(AccountMargin() > (AccountFreeMargin()/100)) 
      {
         MarginMessage = "There is insufficient margin to allow trading. You might want to turn off the UseScoobsMarginCheck input.";
         return(false);
      }//if(AccountMargin() > (AccountFreeMargin()/100)) 
      
   }//if (UseScoobsMarginCheck)


   if (UseForexKiwi && AccountMargin() > 0)
   {
      
      double ml = NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2);
      if (ml < FkMinimumMarginPercent)
      {
         MarginMessage = StringConcatenate("There is insufficient margin percent to allow trading. ", DoubleToStr(ml, 2), "%");
         return(false);
      }//if (ml < FkMinimumMarginPercent)
   }//if (UseForexKiwi && AccountMargin() > 0)
   
  
   //Got this far, so there is sufficient margin for trading
   return(true);
}//End bool MarginCheck()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PeriodText(int per)
{

	switch (per)
	{
   	case PERIOD_M1:
   		return("M1");
   	case PERIOD_M5:
   		return("M5");
   	case PERIOD_M15:
   		return("M15");
   	case PERIOD_M30:
   		return("M30");
   	case PERIOD_H1:
   		return("H1");
   	case PERIOD_H4:
   		return("H4");
   	case PERIOD_D1:
   		return("D1");
   	case PERIOD_MN1:
   		return("MN1");
   	default:
   		return("");
	}

}//End string PeriodText(int per)

//+------------------------------------------------------------------+
//  Code to check that there are at least 100 bars of history in
//  the sym / per in the passed params
//+------------------------------------------------------------------+
bool HistoryOK(string sym,int per)
  {

   double tempArray[][6];  //used for the call to ArrayCopyRates()

                           //get the number of bars
   int bars=iBars(sym,per);
//and report it in the log
   Print("Checking ",sym," for complete data.... number of ",PeriodText(per)," bars = ",bars);

   if(bars<100)
     {
      //we didn't have enough, so set the comment and try to trigger the DL another way
      Comment("Symbol ",sym," -- Waiting for "+PeriodText(per)+" data.");
      ArrayCopyRates(tempArray,sym,per);
      int error=GetLastError();
      if(error!=0) Print(sym," - requesting data from the server...");

      //return false so the caller knows we don't have the data
      return(false);
     }//if (bars < 100)

//if we got here, the data is fine, so clear the comment and return true
   Comment("");
   return(true);

  }//End bool HistoryOK(string sym,int per)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTpSlAreCorrect(int type)
{
   //Looks at an open trade and checks to see that the exact tp/sl were sent with the trade.
   
   
   double stop = 0, take = 0, diff = 0;
   bool ModifyStop = false, ModifyTake = false;
   bool result;
   
   //Is the stop at BE?
   if (type == OP_BUY && OrderStopLoss() >= OrderOpenPrice() ) return;
   if (type == OP_SELL && OrderStopLoss() <= OrderOpenPrice() ) return;
   
   if (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderOpenPrice() - OrderStopLoss()) * factor;
         if (!CloseEnough(diff, StopLoss + (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderTakeProfit() - OrderOpenPrice()) * factor;
         if (!CloseEnough(diff, TakeProfit -  (HiddenPips / factor))) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_BUY, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_BUY)
   
   if (type == OP_SELL || type == OP_SELLSTOP || type == OP_SELLLIMIT)
   {
      if (!CloseEnough(OrderStopLoss(), 0) )
      {
         diff = (OrderStopLoss() - OrderOpenPrice() ) * factor;
         if (!CloseEnough(diff, StopLoss -  (HiddenPips / factor))) 
         {
            ModifyStop = true;
            stop = CalculateStopLoss(OP_SELL, OrderOpenPrice());

         }//if (!CloseEnough(diff, StopLoss) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      

      if (!CloseEnough(OrderTakeProfit(), 0) )
      {
         diff = (OrderOpenPrice() - OrderTakeProfit() ) * factor;
         if (!CloseEnough(diff, TakeProfit +  (HiddenPips / factor))) 
         {
            ModifyTake = true;
            take = CalculateTakeProfit(OP_SELL, OrderOpenPrice());
         }//if (!CloseEnough(diff, TakeProfit) )          
      }//if (!CloseEnough(OrderStopLoss(), 0) )      
   }//if (type == OP_SELL)
   
   if (ModifyStop)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), clrNONE, __FUNCTION__, slim);
   }//if (ModifyStop)
   
   if (ModifyTake)
   {
      result = ModifyOrder(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), clrNONE, __FUNCTION__, tpm);
   }//if (ModifyStop)
   

}//void CheckTpSlAreCorrect(int type)

//+------------------------------------------------------------------+
//| NormalizeLots(string symbol, double lots)                        |
//+------------------------------------------------------------------+
//function added by fxdaytrader
//Lot size must be adjusted to be a multiple of lotstep, which may not be a power of ten on some brokers
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol,double lots)
{
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
}
////////////////////////////////////////////////////////////////////////////////////////

// for 6xx build compatibilità added by milanese

string StringSubstrOld(string x,int a,int b=-1) 
{
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
}

void TakeChartSnapshot(int ticket, string oc)
{

   //Takes a snapshot of the chart after a trade open or close. Files are stored in the MQL4/Files folder
   //of the platform.
   
   //--- Prepare a text to show on the chart and a file name.
   //oc is either " open" or " close"
   string name="ChartScreenShot " + string(ticket) + oc + ".gif";
   
   //--- Save the chart screenshot in a file in the terminal_directory\MQL4\Files\
   if(ChartScreenShot(0,name, PictureWidth, PictureHeight, ALIGN_RIGHT))
      Alert("Screen snapshot taken ",name);
   //---
   

}//void TakeChartSnapshot()


bool MopUpTradeClosureFailures()
{
   //Cycle through the ticket numbers in the ForceCloseTickets array, and attempt to close them
   
   bool Success = true;
   
   for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   {
      //Order might have closed during a previous attempt, so ensure it is still open.
      if (!BetterOrderSelect(ForceCloseTickets[cc], SELECT_BY_TICKET, MODE_TRADES) )
         continue;
   
      bool result = CloseOrder(OrderTicket() );
      if (!result)
         Success = false;
   }//for (int cc = ArraySize(ForceCloseTickets) - 1; cc >= 0; cc--)
   
   if (Success)
      ArrayResize(ForceCloseTickets, 0);
   
   return(Success);


}//END bool MopUpTradeClosureFailures()



bool DoesTradeExist(int type, double price)
{

   if (OrdersTotal() == 0)
      return(false);
   if (OpenTrades == 0)
      return(false);
   
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   {
      if (!BetterOrderSelect(cc, SELECT_BY_POS) ) continue;
      if (OrderSymbol() != Symbol() ) continue;
      if (OrderMagicNumber() != MagicNumber) continue;
      if (OrderType() != type) continue;
      if (!CloseEnough(OrderOpenPrice(), price) ) continue;
      
      //Got to here, so we have found a trade
      return(true);

   }//for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   
   //Got this far, so no trade found
   return(false);   

}//End bool DoesTradeExist(int type, double price)

void CalculateLotAsAmountPerCashDollops()
{

   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double decimal = 0;
   if (CloseEnough(lotstep, 0.1) )
      decimal = 1;
   if (CloseEnough(lotstep, 0.01) )
      decimal = 2;
      
   double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   double DoshDollop = AccountInfoDouble(ACCOUNT_BALANCE); 
   
   if (UseEquity)
      DoshDollop = AccountInfoDouble(ACCOUNT_EQUITY); 

   
   //Initial lot size
   Lot = NormalizeDouble((DoshDollop / SizeOfDollop) * LotsPerDollopOfCash, decimal);
     
   //Min/max size check
   if (Lot > maxlot)
      Lot = maxlot;
      
   if (Lot < minlot)
      Lot = minlot;      


}//void CalculateLotAsAmountPerCashDollops()

bool SundayMondayFridayStuff()
{

   //Friday/Saturday stop trading hour
   int d = TimeDayOfWeek(TimeLocal());
   int h = TimeHour(TimeLocal());
   if (d == 5)
      if (h >= FridayStopTradingHour)
         return(false);
         
   if (d == 4)
      if (!TradeThursdayCandle)
         return(false);
        
   
   if (d == 6)
      if (h >= SaturdayStopTradingHour)
         return(false);
  
   //Sunday candle
   if (d == 0)
      if (!TradeSundayCandle)
         return(false);
         
   //Monday start hour
   if (d == 1)
      if (h < MondayStartHour)      
         return(false);
         
   //Got this far, so we are in a trading period
   return(true);      
   
}//End bool  SundayMondayFridayStuff()

bool indiExists( string indiName ) 
{

   //Returns true if a custom indi exists in the user's indi folder, else false
   bool exists = false;
   
   ResetLastError();
   double value = iCustom( Symbol(), Period(), indiName, 0, 0 );
   if ( GetLastError() == 0 ) exists = true;
   
   return(exists);

}//End bool indiExists( string indiName ) 

//For OrderSelect() Craptrader documentation states:
//   The pool parameter is ignored if the order is selected by the ticket number. The ticket number is a unique order identifier. 
//   To find out from what list the order has been selected, its close time must be analyzed. If the order close time equals to 0, 
//   the order is open or pending and taken from the terminal open orders list.
//This function heals this and allows use of pool parameter when selecting orders by ticket number.
//Tomele provided this code. Thanks Thomas.
bool BetterOrderSelect(int index,int select,int pool=-1)
{
   if (select==SELECT_BY_POS)
   {
      if (pool==-1) //No pool given, so take default
         pool=MODE_TRADES;
         
      return(OrderSelect(index,select,pool));
   }
   
   if (select==SELECT_BY_TICKET)
   {
      if (pool==-1) //No pool given, so submit as is
         return(OrderSelect(index,select));
         
      if (pool==MODE_TRADES) //Only return true for existing open trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()==0)
               return(true);
               
      if (pool==MODE_HISTORY) //Only return true for existing closed trades
         if(OrderSelect(index,select))
            if(OrderCloseTime()>0)
               return(true);
   }
   
   return(false);
}//End bool BetterOrderSelect(int index,int select,int pool=-1)

//This code by tomele. Thank you Thomas. Wonderful stuff.
bool AreWeAtRollover()
{

   double time;
   int hours,minutes,rstart,rend,ltime;
   
   time=StrToDouble(RollOverStarts);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rstart=60*hours+minutes;
      
   time=StrToDouble(RollOverEnds);
   hours=(int)MathFloor(time);
   minutes=(int)MathRound((time-hours)*100);
   rend=60*hours+minutes;
   
   ltime=TimeHour(TimeCurrent())*60+TimeMinute(TimeCurrent());

   if (rend>rstart)
     if(ltime>rstart && ltime<rend)
       return(true);
   if (rend<rstart) //Over midnight
     if(ltime>rstart || ltime<rend)
       return(true);

   //Got here, so not at rollover
   return(false);

}//End bool AreWeAtRollover()

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
//----
   //int cc;

   //mptm sets a Global Variable when it is closing the trades.
   //This tells this ea not to send any fresh trades.
   if (GlobalVariableCheck(GvName))
      return;
   //'Close all trades this pair only script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(LocalGvName))
      return;
   //'Nuclear option script' sets a GV to tell EA's not to attempt a trade during closure
   if (GlobalVariableCheck(NuclearGvName))
      return;

   if (RemoveExpert)
   {
      ExpertRemove();
      return;
   }//if (RemoveExpert)

   //Those stupid sods at MetaCrapper have ensured that stopping an ea by diabling AutoTrading no longer works. Ye Gods alone know why.
   //This routine provided by FxCoder. Thanks Bob.
   if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   {
      Comment("                          TERMINAL AUTOTRADING IS DISABLED");
      return;
      
   }//if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
   if (!IsTradeAllowed() )
   {
      Comment("                          THIS EXPERT HAS LIVE TRADING DISABLED");
      return;
   }//if (!IsTradeAllowed() )
      
   //In case any trade closures failed
   if (ArraySize(ForceCloseTickets) > 0)
   {
      MopUpTradeClosureFailures();
      return;
   }//if (ArraySize(ForceCloseTickets) > 0)      
      
   //Rollover
   if (DisableEaDuringRollover)
   {
      RolloverInProgress = false;
      if (AreWeAtRollover())
      {
         RolloverInProgress = true;
         DisplayUserFeedback();
         return;
      }//if (AreWeAtRollover)
   }//if (DisableEaDuringRollover)
         
   //Code to check that there are sufficient bars in the chart's history. Gaheitman provided this. Many thanks George.
   static bool NeedToCheckHistory=false;
   if (NeedToCheckHistory)
   {
        //Customize these for the EA.  You can use externs for the periods 
        //if the user can change the timeframes used.
        //In a multi-currency bot, you'd put the calls in a loop across
        //all pairs
        
        //Customise these to suit what you are doing
        bool WeHaveHistory = true;
        if (!HistoryOK(Symbol(),Period())) WeHaveHistory = false;
        if (!WeHaveHistory)
        {
            Alert("There are <100 bars on this chart so the EA cannot work. It has removed itself. Please refresh your chart.");
            ExpertRemove();
        }//if (!WeHaveHistory)
        
        //if we get here, history is OK, so stop checking
        NeedToCheckHistory=false;
   }//if (NeedToCheckHistory)

   //Spread calculation
   if (!IsTesting() )
   {   
      if(CloseEnough(AverageSpread,0) || RunInSpreadDetectionMode)
      {
         GetAverageSpread();
         ScreenMessage="";
         int left=TicksToCount-CountedTicks;
         //   ************************* added for OBJ_LABEL
         DisplayCount = 1;
         removeAllObjects();
         //   *************************
         SM("Calculating the average spread. "+DoubleToStr(left,0)+" left to count.");
         Comment(ScreenMessage);
         return;
      }//if (CloseEnough(AverageSpread, 0) || RunInSpreadDetectionMode) 
      //Keep the average spread updated
      double spread=(Ask-Bid)*factor;
      if(spread>BiggestSpread) BiggestSpread=spread;//Widest spread since the EA was loaded
      static double SpreadTotal=0;
      static int counter=0;
      SpreadTotal+=spread;
      counter++;
      if(counter>=500)
      {
         AverageSpread=NormalizeDouble(SpreadTotal/counter,1);
         //Save the average for restarts.
         GlobalVariableSet(SpreadGvName,AverageSpread);
         SpreadTotal=0;
         counter=0;
      }//if (counter >= 500)
   }//if (!IsTesting() )
   
   //Create a flashing comment if there has been a rogue trade
   if (RobotSuspended) 
   {
      while (RobotSuspended)
      {
         Comment(NL, Gap, "****************** ROBOT SUSPENDED. POSSIBLE ROGUE TRADING ACTIVITY. REMOVE THIE EA IMMEDIATELY ****************** ");
         Sleep(2000);
         Comment("");
         Sleep(1000);
         if ( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
            return;
      }//while (RobotSuspended)           
      return;
   }//if (RobotSuspended) 

   //If HG is sleeping after a trade closure, is it time to awake?
   TooClose();
   if(SafetyViolation)//TooClose() sets SafetyViolation
   {
      DisplayUserFeedback();
      return;
   }//if (SafetyViolation) 

/*
   People get twitchy when reading the code being removed from the ex4 file warning, so here is a neat method of turning off a function without deleting it, just in case you change your mind and want it later. 
   */
   if(TurnOff==1)
     {
      CalculateTradeProfitInPips(OP_BUY);//TurnOff is never 1, so the function is not called
      CloseEnough(1,1);
      DrawTrendLine("w",0,0,0,0,0,0,0,true);
      DrawHorizontalLine("w",0,0,0,0);
      DrawVerticalLine("w",Red,STYLE_DASH,0);
   }//if (TurnOff == 1) 

   if(OrdersTotal()==0)
   {
      TicketNo=-1;
      ForceTradeClosure=false;
   }//if (OrdersTotal() == 0)

   if(ForceTradeClosure)
   {
      CloseAllTrades(AllTrades);
      return;
   }//if (ForceTradeClosure) 


   //Check for a massive spread widening event and pause the ea whilst it is happening
   if (!IsTesting() )
      CheckForSpreadWidening();

   GetSwap(Symbol());//For the swap filters, and in case crim has changed swap rates

   //New candle. Cancel an existing alert sent. By default, all the email stuff is turned off, so this is probably redundant.
   static datetime OldAlertBarsTime;
   if(OldAlertBarsTime!=iTime(NULL,0,0))
   {
      AlertSent=false;
      OldAlertBarsTime=iTime(NULL,0,0);
   }//if (OldAlertBarsTimeBarsTime != iTime(NULL, 0, 0) )

   //Daily results so far - they work on what in in the history tab, so users need warning that
   //what they see displayed on screen depends on that.   
   //Code courtesy of TIG yet again. Thanks, George.
   static int OldHistoryTotal;
   if(OrdersHistoryTotal()!=OldHistoryTotal)
   {
      CalculateDailyResult();//Does no harm to have a recalc from time to time
      OldHistoryTotal=OrdersHistoryTotal();
   }//if (OrdersHistoryTotal() != OldHistoryTotal)

   ReadIndicatorValues();//This might want moving to the trading section at the end of this function if EveryTickMode = false

   //Delete orphaned tp/sl lines
   static int M15Bars;
   if(M15Bars!=iBars(NULL,PERIOD_M15))
   {
      M15Bars=iBars(NULL,PERIOD_M15);
      DeleteOrphanTpSlLines();
   }//if (M15Bars != iBars(NULL, PERIOD_M15)

///////////////////////////////////////////////////////////////////////////////////
   //Find open trades.
   CountOpenTrades();
//Safety feature. Sometimes an unexpected concatenation of inputs choice and logic error can cause rapid opening-closing of trades. Detect a closed trade and check that is was not a rogue.
   if(OldOpenTrades!=OpenTrades)
   {
      if(IsClosedTradeRogue())
      {
         RobotSuspended=true;
         return;
      }//if (IsClosedTradeRogue() )      
   }//if (OldOpenTrades != OpenTrades)

   OldOpenTrades=OpenTrades;

   //Reset various variables
   if(OpenTrades==0)
   {

   }//if (OpenTrades > 0)

   
   //Lot size based on account size
   if (!CloseEnough(LotsPerDollopOfCash, 0))
      CalculateLotAsAmountPerCashDollops();

///////////////////////////////////////////////////////////////////////////////////

   //Trading times
   TradeTimeOk=CheckTradingTimes();
   if(!TradeTimeOk)
   {
      DisplayUserFeedback();
      Sleep(1000);
      return;
   }//if (!TradeTimeOk)

   //Sunday trading, Monday start time, Friday stop time, Thursday trading
   TradeTimeOk = SundayMondayFridayStuff();
   if (!TradeTimeOk)
   {
      DisplayUserFeedback();
      return;
   }//if (!TradeTimeOk)

///////////////////////////////////////////////////////////////////////////////////

   //Check that there is sufficient margin for trading
   if(!MarginCheck())
   {
      DisplayUserFeedback();
      return;
   }//if (!MarginCheck() )

   
   //Trading
   if(EveryTickMode) OldBarsTime=0;
   if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))
   {
      OldBarsTime = iTime(NULL, TradingTimeFrame, 0);
      //ReadIndicatorValues();//Remember to delete the call higher up in this function if EveryTickMode = false
      if (TimeCurrent() >= TimeToStartTrading)
         if (!StopTrading)
            //if (OpenTrades < MaxTradesAllowed)//Un-comment this line for multi traders. Leave commented 
                                                //for single traders
            if (TicketNo == -1)//Comment out this line for multi-traders. Leave uncomment 
                               //for single traders  
            {
               TimeToStartTrading = 0;//Set to TimeCurrent() + (PostTradeAttemptWaitMinutes * 60) when there is an OrderSend() attempt)
               LookForTradingOpportunities();
            }//if (TicketNo == -1 or if (OpenTrades < MaxTradesAllowed))
   }//if(OldBarsTime!=iTime(NULL,TradingTimeFrame,0))


///////////////////////////////////////////////////////////////////////////////////

   DisplayUserFeedback();

//----
   return;
}
//+------------------------------------------------------------------+
