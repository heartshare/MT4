//+------------------------------------------------------------------+
//|                                                 Martingale A.mq4 |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict

extern int MagicNumber=1288;
extern double Lots=0.1;       //起始倉位
extern int ProfitStep = 150;  //$利標，加倉距離

double aryLots[10] ={0.0, 0.1, 0.2,0.4, 0.8, 1.6, 3.2, 6.4, 12.8, 25.6}; 
int consecutive_win =0,  consecutive_loss=0, type_last_win=-1;//連勝，連敗次數，是買或賣

int max_loss[10], max_win[10];
string Name_EA ="Martin";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
 {
   return(INIT_SUCCEEDED);
 }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
 {
 }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(GetLastError() == 134) return;            //(Not enough money)
   double last_LOT=0;                           //前單手數
   double last_WIN_profit=0, last_ordOP_win=0;  //前勝單獲利，前勝單進場價
   int last_ordCT_win =-1, last_ordCT_loss =-1; //平倉時間前:前勝單、前負單
   int type_last_loss =-1;                      //前負單型態
   int Last_number=0;                           //歷史單號
    
// ------  勝敗統計 ------  
   for(int i=0; i <OrdersHistoryTotal(); i++) 
      {
         OrderSelect(i, SELECT_BY_POS,MODE_HISTORY);
         if(OrderSymbol()!= Symbol()) continue;
         if(OrderMagicNumber()!= MagicNumber) continue;
          {
           if(OrderProfit() > 0)
            { 
              consecutive_win  ++;  //連勝次數
              consecutive_loss=0;   
              type_last_win=OrderType() ;
              last_LOT=OrderLots();
              last_WIN_profit=OrderProfit(); 
              last_ordCT_win=OrderCloseTime();
              last_ordOP_win=OrderOpenPrice();
              Last_number=i+1;
             }
           if(OrderProfit() < 0)
            { 
               consecutive_loss ++;    //連敗次數
               consecutive_win=0; 
               type_last_loss=OrderType() ;
               last_LOT = OrderLots();
               last_WIN_profit=OrderProfit();   
               last_ordCT_loss=OrderCloseTime();
               last_ordOP_win=OrderOpenPrice();
               Last_number=i+1;
             }   
            }    
       } 
  
   if(Last_number == 100)  OnDeinit(134);    //下單次數上限100次
   
    if(max_loss[0] < consecutive_loss) max_loss[0]=consecutive_loss; //最大連敗次數
    if(max_win[0] < consecutive_win)  max_win[0]=consecutive_win;    //最大連勝次數
      
       ObjectDelete (Name_EA+"LOSS");
       ObjectCreate (Name_EA+"LOSS", OBJ_LABEL, 0,0,0);
       ObjectSet    (Name_EA+"LOSS", OBJPROP_XDISTANCE, 500);
       ObjectSet    (Name_EA+"LOSS", OBJPROP_YDISTANCE,25);
       ObjectSetText(Name_EA+"LOSS", "連敗次數："+ (string) consecutive_loss +" ，最大連敗次數："+ (string)  max_loss[0], 8, "Arial", Coral);
       
       ObjectsRedraw(); 
       ObjectDelete (Name_EA+"MAX");
       ObjectCreate (Name_EA+"MAX", OBJ_LABEL, 0,0,0);
       ObjectSet    (Name_EA+"MAX", OBJPROP_XDISTANCE, 500);
       ObjectSet    (Name_EA+"MAX", OBJPROP_YDISTANCE,55);
       ObjectSetText(Name_EA+"MAX", "連勝次數："+(string)consecutive_win + " ，最大連勝次數："+(string) max_win[0], 8, "Arial", Yellow);
       ObjectsRedraw(); 

// ------  持倉統計 ------  
 int buy=0, sell=0;
 double profit_buy=0, profit_sell=0;
 int j=-1, i= -1; 
 j=OrdersTotal()-1;
 for (i=j;i>=0;i--)
 {
   if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
   if(OrderMagicNumber()!=MagicNumber) continue;
   if(OrderSymbol()!=Symbol()) continue;
    {  if(OrderType()== OP_BUY){
           buy++; //多單
           profit_buy += OrderProfit();//多倉獲利
         }
         if(OrderType()== OP_SELL){
           sell++;//空單
           profit_sell += OrderProfit();//空倉獲利
          }
    }
 }
    
   string PROFIT_BUY, PROFIT_SELL;
   PROFIT_BUY=DoubleToStr(profit_buy, 0);
   PROFIT_SELL=DoubleToStr(profit_sell, 0);
   ObjectDelete (Name_EA+"profit");
   ObjectCreate (Name_EA+"profit", OBJ_LABEL, 0,0,0);
   ObjectSet    (Name_EA+"profit", OBJPROP_XDISTANCE, 50);
   ObjectSet    (Name_EA+"profit", OBJPROP_YDISTANCE,120);
   ObjectSetText(Name_EA+"profit", " 多倉="+(string)buy+"   "+PROFIT_BUY+" 空倉="+(string)sell+"    "+PROFIT_SELL, 8, "Arial Black", clrMagenta);
   ObjectsRedraw();             

  if(OrdersTotal() == 1 && OrderProfit()>= ProfitStep)
     CloseAll();  //平倉
   else if (OrdersTotal() >= 2 && (profit_buy+profit_sell)>0) 
     CloseAll();  //全部位平倉
  
 if(Last_number == 100)  OnDeinit(134);  //下單次數上限100次

      // --- 馬丁核心模組 ---
      string Label_last_order, genre;
     
      if(last_ordCT_win > last_ordCT_loss)  //前單為勝
        { 
          Label_last_order="(勝)";
          if(type_last_win  == 0){     //前單為買
            genre ="Buy"; 
             Open_Order(OP_BUY,  Lots);
            }
          if(type_last_win  == 1){     //前單為賣
            genre="Sell";
            Open_Order(OP_SELL, Lots);
            }
        }
         
      if(last_ordCT_win < last_ordCT_loss) //前單為敗
        {    
          Label_last_order="(敗)";
          if(type_last_loss == 0){     //前單為買
             genre ="Buy"; 
             Open_Order(OP_SELL, aryLots[consecutive_loss + 1]); }
          if(type_last_loss == 1){     //前單為賣
             genre="Sell"; 
             Open_Order(OP_BUY, aryLots[consecutive_loss + 1]); }
        }     

// ----------    INFO Comment ------------ 
       ObjectDelete (Name_EA+"last_order");
       ObjectCreate (Name_EA+"last_order", OBJ_LABEL, 0,0,0);
       ObjectSet    (Name_EA+"last_order", OBJPROP_XDISTANCE, 50);
       ObjectSet    (Name_EA+"last_order", OBJPROP_YDISTANCE,150);
       ObjectSetText(Name_EA+"last_order", "#"+(string)(Last_number)+"  "+"前單="+ Label_last_order +genre, 8, "Arial Black", clrMagenta);
       ObjectsRedraw(); 
       ObjectDelete (Name_EA+"lots");
       ObjectCreate (Name_EA+"lots", OBJ_LABEL, 0,0,0);
       ObjectSet    (Name_EA+"lots", OBJPROP_XDISTANCE, 50);
       ObjectSet    (Name_EA+"lots", OBJPROP_YDISTANCE,180);
       ObjectSetText(Name_EA+"lots", "加倉距離$=" + (string)ProfitStep  + " 手數 "+(string) aryLots[ consecutive_loss + 1], 8, "Arial Black", clrAqua);
       ObjectsRedraw();   
       
// ------  首單 ------  
       double AO=iAO(NULL,0,1);
       if(OrdersTotal() == 0)
       {
         if(AO > 0) Open_Order(OP_BUY,  Lots);
         if(AO < 0) Open_Order(OP_SELL, Lots);  
       }
  return;
}

// ------ 進場 ------
 int Open_Order(int op_type, double llots)
{
  int ticket=-1;
  if(OrdersTotal() == 0)
  {
   if(op_type == 0)
      {
         while(ticket == -1)
         {
           ticket =OrderSend(Symbol(),OP_BUY, llots,Ask,3, 0, 0, "Long"+consecutive_loss,MagicNumber,0, PaleGreen);
           if(ticket > -1) break;
            else  if(GetLastError() == 134) break;
            else Sleep(10000);
        }   }
        
  if(op_type == 1)
   {
     ticket=-1;
      while(ticket == -1)
       {
         ticket  =OrderSend(Symbol(),OP_SELL,llots,Bid,3,0, 0,"Short"+consecutive_loss,MagicNumber,0, Red);
         if(ticket > -1) break;
          else  if(GetLastError() == 134) break;
          else Sleep(10000);
       }
   }
  }
  return(0);
}

//--------------------------------------------------       
void CloseAll()
{
   bool   Result;
   int    Pos,ErrCode;
   int    Total=OrdersTotal();
   
   if(Total>0)
   {for(int cnt=Total-1; cnt>=0; cnt--) 
     {if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == TRUE) 
       {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
         {
          Pos=OrderType();
           if(Pos==OP_BUY)
           {
              Result=OrderClose(OrderTicket(), OrderLots(), Bid, 0, clrNONE);
           }
           if(Pos==OP_SELL)
           {
              Result=OrderClose(OrderTicket(), OrderLots(), Ask, 0, clrNONE);
           }
           if((Pos==OP_BUYSTOP)||(Pos==OP_SELLSTOP)||(Pos==OP_BUYLIMIT)||(Pos==OP_SELLLIMIT))
           {
              Result=OrderDelete(OrderTicket(), clrNONE);
           }
           
           if(Result!=true)
           {
              ErrCode=GetLastError();
              Print("LastError = ",ErrCode);
           }
           else ErrCode=0;
         }
       }
     }
   }
   return;
}     