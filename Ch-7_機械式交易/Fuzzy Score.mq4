//+------------------------------------------------------------------+
//|                                                 Fuzzy score_.mq4 |
//+------------------------------------------------------------------+

//1) 根據五個指標（Gator、WPR、AC、DeMarker 和 RSI）值進行估算。估計是基於梯形隸屬函數進行的。
//2) 可以直接在代碼中修改屬性的排名和權重。
//3) 不僅可以使用上面指定的指標，還可以使用許多其他指標，作為模糊估計（買入、賣出、不動作）的進出場條件。

#define MAGICMA  6969

double Lots               =  0.1;
extern int TrailingStop          =  35;

extern double SL                 =  60;
bool FirstSL = true;

bool UseMM                       =  true;
extern double PercentMM          =  8;
extern double  DeltaMM           =  0;
extern int     InitialBalance    =  10000;

double LotsOptimized()
   {
      double volume,TempVolume, F;  
      TempVolume=Lots;
      
      if (UseMM) TempVolume =0.00001*(AccountBalance()*(PercentMM+DeltaMM)-InitialBalance*DeltaMM); 
      
      volume=NormalizeDouble(TempVolume,2);
         
      if (volume>MarketInfo(Symbol(),MODE_MAXLOT)) volume=MarketInfo(Symbol(),MODE_MAXLOT);
      if (volume<MarketInfo(Symbol(),MODE_MINLOT)) volume=MarketInfo(Symbol(),MODE_MINLOT);
          
      return (volume);      
   }

int OpenOrders_Count(string symbol)
  {
   int buys=0,sells=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
   if(buys>0) return(buys);
   else       return(-sells);
  }

double FuzzyScore()
  {
      double Gator, Gator2, SumGator, WPR, AC1, AC2, AC3, AC4, AC5, tempAC_b, tempAC_s, DeMarker, RSI, Decision;
      double Rang[5,5], FuzzyScore[5];
      int x, y;
      
      //- Membership definition
      double aryGator[7]    ={10,20,30,40,40,30,20,10};
      double aryWPR[7]      ={-95,-90,-80,-75,-25,-20,-10,-5};
      double aryAC[7]       ={5,4,3,2,2,3,4,5};
      double aryDeMarker[7] ={0.15,0.2,0.25,0.3,0.7,0.75,0.8,0.85};
      double aryRSI[7]      ={25,30,35,40,60,65,70,75};

      double aryWeight[7]   ={0.133,0.133,0.133,0.267,0.333}; //-- 1/15, 1/15, 1/15, 4/15, 5/15
            
      Gator    =iGator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_UPPER,1); 
      Gator2   =iGator(NULL,0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_LOWER,1);       
      SumGator =MathAbs(Gator)+MathAbs(Gator2);
      
      WPR      =iWPR(NULL,0,14,1);      
      DeMarker =iDeMarker(NULL,0,14,1);
      RSI      =iRSI(NULL,0,14,PRICE_CLOSE,1);
      
      AC1      =iAC(NULL,0,1);  //  Bill Williams' Accelerator/Decelerator oscillator 
      AC2      =iAC(NULL,0,2);
      AC3      =iAC(NULL,0,3);
      AC4      =iAC(NULL,0,4);
      AC5      =iAC(NULL,0,5);
            
      ArrayInitialize(Rang,0);
      ArrayInitialize(FuzzyScore,0);
      
//1)=== Gator score ===========================      
      if (SumGator<aryGator[0]){Rang[0,0]=0.5;Rang[0,4]=0.5;}                                                 
      if (SumGator>=aryGator[0] && SumGator<aryGator[1])
               {
                  Rang[0,0]=(1-(SumGator-aryGator[0])/(aryGator[1]-aryGator[0]))/2;
                  Rang[0,1]=(1-Rang[0,0]*2)/2;
                  
                  Rang[0,4]=Rang[0,0];
                  Rang[0,3]=Rang[0,1];
               }
      if (SumGator>=aryGator[1] && SumGator<aryGator[2]){Rang[0,1]=0.5;Rang[0,3]=0.5;}
      if (SumGator>=aryGator[2] && SumGator<aryGator[3])
               {
                  Rang[0,1]=(1-(SumGator-aryGator[2])/(aryGator[3]-aryGator[2]))/2;
                  Rang[0,2]=1-Rang[0,1]*2;
                  Rang[0,3]=Rang[0,1]; 
               }
      if (SumGator>=aryGator[3] || SumGator>=aryGator[4]){Rang[0,2]=1;}      

//2)=== WPR score ============================
      if (WPR<aryWPR[0]){Rang[1,0]=1;}
      if (WPR>=aryWPR[0] && WPR<aryWPR[1])
               {
                  Rang[1,0]=1-(WPR-aryWPR[0])/(aryWPR[1]-aryWPR[0]);
                  Rang[1,1]=1-Rang[1,0];
               }
      if (WPR>=aryWPR[1] && WPR<aryWPR[2]){Rang[1,1]=1;}
      if (WPR>=aryWPR[2] && WPR<aryWPR[3])
               {
                  Rang[1,1]=1-(WPR-aryWPR[2])/(aryWPR[3]-aryWPR[2]);
                  Rang[1,2]=1-Rang[1,1];
               }
      if (WPR>=aryWPR[3] && WPR<aryWPR[4]){Rang[1,2]=1;}
      if (WPR>=aryWPR[4] && WPR<aryWPR[5])
               {
                  Rang[1,2]=1-(WPR-aryWPR[4])/(aryWPR[5]-aryWPR[4]);
                  Rang[1,3]=1-Rang[1,2];
               }
      if (WPR>=aryWPR[5] && WPR<aryWPR[6]){Rang[1,3]=1;}
      if (WPR>=aryWPR[6] && WPR<aryWPR[7])
               {
                  Rang[1,3]=1-(WPR-aryWPR[6])/(aryWPR[7]-aryWPR[6]);                  
                  Rang[1,4]=1-Rang[1,3];                  
               }
      if (WPR>=aryWPR[7]){Rang[1,4]=1;}         

//3)=== AC score ===============================     
      if (AC1<AC2 && AC1<0 && AC2<0){tempAC_b=2;}
      if (AC1<AC2 && AC2<AC3 && AC1<0 && AC2<0 && AC3<0){tempAC_b=3;}
      if (AC1<AC2 && AC2<AC3 && AC3<AC4 && AC1<0 && AC2<0 && AC3<0 && AC4<0){tempAC_b=4;}
      if (AC1<AC2 && AC2<AC3 && AC3<AC4 && AC4<AC5 && AC1<0 && AC2<0 && AC3<0 && AC4<0 && AC5<5){tempAC_b=5;}
      
      if (AC1>AC2 && AC1>0 && AC2>0){tempAC_s=2;}      
      if (AC1>AC2 && AC2>AC3 && AC1>0 && AC2>0 && AC3>0){tempAC_s=3;}
      if (AC1>AC2 && AC2>AC3 && AC3>AC4 && AC1>0 && AC2>0 && AC3>0 && AC4>0){tempAC_s=4;}
      if (AC1>AC2 && AC2>AC3 && AC3>AC4 && AC4>AC5 && AC1>0 && AC2>0 && AC3>0 && AC4>0 && AC5>0){tempAC_s=5;}
      //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      if (tempAC_b==aryAC[0] || tempAC_b==aryAC[1]){Rang[2,0]=1;}      
      if (tempAC_b==aryAC[2] || tempAC_b==aryAC[3]){Rang[2,1]=1;}
      
      if (tempAC_s==aryAC[4] || tempAC_s==aryAC[5]){Rang[2,3]=1;}
      if (tempAC_s==aryAC[6] || tempAC_s==aryAC[7]){Rang[2,4]=1;}      
      
      if (Rang[2,0]==0 && Rang[2,1]==0 && Rang[2,3]==0 && Rang[2,4]==0){Rang[2,2]=1;}

//4)=== DeMarker score ======================
      if (DeMarker<aryDeMarker[0]){Rang[3,0]=1;}
      if (DeMarker>=aryDeMarker[0] && DeMarker<aryDeMarker[1])
               {
                  Rang[3,0]=1-(DeMarker-aryDeMarker[0])/(aryDeMarker[1]-aryDeMarker[0]);
                  Rang[3,1]=1-Rang[3,0];
               }
      if (DeMarker>=aryDeMarker[1] && DeMarker<aryDeMarker[2]){Rang[3,1]=1;}
      if (DeMarker>=aryDeMarker[2] && DeMarker<aryDeMarker[3])
               {
                  Rang[3,1]=1-(DeMarker-aryDeMarker[2])/(aryDeMarker[3]-aryDeMarker[2]);
                  Rang[3,2]=1-Rang[3,1];
               }
      if (DeMarker>=aryDeMarker[3] && DeMarker<aryDeMarker[4]){Rang[3,2]=1;}
      if (DeMarker>=aryDeMarker[4] && DeMarker<aryDeMarker[5])
               {
                  Rang[3,2]=1-(DeMarker-aryDeMarker[4])/(aryDeMarker[5]-aryDeMarker[4]);
                  Rang[3,3]=1-Rang[3,2];
               }
      if (DeMarker>=aryDeMarker[5] && DeMarker<aryDeMarker[6]){Rang[3,3]=1;}
      if (DeMarker>=aryDeMarker[6] && DeMarker<aryDeMarker[7])
               {
                  Rang[3,3]=1-(DeMarker-aryDeMarker[6])/(aryDeMarker[7]-aryDeMarker[6]);
                  Rang[3,4]=1-Rang[3,3];
               }
      if (DeMarker>=aryDeMarker[7]){Rang[3,4]=1;}

//5)=== RSI score ==================
      if (RSI<aryRSI[0]){Rang[4,0]=1;}
      if (RSI>=aryRSI[0] && RSI<aryRSI[1])
               {
                  Rang[4,0]=1-(RSI-aryRSI[0])/(aryRSI[1]-aryRSI[0]);
                  Rang[4,1]=1-Rang[4,0];
               }
      if (RSI>=aryRSI[1] && RSI<aryRSI[2]){Rang[4,1]=1;}
      if (RSI>=aryRSI[2] && RSI<aryRSI[3])
               {
                  Rang[4,1]=1-(RSI-aryRSI[2])/(aryRSI[3]-aryRSI[2]);
                  Rang[4,2]=1-Rang[4,1];
               }
      if (RSI>=aryRSI[3] && RSI<aryRSI[4]){Rang[4,2]=1;}
      if (RSI>=aryRSI[4] && RSI<aryRSI[5])
               {
                  Rang[4,2]=1-(RSI-aryRSI[4])/(aryRSI[5]-aryRSI[4]);
                  Rang[4,3]=1-Rang[4,2];
               }
      if (RSI>=aryRSI[5] && RSI<aryRSI[6]){Rang[4,3]=1;}
      if (RSI>=aryRSI[6] && RSI<aryRSI[7])
               {
                  Rang[4,3]=1-(RSI-aryRSI[6])/(aryRSI[7]-aryRSI[6]);
                  Rang[4,4]=1-Rang[4,3];
               }
      if (RSI>=aryRSI[7]){Rang[4,4]=1;}

//---Fuzzy Score aggregator -------------------
      for(x=0;x<4;x++)
            {
               for(y=0;y<4;y++)
                  {FuzzyScore[x] = FuzzyScore[x] + Rang[y,x] * aryWeight[x];}
                  if (FuzzyScore[x]>1) {Print (FuzzyScore[x]," x=",x);}
            }
      
      for(x=0;x<4;x++)
            {
            Decision = Decision + FuzzyScore[x] * (0.2*(x+1)-0.1);
            }
//-------------------------------
            
      Print("Gator-     ",SumGator,"==",Rang[0,0],"--",Rang[0,1],"--",Rang[0,2],"--",Rang[0,3],"--",Rang[0,4]);
      Print("WPR-       ",WPR,"==",Rang[1,0],"--",Rang[1,1],"--",Rang[1,2],"--",Rang[1,3],"--",Rang[1,4]);
      Print("tempAC_b- ",tempAC_b,"       ","tempAC_s- ",tempAC_s,"    ==",Rang[2,0],"--",Rang[2,1],"--",Rang[2,2],"--",Rang[2,3],"--",Rang[2,4]);
      Print("DeMarker-  ",DeMarker,"==",Rang[3,0],"--",Rang[3,1],"--",Rang[3,2],"--",Rang[3,3],"--",Rang[3,4]);
      Print("RSI-       ",RSI,"==",Rang[4,0],"--",Rang[4,1],"--",Rang[4,2],"--",Rang[4,3],"--",Rang[4,4]);
      
      return(Decision);
  }

void CheckForOpen()
  {   
   int res;
   if(Volume[0]>1) return;  
   
   //Print (FuzzyScore());
   if(FuzzyScore()<0.25)  
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      FirstSL=True;      
      return;
     }

   if(FuzzyScore()>0.75)  
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      FirstSL=True;
      return;
     }
  }
  
void SetStopLoss()
   {
      double StopLoss, TakeProfit;
      int cnt1, err;
      bool tic;
      
      StopLoss=NormalizeDouble(SL*Point,Digits);      
      for(cnt1=0;cnt1<OrdersTotal();cnt1++)
            {
               OrderSelect(cnt1, SELECT_BY_POS, MODE_TRADES);
               if (OrderType()==OP_SELL && OrderStopLoss()!=OrderOpenPrice()+StopLoss && OrderSymbol()==Symbol())
                     {
                        tic=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+StopLoss,0,0,Green);                        
                     }
                if (OrderType()==OP_BUY && OrderStopLoss()!=OrderOpenPrice()-StopLoss && OrderSymbol()==Symbol())
                     {
                        tic=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-StopLoss,0,0,Green);                      
                     }
            }      
   }

void start()
  {
   if(Bars<100 || IsTradeAllowed()==false) return;
   if(OpenOrders_Count(Symbol())==0) CheckForOpen();
   
   if (FirstSL==True) {SetStopLoss();}
   int cnt1;
   
   for(cnt1=0;cnt1<OrdersTotal();cnt1++)
   {
   OrderSelect(cnt1,SELECT_BY_POS);
   if(OrderType()==OP_BUY)
           {
            if(TrailingStop>0)
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  FirstSL=false;
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);}
                 }
              }
           }
         else 
           {           
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  FirstSL=false;
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);}
                 }
              }
           }
          }
  }