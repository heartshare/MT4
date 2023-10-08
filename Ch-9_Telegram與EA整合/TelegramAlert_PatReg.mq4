//+------------------------------------------------------------------+
//|                                        TelegramAlert_PatReg.mq4  |
//|                            (Ref)  https://github.com/sholafalana |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict
#include <Telegram.mqh>

//--- input parameters
extern bool AlertonTelegram = true;
extern bool MobileNotification = false;
extern bool EmailNotification = false;

//--- global variables
input string InpChannelName="MT4_difMA_Signal";             //TG的Channel username
input string InpToken="5306239589:AAEZeC6IBCCNFrz5bnn3Vnz2_1zAdVvrpDs";//bot Token
extern string mySigalname = "Pattern Recognizition";

string msgText="";
int Once_counter=0;

CCustomBot bot;
//int macd_handle;
datetime time_signal=0;
bool checked;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   EventSetTimer(300)  ;   //number of seconds
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   EventKillTimer();
   return(0);
  }
  
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_KEYDOWN && lparam=='Q')
  {
   bot.SendMessage(InpChannelName,"ee\nAt:100\nDDDD");
  }
}
    
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   
   bot.Token(InpToken);
   if(!checked)
     {
      if(StringLen(InpChannelName)==0)
        {
         Print("Error: Channel name is empty");
         msgText =StringFormat("bot(%s)@ch(%s)%s\n%s",bot.Name(),InpChannelName,Symbol(),"channel有問題");
         Sleep(10000);
         return (0);
        }

      int result=bot.GetMe();
      
      if(result==0)
        {
         Print("Bot name: ",bot.Name());
         checked=true;
        }
      else
        {
         Print("Error: ",GetErrorDescription(result));
         msgText =StringFormat("bot(%s)@ch(%s)%s\n%s",bot.Name(),InpChannelName,Symbol(),"bot有問題");
         Sleep(10000);
         return(0);
        }

     }
    
    if(Once_counter++==0)  //只執行一次 
      {
       msgText = StringFormat("bot(%s)@ch(%s)%s\n%s",bot.Name(),InpChannelName,Symbol(),"就緒，等待訊號傳送");
       bot.SendMessage(InpChannelName,msgText);
      }
 return(0);
}

void OnTimer()
  {
     static int pre_pattern=-1; //0=Bull ,1=Bear
     int cur_pattern = -1;
     if (IsBullPattern()) cur_pattern =0;   
     if (IsBearPattern()) cur_pattern =1;
     
     //if (!(IsBullPattern()||IsBearPattern())) cur_pattern =-1;
     
     if(!(cur_pattern == pre_pattern))    //不會一直下，pattern改變才動作
     {
      pre_pattern = cur_pattern;
      
      if(cur_pattern==0 )
       {
          msgText="多方型態";         
       } 
       else if (cur_pattern==1)
       {
          msgText= "空方型態";         
       }
      else msgText= "";         

      if (msgText!="")
      {
         msgText =StringFormat("訊號: %s\n品種: %s\nAsk: %s",msgText,Symbol(),DoubleToString(MarketInfo(_Symbol,MODE_BID), Digits));
         //Alert(" IsBullPattern=",IsBullPattern(), " IsBearPattern=",IsBearPattern());PlaySound("alert.wav");    
         
         if(AlertonTelegram){bot.SendMessage(InpChannelName,msgText);}
         if(MobileNotification){SendNotification(msgText);}                
         if(EmailNotification){SendMail("Pattern Notification",msgText);}
      }
    }
 }    

//-- Check for Bullish    //adopted from Pattern_Recognition_Master_v3.mq4
bool IsBullPattern()
{
   bool IsBullPattern=false;
   double Piercing_Line_Ratio = 0;      
   int Piercing_Candle_Length = 0;  
   int Engulfing_Length = 0;
   double Candle_WickBody_Percent = 0;
   double Doji_Star_Ratio = 0;
   double Doji_MinLength = 0;
   double Star_MinLength = 0;
   int CandleLength = 0; 
   int Star_Body_Length = 5; 
   
   Piercing_Line_Ratio = 0.5; //穿透
   Piercing_Candle_Length = 10;
   Engulfing_Length = 0;//吞沒，for period = "M15"
      //Engulfing_Length = 15;//for period = "M30"
      //Engulfing_Length = 25;//for period = "H1"
      //Engulfing_Length = 20;//for period = "H4"
      //Engulfing_Length = 30;//for period = "D1"

   Candle_WickBody_Percent = 0.9;
   CandleLength = 12;
   Doji_Star_Ratio = 0;

   int shift;
   int shift1;
   int shift2;
   int shift3;
   int shift4;
   double O, O1, O2, C, C1, C2, C3, L, L1, L2, L3, H, H1, H2, H3;
   double CL, CL1, CL2, BL, BLa, BL90, UW, LW, BodyHigh, BodyLow;
      shift1 = shift + 1;
      shift2 = shift + 2;
      shift3 = shift + 3;
      shift4 = shift + 4;
      
      O = iOpen(Symbol(), PERIOD_M5,shift1);//Open[shift1]
      O1 = iOpen(Symbol(), PERIOD_M5,shift2);//Open[shift2]
      O2 = iOpen(Symbol(), PERIOD_M5,shift3);//Open[shift3]
      H = iHigh(Symbol(), PERIOD_M5,shift1);//High[shift1];
      H1 = iHigh(Symbol(), PERIOD_M5,shift2);//High[shift2];
      H2 = iHigh(Symbol(), PERIOD_M5,shift3);//High[shift3];
      H3 = iHigh(Symbol(), PERIOD_M5,shift4);//High[shift4];
      L = iLow(Symbol(), PERIOD_M5,shift1);//Low[shift1];
      L1 = iLow(Symbol(), PERIOD_M5,shift2);//Low[shift2];
      L2 = iLow(Symbol(), PERIOD_M5,shift3);//Low[shift3];
      L3 = iLow(Symbol(), PERIOD_M5,shift4);//Low[shift4];
      C = iClose(Symbol(), PERIOD_M5,shift1);//Close[shift1]
      C1 =iClose(Symbol(), PERIOD_M5,shift2);// Close[shift2];
      C2 = iClose(Symbol(), PERIOD_M5,shift3);//Close[shift3];
      C3 = iClose(Symbol(), PERIOD_M5,shift4);//Close[shift4];
      
      if (O>C) { BodyHigh = O; BodyLow = C;  }
      else     { BodyHigh = C; BodyLow = O; }
      
      CL = H1-L1;//High[shift1]-Low[shift1];
      CL1 =H2-L2;//High[shift2]-Low[shift2];
      CL2 =H3-L3;//High[shift3]-Low[shift3];
      BL = O1-C1;//Open[shift1]-Close[shift1];
      UW = H1-BodyHigh;//High[shift1]-BodyHigh;
      LW = BodyLow-L1;//BodyLow-Low[shift1];
      BLa = MathAbs(BL);
      BL90 = BLa * Candle_WickBody_Percent;

      // Check for Bullish 
      if ((L<=L1)&&(L<L2)&&(L<L3))
      {
         IsBullPattern=(
               (((LW/4)>UW)&&(LW>BL90)&&(CL>=(CandleLength*Point))&&(O!=C))        //Bullish Hammer 
            || ((BLa<(Star_Body_Length*Point))&&(!O==C)&&((O2>C2)&&((O2-C2)/(H2-L2)>Doji_Star_Ratio))&&(O1>C1)&&(C>O)&&(CL>=(Star_MinLength*Point)))//Morning Star
            || ((O==C)&&((O2>C2)&&((O2-C2)/(H2-L2)>Doji_Star_Ratio))&&(O1>C1)&&(CL>=(Doji_MinLength*Point)))// Morning Doji Star
            || ((C1<O1)&&(((O1+C1)/2)<C)&&(O<C)&&((C-O)/((H-L))>Piercing_Line_Ratio)&&(CL>=(Piercing_Candle_Length*Point)))//Piercing Line pattern
            || ((O1>C1)&&(C>O)&&(C>=O1)&&(C1>=O)&&((C-O)>(O1-C1))&&(CL>=(Engulfing_Length*Point)))//Bullish Engulfing pattern
            );
      }
	return (IsBullPattern);
}

bool IsBearPattern()
{
   bool IsBearPattern=false;
   double Piercing_Line_Ratio = 0;      
   int Piercing_Candle_Length = 0;  
   int Engulfing_Length = 0;
   double Candle_WickBody_Percent = 0;
   double Doji_Star_Ratio = 0;
   double Doji_MinLength = 0;
   double Star_MinLength = 0;
   int CandleLength = 0; 
   int Star_Body_Length = 5; 
   
   Piercing_Line_Ratio = 0.55; //for period = "H1";
   Piercing_Candle_Length = 10;
   Engulfing_Length = 25;
   Candle_WickBody_Percent = 0.9;
   CandleLength = 12;
   Doji_Star_Ratio = 0;

   int shift;
   int shift1;
   int shift2;
   int shift3;
   int shift4;
   double O, O1, O2, C, C1, C2, C3, L, L1, L2, L3, H, H1, H2, H3;
   double CL, CL1, CL2, BL, BLa, BL90, UW, LW, BodyHigh, BodyLow;
      shift1 = shift + 1;
      shift2 = shift + 2;
      shift3 = shift + 3;
      shift4 = shift + 4;
      
      O = iOpen(Symbol(), PERIOD_M5,shift1);//Open[shift1]
      O1 = iOpen(Symbol(), PERIOD_M5,shift2);//Open[shift2]
      O2 = iOpen(Symbol(), PERIOD_M5,shift3);//Open[shift3]
      H = iHigh(Symbol(), PERIOD_M5,shift1);//High[shift1];
      H1 = iHigh(Symbol(), PERIOD_M5,shift2);//High[shift2];
      H2 = iHigh(Symbol(), PERIOD_M5,shift3);//High[shift3];
      H3 = iHigh(Symbol(), PERIOD_M5,shift4);//High[shift4];
      L = iLow(Symbol(), PERIOD_M5,shift1);//Low[shift1];
      L1 = iLow(Symbol(), PERIOD_M5,shift2);//Low[shift2];
      L2 = iLow(Symbol(), PERIOD_M5,shift3);//Low[shift3];
      L3 = iLow(Symbol(), PERIOD_M5,shift4);//Low[shift4];
      C = iClose(Symbol(), PERIOD_M5,shift1);//Close[shift1]
      C1 =iClose(Symbol(), PERIOD_M5,shift2);// Close[shift2];
      C2 = iClose(Symbol(), PERIOD_M5,shift3);//Close[shift3];
      C3 = iClose(Symbol(), PERIOD_M5,shift4);//Close[shift4];

      if (O>C) { BodyHigh = O; BodyLow = C;  }
      else     { BodyHigh = C; BodyLow = O; }
      
      CL = H1-L1;//High[shift1]-Low[shift1];
      CL1 =H2-L2;//High[shift2]-Low[shift2];
      CL2 =H3-L3;//High[shift3]-Low[shift3];
      BL = O1-C1;//Open[shift1]-Close[shift1];
      UW = H1-BodyHigh;//High[shift1]-BodyHigh;
      LW = BodyLow-L1;//BodyLow-Low[shift1];
      BLa = MathAbs(BL);
      BL90 = BLa * Candle_WickBody_Percent;

      // Check for Bearish 
      if ((H>=H1)&&(H>H2)&&(H>H3))
      {
         IsBearPattern= (
         (((UW/4)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*Point))&&(O!=C))        //Shooting ShootStar 
            ||((BLa<(Star_Body_Length*Point))&&(C2>O2)&&(!O==C)&&((C2-O2)/(H2-L2)>Doji_Star_Ratio)&&(C1>O1)&&(O>C)&&(CL>=(Star_MinLength*Point)))//Evening Star pattern
            ||((O==C)&&((C2>O2)&&(C2-O2)/(H2-L2)>Doji_Star_Ratio)&&(C1>O1)&&(CL>=(Doji_MinLength*Point)))     //Evening Doji Star pattern
            ||(C1>O1)&&(((C1+O1)/2)>C)&&(O>C)&&(C>O1)&&((O-C)/((H-L))>Piercing_Line_Ratio)&&((CL>=Piercing_Candle_Length*Point))//Dark Cloud Cover pattern
            ||((C1>O1)&&(O>C)&&(O>=C1)&&(O1>=C)&&((O-C)>(C1-O1))&&(CL>=(Engulfing_Length*Point)))  //Engulfing pattern
         );
      }
	return (IsBearPattern);
}

