//+------------------------------------------------------------------+
//|                                           My_First_Indicator.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red

//---- buffers
double ExtMapBuffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
   string short_name = "我的第一個指標【執行中】";
   IndicatorShortName(short_name);
//----
   return(1);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
   
//---- check for possible errors
   if (counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if (counted_bars>0) counted_bars--;
   
   int    pos=Bars-counted_bars;
   
   double dHigh , dLow , dResult;
   Comment("Hi! 我的第一個指標!");

//---- main calculation loop
   while(pos>=0)
     {
         dHigh = High[pos];
         dLow = Low[pos];
         dResult = dHigh - dLow;
         ExtMapBuffer1[pos]= dResult ;
         pos--;
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+