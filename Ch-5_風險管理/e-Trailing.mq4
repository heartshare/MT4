//+------------------------------------------------------------------+
//|                                                   e-Trailing.mq4 |
//|            Hang on only one chart                                |
//+------------------------------------------------------------------+

//------- External parameters ------------------------------------------
extern bool   AllPositions  =False;         // Manage all positions
extern bool   ProfitTrailing=True;          // Trawl only profit
extern int    TrailingStop  =15;            // Fixed trawl size
extern int    TrailingStep  =2;             // Trawl step
extern bool   UseSound      =True;          // Use beep
extern string NameFileSound ="expert.wav";  // Sound filename
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
  void start() 
  {
     for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (AllPositions || OrderSymbol()==Symbol()) 
           {
            TrailingPositions();
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Position tracking with a simple drawl                            |
//+------------------------------------------------------------------+
  void TrailingPositions() 
  {
   double pBid, pAsk, pp;
   pp=MarketInfo(OrderSymbol(), MODE_POINT);
     if (OrderType()==OP_BUY) 
     {
      pBid=MarketInfo(OrderSymbol(), MODE_BID);
        if (!ProfitTrailing || (pBid-OrderOpenPrice())>TrailingStop*pp) 
        {
           if (OrderStopLoss()<pBid-(TrailingStop+TrailingStep-1)*pp) 
           {
            ModifyStopLoss(pBid-TrailingStop*pp);
            return;
           }
        }
     }
     if (OrderType()==OP_SELL) 
     {
      pAsk=MarketInfo(OrderSymbol(), MODE_ASK);
        if (!ProfitTrailing || OrderOpenPrice()-pAsk>TrailingStop*pp) 
        {
           if (OrderStopLoss()>pAsk+(TrailingStop+TrailingStep-1)*pp || OrderStopLoss()==0) 
           {
            ModifyStopLoss(pAsk+TrailingStop*pp);
            return;
           }
        }
     }
  }
  
//+------------------------------------------------------------------+
//| Level transfer StopLoss                                          |
//| Parameters:                                                      |
//|   ldStopLoss - level StopLoss                                    |
//+------------------------------------------------------------------+
  void ModifyStopLoss(double ldStopLoss) 
  {
   bool fm;
   fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE);
   if (fm && UseSound) PlaySound(NameFileSound);
  }
//+------------------------------------------------------------------+