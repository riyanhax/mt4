//
// MTF HGI Bars.mq4
// Indicator for showing HGI status and signals on multiple timeframes
//
// Copyright 2017 CC BY-NC-SA 3.0, tomele@stevehopwoodforex.com
// Based on the brilliant HGI indicator and library by nanningbob, milanese and elixe (@stevehopwoodforex.com)
//
// This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
// or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
//
// You may use this code or parts of it for your own creations as long as you refer to the original author,
// as long as you use it for non-commercial projects and as long as you facilitate to reuse your creation.
// 

#property copyright "Copyright 2017 CC BY-NC-SA 3.0, tomele@stevehopwoodforex.com"

#property indicator_separate_window
#property indicator_buffers 8

#property indicator_color1 C'0,60,0'
#property indicator_color2 C'80,0,0'
#property indicator_color3 C'0,60,0'
#property indicator_color4 C'80,0,0'
#property indicator_color5 C'0,60,0'
#property indicator_color6 C'80,0,0'
#property indicator_color7 C'0,60,0'
#property indicator_color8 C'80,0,0'

#property indicator_minimum 0.00;
#property indicator_maximum 1.00;
double gap = 0.18;

extern string          c01="===========================================================";
extern string          c02="How many bars back to calculate and how often. '0' means all bars.";
extern string          c03="WARNING: Dont set these too extreme. The indi will become slow.";
extern int             BarsToCalculate=5000;
extern int             RefreshSeconds=60;

extern string          c11="===========================================================";
extern string          c12="The indi shows trend arrows and wavys. It can ignore wavys.";
extern bool            IgnoreBlueWavys=false;
extern bool            IgnoreYellowWavys=false;

extern string          c21="===========================================================";
extern string          c22="Enable/Disable displaying M30 as a higher timeframe.";
extern bool            IgnoreM30Timeframe=true;

extern string          c31="===========================================================";
extern string          c32="Choose fixed lowest timeframe or auto-timeframes (current).";
extern ENUM_TIMEFRAMES LowestTimeframe=PERIOD_CURRENT;

extern string          c41="===========================================================";
extern string          c42="Switch showing the signals on the bars and adjust colors.";
extern bool            ShowSignals=True;
extern color           UpArrowColor=LimeGreen;
extern color           DownArrowColor=Tomato;
extern color           UpWavyColor=LimeGreen;
extern color           DownWavyColor=Tomato;
extern color           RangeWavyColor=Gold;
extern color           TFLabelColor=White;

extern string          c51="===========================================================";
extern string          c52="Switch to alternate signal display (dots) and adjust colors.";
extern bool            ShowSignalsAsDots=True;
extern color           UpArrowDotColor=LimeGreen;
extern color           DownArrowDotColor=Tomato;
extern color           TrendWavyDotColor=DeepSkyBlue;
extern color           RangeWavyDotColor=Gold;

#import "hgi_lib.ex4"
   enum SIGNAL {NONE=0,TRENDUP=1,TRENDDN=2,RANGEUP=3,RANGEDN=4,RADUP=5,RADDN=6};
   enum SLOPE {UNDEFINED=0,RANGEABOVE=1,RANGEBELOW=2,TRENDABOVE=3,TRENDBELOW=4};
   SIGNAL getHGISignal(string symbol,int timeframe,int shift);
   SLOPE getHGISlope (string symbol,int timeframe,int shift);
#import

enum SIGNALS {none=0,arrowup=1,arrowdown=2,wavyup=3,wavydown=4,range=5};

double buf4_up[];
double buf4_down[];
double buf3_up[];
double buf3_down[];
double buf2_up[];
double buf2_down[];
double buf1_up[];
double buf1_down[];

ENUM_TIMEFRAMES period,p1,p2,p3,p4;

int BarsToRecalculate=20;
int ticks=0;

datetime calctime=0;


int OnInit()
{
   IndicatorShortName("MTF HGI Bars by Tomele");
   
   period=LowestTimeframe;
   if (period==PERIOD_CURRENT || period<Period())
      period=(ENUM_TIMEFRAMES)Period();
      
   if (IgnoreM30Timeframe) switch (period)
   {
      case PERIOD_M1:  p1=PERIOD_M1;  p2=PERIOD_M5;  p3=PERIOD_M15; p4=PERIOD_H1;  break;
      case PERIOD_M5:  p1=PERIOD_M5;  p2=PERIOD_M15; p3=PERIOD_H1;  p4=PERIOD_H4;  break;
      case PERIOD_M15: p1=PERIOD_M15; p2=PERIOD_H1;  p3=PERIOD_H4;  p4=PERIOD_D1;  break;
   }
   
   else switch (period)
   {
      case PERIOD_M1:  p1=PERIOD_M1;  p2=PERIOD_M5;  p3=PERIOD_M15; p4=PERIOD_M30; break;
      case PERIOD_M5:  p1=PERIOD_M5;  p2=PERIOD_M15; p3=PERIOD_M30; p4=PERIOD_H1;  break;
      case PERIOD_M15: p1=PERIOD_M15; p2=PERIOD_M30; p3=PERIOD_H1;  p4=PERIOD_H4;  break;
   }

   switch (period)
   {
      case PERIOD_M30: p1=PERIOD_M30; p2=PERIOD_H1;  p3=PERIOD_H4;  p4=PERIOD_D1;  break;
      case PERIOD_H1:  p1=PERIOD_H1;  p2=PERIOD_H4;  p3=PERIOD_D1;  p4=PERIOD_W1;  break;
      case PERIOD_H4:  p1=PERIOD_H4;  p2=PERIOD_D1;  p3=PERIOD_W1;  p4=PERIOD_MN1; break;
      case PERIOD_D1:  p1=PERIOD_D1;  p2=PERIOD_W1;  p3=PERIOD_MN1; p4=0;          break;
      case PERIOD_W1:  p1=PERIOD_W1;  p2=PERIOD_MN1; p3=0;          p4=0;          break;
      case PERIOD_MN1: p1=PERIOD_MN1; p2=0;          p3=0;          p4=0;          break;
   }

   SetIndexStyle(0,DRAW_ARROW,EMPTY,1); SetIndexArrow(0,110); SetIndexEmptyValue(0,100); SetIndexLabel(0,NULL); SetIndexBuffer(0,buf4_up);
   SetIndexStyle(1,DRAW_ARROW,EMPTY,1); SetIndexArrow(1,110); SetIndexEmptyValue(1,100); SetIndexLabel(1,NULL); SetIndexBuffer(1,buf4_down);
   SetIndexStyle(2,DRAW_ARROW,EMPTY,1); SetIndexArrow(2,110); SetIndexEmptyValue(2,100); SetIndexLabel(2,NULL); SetIndexBuffer(2,buf3_up);
   SetIndexStyle(3,DRAW_ARROW,EMPTY,1); SetIndexArrow(3,110); SetIndexEmptyValue(3,100); SetIndexLabel(3,NULL); SetIndexBuffer(3,buf3_down);
   SetIndexStyle(4,DRAW_ARROW,EMPTY,1); SetIndexArrow(4,110); SetIndexEmptyValue(4,100); SetIndexLabel(4,NULL); SetIndexBuffer(4,buf2_up);
   SetIndexStyle(5,DRAW_ARROW,EMPTY,1); SetIndexArrow(5,110); SetIndexEmptyValue(5,100); SetIndexLabel(5,NULL); SetIndexBuffer(5,buf2_down);
   SetIndexStyle(6,DRAW_ARROW,EMPTY,1); SetIndexArrow(6,110); SetIndexEmptyValue(6,100); SetIndexLabel(6,NULL); SetIndexBuffer(6,buf1_up);
   SetIndexStyle(7,DRAW_ARROW,EMPTY,1); SetIndexArrow(7,110); SetIndexEmptyValue(7,100); SetIndexLabel(7,NULL); SetIndexBuffer(7,buf1_down);
   
   DrawLabel(4,p1);
   DrawLabel(3,p2);
   DrawLabel(2,p3);
   DrawLabel(1,p4);
   
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
      if (StringFind(ObjectName(i),"MHB-",0) > -1) 
         ObjectDelete(ObjectName(i));
}


int OnCalculate(const int rates_total, 
                const int prev_calculated, 
                const datetime& time[], 
                const double& open[], 
                const double& high[], 
                const double& low[], 
                const double& close[], 
                const long& tick_volume[], 
                const long& volume[], 
                const int& spread[]) 
{
   int i,maxbar;
   
   if (calctime>TimeCurrent() && ticks>2)
      return(prev_calculated); 
   calctime=TimeCurrent()+RefreshSeconds;
   ticks++;
   
   maxbar=MathMin(Bars-prev_calculated,BarsToCalculate);
   for(i=maxbar-1; i>=0; i--)
      CalcBarHGI(i,BarsToCalculate);
      
   for(i=ObjectsTotal()-1; i>=0; i--)
   {
      if (StringFind(ObjectName(i),"MHB-SIG-1",0)>-1) 
         if (ObjectGet(ObjectName(i),OBJPROP_TIME1)>iTime(NULL,p1,BarsToRecalculate)) 
            ObjectDelete(ObjectName(i));
      if (StringFind(ObjectName(i),"MHB-SIG-2",0)>-1) 
         if (ObjectGet(ObjectName(i),OBJPROP_TIME1)>iTime(NULL,p2,BarsToRecalculate)) 
            ObjectDelete(ObjectName(i));
      if (StringFind(ObjectName(i),"MHB-SIG-3",0)>-1) 
         if (ObjectGet(ObjectName(i),OBJPROP_TIME1)>iTime(NULL,p3,BarsToRecalculate)) 
            ObjectDelete(ObjectName(i));
      if (StringFind(ObjectName(i),"MHB-SIG-4",0)>-1) 
         if (ObjectGet(ObjectName(i),OBJPROP_TIME1)>iTime(NULL,p4,BarsToRecalculate)) 
            ObjectDelete(ObjectName(i));
   }

   for(i=BarsToCalculate; i>=0; i--)
      CalcBarHGI(i,BarsToRecalculate);
   
   if (p1>=Period()) ObjectSet("MHB-LAB-4", OBJPROP_TIME1, iTime(NULL,0,0));
   if (p2>=Period()) ObjectSet("MHB-LAB-3", OBJPROP_TIME1, iTime(NULL,0,0));
   if (p3>=Period()) ObjectSet("MHB-LAB-2", OBJPROP_TIME1, iTime(NULL,0,0));
   if (p4>=Period()) ObjectSet("MHB-LAB-1", OBJPROP_TIME1, iTime(NULL,0,0));
   
   return(rates_total); 
}   


void CalcBarHGI(int i, int max)
{
   SIGNALS h1=none;
   SIGNALS h2=none;
   SIGNALS h3=none;
   SIGNALS h4=none;
   
   int i1=iBarShift(NULL,p1,iTime(NULL,0,i));
   int i2=iBarShift(NULL,p2,iTime(NULL,0,i));
   int i3=iBarShift(NULL,p3,iTime(NULL,0,i));
   int i4=iBarShift(NULL,p4,iTime(NULL,0,i));
   
   int j1=iBarShift(NULL,p1,iTime(NULL,0,i+1));
   int j2=iBarShift(NULL,p2,iTime(NULL,0,i+1));
   int j3=iBarShift(NULL,p3,iTime(NULL,0,i+1));
   int j4=iBarShift(NULL,p4,iTime(NULL,0,i+1));
   
   if (i1<max)
   {
      buf1_down[i]=100; buf1_up[i]=100;
      if (p1!=0 && p1>=Period())
      {
         if (i1!=j1) h1=GetHGI(p1,i1);
         if (h1==arrowup || h1==wavyup) buf1_up[i]=4*gap;
         else if (h1==arrowdown || h1==wavydown) buf1_down[i]=4*gap;
         else if (h1==none) {buf1_up[i]=buf1_up[i+1]; buf1_down[i]=buf1_down[i+1];}
         if (ShowSignals && i1!=j1 && h1!=none) DrawSignal(1,iTime(NULL,0,i),h1);
      }
   }
      
   if (i2<max)
   {
      buf2_down[i]=100; buf2_up[i]=100;
      if (p2!=0 && p2>=Period())
      {
         if (i2!=j2) h2=GetHGI(p2,i2);
         if (h2==arrowup || h2==wavyup) buf2_up[i]=3*gap;
         else if (h2==arrowdown || h2==wavydown) buf2_down[i]=3*gap;
         else if (h2==none) {buf2_up[i]=buf2_up[i+1]; buf2_down[i]=buf2_down[i+1];}
         if (ShowSignals && i2!=j2 && h2!=none) DrawSignal(2,iTime(NULL,0,i),h2);
      }
   }
      
   if (i3<max)
   {
      buf3_down[i]=100; buf3_up[i]=100;
      if (p3!=0 && p3>=Period())
      {
         if (i3!=j3) h3=GetHGI(p3,i3);
         if (h3==arrowup || h3==wavyup) buf3_up[i]=2*gap;
         else if (h3==arrowdown || h3==wavydown) buf3_down[i]=2*gap;
         else if (h3==none) {buf3_up[i]=buf3_up[i+1]; buf3_down[i]=buf3_down[i+1];}
         if (ShowSignals && i3!=j3 && h3!=none) DrawSignal(3,iTime(NULL,0,i),h3);
      }
   }
      
   if (i4<max)
   {
      buf4_down[i]=100; buf4_up[i]=100;
      if (p4!=0 && p4>=Period())
      {
         if (i4!=j4) h4=GetHGI(p4,i4);
         if (h4==arrowup || h4==wavyup) buf4_up[i]=1*gap;
         else if (h4==arrowdown || h4==wavydown) buf4_down[i]=1*gap;
         else if (h4==none) {buf4_up[i]=buf4_up[i+1]; buf4_down[i]=buf4_down[i+1];}
         if (ShowSignals && i4!=j4 && h4!=none) DrawSignal(4,iTime(NULL,0,i),h4);
      }
   }
}


SIGNALS GetHGI(int timeframe, int shift)
{
   SIGNAL signal = 0;
   SLOPE  slope  = 0;
   
   SIGNALS result=0;
   
   signal = getHGISignal(Symbol(), timeframe, shift);
   
   if (!(IgnoreYellowWavys && IgnoreBlueWavys))
      slope = getHGISlope (Symbol(), timeframe, shift);
   
   if (!IgnoreYellowWavys)
      if (slope==RANGEABOVE || slope==RANGEBELOW) result=range;
      
   if (!IgnoreBlueWavys)
      if(slope==TRENDBELOW) result=wavyup;
      else if(slope==TRENDABOVE) result=wavydown;

   if (signal==TRENDUP) result=arrowup;
   else if (signal==TRENDDN) result=arrowdown;
  
   return(result);
}


void DrawLabel(int position, ENUM_TIMEFRAMES timeframe)
{
   string tf;
   switch (timeframe)
   {
      case PERIOD_M1:  tf="M1";  break;
      case PERIOD_M5:  tf="M5";  break;
      case PERIOD_M15: tf="M15"; break;
      case PERIOD_M30: tf="M30"; break;
      case PERIOD_H1:  tf="H1";  break;
      case PERIOD_H4:  tf="H4";  break;
      case PERIOD_D1:  tf="D1";  break;
      case PERIOD_W1:  tf="W1";  break;
      case PERIOD_MN1: tf="MN1"; break;
   }
   
   string name="MHB-LAB-"+IntegerToString(position);
   
   ObjectCreate(name, OBJ_TEXT, ChartWindowFind(), 0,0);
   ObjectSet(name, OBJPROP_FONTSIZE, 8);
   ObjectSet(name, OBJPROP_COLOR, TFLabelColor);
   ObjectSet(name, OBJPROP_BACK, False);
   ObjectSet(name, OBJPROP_PRICE1, position*gap);
   ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetString(0,name, OBJPROP_TEXT, "   "+tf);
}


void DrawSignal(int position, datetime time, int signal)
{
   string symbol;
   color colour;
   
   if (!ShowSignalsAsDots) switch (signal)
   {
      case arrowup:   {symbol="á"; colour=UpArrowColor;   break;}
      case arrowdown: {symbol="â"; colour=DownArrowColor; break;}
      case wavyup:    {symbol="~"; colour=UpWavyColor;    break;}
      case wavydown:  {symbol="~"; colour=DownWavyColor;  break;}
      case range:     {symbol="~"; colour=RangeWavyColor; break;}
   }
   else switch (signal)
   {
      case arrowup:   {symbol="l"; colour=UpArrowDotColor;   break;}
      case arrowdown: {symbol="l"; colour=DownArrowDotColor; break;}
      case wavyup:    {symbol="l"; colour=TrendWavyDotColor; break;}
      case wavydown:  {symbol="l"; colour=TrendWavyDotColor; break;}
      case range:     {symbol="l"; colour=RangeWavyDotColor; break;}
   }   
   
   string font="Wingdings";
   int fontsize=7;
   
   if (symbol=="~") {font="Arial"; fontsize=10;}
   else if (symbol=="l") {fontsize=10;}
   
   string name="MHB-SIG-"+IntegerToString(position)+"-"+IntegerToString(time);
   
   ObjectCreate(name, OBJ_TEXT, ChartWindowFind(), 0,0);
   ObjectSet(name, OBJPROP_FONTSIZE, fontsize);
   ObjectSet(name, OBJPROP_COLOR, colour);
   ObjectSet(name, OBJPROP_BACK, False);
   ObjectSet(name, OBJPROP_TIME1, time);
   ObjectSet(name, OBJPROP_PRICE1, (5-position)*gap);
   ObjectSet(name, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSetString(0,name, OBJPROP_FONT, font);
   ObjectSetString(0,name, OBJPROP_TEXT, symbol);
}
