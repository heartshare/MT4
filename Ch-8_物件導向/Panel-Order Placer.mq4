//+------------------------------------------------------------------+
//|                                           Panel-Order Placer.mq4 |
//+------------------------------------------------------------------+
#property copyright "2022, Findex"
#property link      "meta.msg@gmail.com"
#property version   "1.0"
#property strict

#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\ComboBox.mqh>

input int    OrdCnt=1;  //下單委託數目
input double Lots=0.01; //LOTS
int SL=0;               //止損(pips)，若為0，則採3倍點差 
int TP=0;               //止盈(pips)，若為0，則採5倍點差 
double pips_point; 
string Sym ;
int Spread;

//+------------------------------------------------------------------+
//| DEFINES                                                          |
//+------------------------------------------------------------------+
#define INDENT_LEFT                         (-60)     //左縮（包括邊框寬度）
#define INDENT_TOP                          (11)      //頂縮（包括邊框寬度）
#define INDENT_RIGHT                        (11)      //右縮（包括邊框寬度）
#define INDENT_BOTTOM                       (11)      //底縮（包括邊框寬度）
#define CONTROLS_GAP_X                      (5)       //控件在X軸上的間距
#define CONTROLS_GAP_Y                      (5)       //控件在Y軸上的間距
#define LABEL_WIDTH                         (30)      //文字標籤的寬度(X軸)
#define EDIT_WIDTH                          (55)      //編輯框的寬度(X軸)
#define EDIT_HEIGHT                         (20)      //編輯框的高度(Y軸)
#define BUTTON_WIDTH                        (70)      //按鈕的寬度(X軸)
#define BUTTON_HEIGHT                       (20)      //編輯框的高度(Y軸)

//+------------------------------------------------------------------+
//| CPanelDialog class: main application dialog                      |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
  {
   private:
      //-- ADDITIONAL CONTROLS
      CLabel   ctlLabel_OrdCnt;
      CLabel   ctlLabel_SL;
      CLabel   ctlLabel_Lots;
      CLabel   ctlLabel_TP;
      CLabel   ctlLabel_PAIR;  //品種
      
      CSpinEdit ctlSpinEdit_OrdCnt;
      CEdit    ctlEdit_SL;
      CEdit    ctlEdit_TP;
      CEdit    ctlEdit_Lots;
      
      CButton  ctlButton_SELL;
      CButton  ctlButton_BUY;

      //-- EA下單的參數     
      int iOrdCnt;   //下單數量
      double iLots;  //手數
      int iSL;       //SL
      int iTP;       //TP
      int iPair;     //品種
   
   public:
      CComboBox   ctlComboBox_PAIR; // 下拉選單

      CControlsDialog(void);  //建構函數
      ~CControlsDialog(void); //解構函數
      
      //--- creation 虛擬函數
      virtual bool Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
      
      //--- 圖表事件處理器
      virtual bool OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
      
      //--- 屬性
      void vSetOrdCnt(const int value);
      void vSetSL(const int value);
      void vSetTP(const int value);
      void vSetLots(const double value);
      void vSetPair(const int value);

   
   protected:
      //--- 各控制項的創建函數(方法)
      bool bCreate_Label_OrdCnt(void);
      bool bCreate_Label_SL(void);
      bool bCreate_Label_Lots(void);
      bool bCreate_Label_TP(void);
      bool bCreate_Label_PAIR(void);
      
      bool bCreate_SpinEdit_OrdCnt (void);
      bool bCreate_Edit_SL(void);
      bool bCreate_Edit_Lots(void);
      bool bCreate_Edit_TP(void);
      
      bool bCreate_Button_SELL(void);
      bool bCreate_Button_BUY(void);
            
      bool bCreate_ComboBox_PAIR(void);

      //--- 控制項(controls)的事件處理
      void vOnClick_Button_SELL(void);
      void vOnClick_Button_BUY(void);
      void OnChangeComboBox(void);

      //--- 內部事件處理
      virtual bool  OnResize(void); //面板最小化最大化，將調用類的OnResize方法

};

// ********************************************** //
// *************** EVENT HANDLING *************** //
// ********************************************** //
EVENT_MAP_BEGIN(CControlsDialog)
   ON_EVENT(ON_CLICK,ctlButton_SELL,       vOnClick_Button_SELL)
   ON_EVENT(ON_CLICK,ctlButton_BUY,        vOnClick_Button_BUY)
   ON_EVENT(ON_CHANGE,ctlComboBox_PAIR,OnChangeComboBox)
   
EVENT_MAP_END(CAppDialog)

// ********************************************** //
// *********** CONSTRUCTOR/DESTRUCTOR *********** //
// ********************************************** //
CControlsDialog::CControlsDialog(void) { }
CControlsDialog::~CControlsDialog(void) { }

// ********************************************** //
// ******************* CREATION ***************** //
// ********************************************** //
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2) {

   //--- calling the parent class method
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
      
   // CREATING ADDITIONAL CONTROLS //

   if(!bCreate_Label_OrdCnt())            return(false);
   if(!bCreate_Label_SL())                return(false);
   if(!bCreate_Label_Lots())              return(false);
   if(!bCreate_Label_TP())                return(false);
   if(!bCreate_Label_PAIR())              return(false);
   
   if(!bCreate_SpinEdit_OrdCnt())         return(false);
   if(!bCreate_Edit_SL())                 return(false);
   if(!bCreate_Edit_Lots())               return(false);
   if(!bCreate_Edit_TP())                 return(false);
   
   if(!bCreate_Button_SELL())             return(false);
   if(!bCreate_Button_BUY())              return(false);

   if(!bCreate_ComboBox_PAIR())           return(false);

   return(true);
}

//+----------------------------------------+
//| CREATING THE DISPLAY ELEMENT OrdCnt    |
//+----------------------------------------+
bool CControlsDialog::bCreate_Label_OrdCnt(void)
  {
   // COORDINATES //
   int x1=INDENT_LEFT+5*LABEL_WIDTH+5*CONTROLS_GAP_X;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   // CREATING THE LABEL OrdCnt//
   if(!ctlLabel_OrdCnt.Create(m_chart_id,m_name+"Label_OrdCnt",m_subwin,x1,y1+1,x2,y2))   return(false);
   if(!ctlLabel_OrdCnt.Text("單"))                                                    return(false);
   if(!Add(ctlLabel_OrdCnt))                                                          return(false);

   return(true);
}

//+----------------------------------------+
//| CREATING THE EDIT ELEMENT OrdCnt       |
//+----------------------------------------+
bool CControlsDialog::bCreate_SpinEdit_OrdCnt(void)
  {
   // COORDINATES //
   int x1=INDENT_LEFT+5.5*LABEL_WIDTH+5.5*CONTROLS_GAP_X;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

//--- create
   if(!ctlSpinEdit_OrdCnt.Create(m_chart_id,m_name+"SpinEdit_OrdCnt",m_subwin,x1,y1,x2,y2)) return(false);
   if(!Add(ctlSpinEdit_OrdCnt)) return(false);
   ctlSpinEdit_OrdCnt.MinValue(1);
   ctlSpinEdit_OrdCnt.MaxValue(20);
   ctlSpinEdit_OrdCnt.Value(1);

   return(true);
}

//+----------------------------------------+
//|  CREATING THE DISPLAY ELEMENT SL       |
//+----------------------------------------+
bool CControlsDialog::bCreate_Label_SL(void)
  {
   // COORDINATES //
   int x1=INDENT_LEFT+2*LABEL_WIDTH+2*CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   // CREATING THE LABEL OrdCnt//
   if(!ctlLabel_SL.Create(m_chart_id,m_name+"Label_SL",m_subwin,x1,y1+1,x2,y2))   return(false);
   if(!ctlLabel_SL.Text("SL"))                                                    return(false);
   if(!Add(ctlLabel_SL))                                                          return(false);

   return(true);
}

//+----------------------------------------+
//|  CREATING THE EDIT ELEMENT SL          |
//+----------------------------------------+
bool CControlsDialog::bCreate_Edit_SL(void)
  {
   int x1=INDENT_LEFT+3*LABEL_WIDTH+3*CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlEdit_SL.Create(m_chart_id,m_name+"Edit_SL",m_subwin,x1,y1,x2,y2))  return(false);
   if(!ctlEdit_SL.Text(IntegerToString(SL)))                           return(false);
   if(!ctlEdit_SL.ReadOnly(false))                                           return(false);
   if(!Add(ctlEdit_SL))                                                      return(false);

   return(true);
   }

//+----------------------------------------+
//|  CCREATING THE DISPLAY ELEMENT TP      |
//+----------------------------------------+
bool CControlsDialog::bCreate_Label_TP(void)
  {
   int x1=INDENT_LEFT+5*LABEL_WIDTH+5*CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlLabel_TP.Create(m_chart_id,m_name+"Label_TP",m_subwin,x1,y1+1,x2,y2))   return(false);
   if(!ctlLabel_TP.Text("TP"))                                                    return(false);
   if(!Add(ctlLabel_TP))                                                          return(false);

   return(true);
}

//+----------------------------------------+
//|    CREATING THE EDIT ELEMENT TP        |
//+----------------------------------------+
bool CControlsDialog::bCreate_Edit_TP(void)
  {
   int x1=INDENT_LEFT+5.5*LABEL_WIDTH+5.5*CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlEdit_TP.Create(m_chart_id,m_name+"Edit_TP",m_subwin,x1,y1,x2,y2))  return(false);
   if(!ctlEdit_TP.Text(IntegerToString(TP)))                           return(false);
   if(!ctlEdit_TP.ReadOnly(false))                                           return(false);
   if(!Add(ctlEdit_TP))                                                      return(false);

   return(true);
   }

//+----------------------------------------+
//|    CREATING THE DISPLAY ELEMENT Lots   |
//+----------------------------------------+
bool CControlsDialog::bCreate_Label_Lots(void)
  {
   int x1=INDENT_LEFT+2*LABEL_WIDTH+2*CONTROLS_GAP_X;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlLabel_Lots.Create(m_chart_id,m_name+"Label_Lots",m_subwin,x1,y1+1,x2,y2))   return(false);
   if(!ctlLabel_Lots.Text("手數"))                                                    return(false);
   if(!Add(ctlLabel_Lots))                                                          return(false);

   return(true);
}

//+----------------------------------------+
//|     CREATING THE EDIT ELEMENT Lots     |
//+----------------------------------------+
bool CControlsDialog::bCreate_Edit_Lots(void)
  {
   int x1=INDENT_LEFT+3*LABEL_WIDTH+3*CONTROLS_GAP_X;
   int y1=INDENT_TOP;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlEdit_Lots.Create(m_chart_id,m_name+"Edit_Lots",m_subwin,x1,y1,x2,y2))  return(false);
   if(!ctlEdit_Lots.Text(DoubleToString(Lots)))                           return(false);
   if(!ctlEdit_Lots.ReadOnly(false))                                           return(false);
   if(!Add(ctlEdit_Lots))                                                      return(false);

   return(true);
   }


//+----------------------------------------+
//|        CREATING THE SELL BUTTON        |
//+----------------------------------------+
bool CControlsDialog::bCreate_Button_SELL(void)
  {
   int x1=INDENT_LEFT+2*LABEL_WIDTH+2*CONTROLS_GAP_X;
   int y1=INDENT_TOP+2*EDIT_HEIGHT+2*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlButton_SELL.Create(m_chart_id,"ButtonSELL",m_subwin,x1,y1,x2,y2))   return(false);
   if(!ctlButton_SELL.Text("SELL"))     return(false);
   if(!Add(ctlButton_SELL))             return(false);

   return(true);
  }

//+----------------------------------------+
//|        CREATING THE BUY BUTTON         |
//+----------------------------------------+
bool CControlsDialog::bCreate_Button_BUY(void)
  {
   // COORDINATES //
   int x1=INDENT_LEFT+5*LABEL_WIDTH+5*CONTROLS_GAP_X;
   int y1=INDENT_TOP+2*EDIT_HEIGHT+2*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

//--- create
   if(!ctlButton_BUY.Create(m_chart_id,m_name+"ButtonBUY",m_subwin,x1,y1,x2,y2))  return(false);
   if(!ctlButton_BUY.Text("BUY")) return(false);
   if(!Add(ctlButton_BUY))        return(false);

   return(true);
  }

//+----------------------------------------+
//|CREATING THE DISPLAY ELEMENT SYMBOL標籤 |
//+----------------------------------------+
bool CControlsDialog::bCreate_Label_PAIR(void)
  {
   int x1=INDENT_LEFT+2.5*LABEL_WIDTH+2.5*CONTROLS_GAP_X;
   int y1=INDENT_TOP+3*EDIT_HEIGHT+3*CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlLabel_PAIR.Create(m_chart_id,m_name+"ctlLabel_PAIR",m_subwin,x1,y1+1,x2,y2))   return(false);
   if(!ctlLabel_PAIR.Text("品種"))                                                    return(false);
   if(!Add(ctlLabel_PAIR))                                                          return(false);

   return(true);
}

//+----------------------------------------+
//|   CREATING THE COMBOBOX ELEMENT PAIR   |
//+----------------------------------------+
bool CControlsDialog::bCreate_ComboBox_PAIR(void)
  {
   int x1=INDENT_LEFT+3.5*LABEL_WIDTH+3.5*CONTROLS_GAP_X;
   int y1=INDENT_TOP+3*EDIT_HEIGHT+3*CONTROLS_GAP_Y;
   int x2=x1+EDIT_WIDTH*1.5;
   int y2=y1+EDIT_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!ctlComboBox_PAIR.Create(m_chart_id,"COMBOBOX_PAIR",m_subwin,x1,y1,x2,y2))  return(false);
   if(!Add(ctlComboBox_PAIR))                                                      return(false);
   
   int CntWatchedSymbols=SymbolsTotal(true); //取得市場觀察中的品種數目
   
   string aryWatchSymbol[], symbol;             //字串陣列宣告
   ArrayResize(aryWatchSymbol,CntWatchedSymbols); 

   for(int i=0;i<CntWatchedSymbols;i++)      
      aryWatchSymbol[i]=SymbolName(i,true);  //取出有觀察的品種，陣列第一維註記true

   for(int i=0;i<CntWatchedSymbols;i++) {    //將品種名稱存入字串陣列第二維
		for(int j=i+1;j<CntWatchedSymbols;j++) {
			if(StringCompare(aryWatchSymbol[i],aryWatchSymbol[j],false)>0) {
				symbol = aryWatchSymbol[i];
				aryWatchSymbol[i]=aryWatchSymbol[j];
				aryWatchSymbol[j]=symbol;
			}
		}
	}

   for(int i=0;i<CntWatchedSymbols;i++) { //將品種名稱繫結到下拉選單
      ctlComboBox_PAIR.ItemAdd(aryWatchSymbol[i]);
   }
   ctlComboBox_PAIR.SelectByText(Symbol());

   return(true);
}

//+------------------------------------------------------------------+
//| 設定下單數目值                                                   |
//+------------------------------------------------------------------+
void CControlsDialog::vSetOrdCnt(const int value) {

   iOrdCnt=value;
   ctlSpinEdit_OrdCnt.Value(value);
}

//+------------------------------------------------------------------+
//| 設定SL值                                                         |
//+------------------------------------------------------------------+
void CControlsDialog::vSetSL(const int value) {

   iSL=value;
   ctlEdit_SL.Text(IntegerToString(value));
}

//+------------------------------------------------------------------+
//| 設定 TP 值                                                       |
//+------------------------------------------------------------------+
void CControlsDialog::vSetTP(const int value) {

   iTP=value;
   ctlEdit_TP.Text(IntegerToString(value));
}

//+------------------------------------------------------------------+
//| 設定 手數值                                                      |
//+------------------------------------------------------------------+
void CControlsDialog::vSetLots(const double value) {

   iLots=value;
   ctlEdit_Lots.Text(DoubleToString(value,2));
}
 

//+------------------------------------------------------------------+
//| 設定品種                                                         |
//+------------------------------------------------------------------+
void CControlsDialog::vSetPair(const int value){

   iPair=value;
   ctlComboBox_PAIR.Select(value);
   ChartSetSymbolPeriod(0, ctlComboBox_PAIR.Select(), PERIOD_CURRENT);
}

//+------------------------------------------------------------------+
//| 面版最小化最大化事件處理                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::OnResize(void)
  {
//--- 呼叫父類CAppDialog的方法
   if(!CAppDialog::OnResize()) return(false);

   return(true);
  }

//+------------------------------------------------------------------+
//| 下拉選單事件處理器                                              |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeComboBox(void)
{
   ChartSetSymbolPeriod(0, ctlComboBox_PAIR.Select(), PERIOD_CURRENT);
   Sym=ctlComboBox_PAIR.Select();
   Spread = MarketInfo(Sym,MODE_SPREAD);
   if (SL==0) SL=3*Spread;
   if (TP==0) TP=5*Spread;   
   ExtDialog1.vSetSL(SL);
   ExtDialog1.vSetTP(TP); 
}

//+------------------------------------------------------------------+
//| BUY 按鈕事件處理器                                               |
//+------------------------------------------------------------------+
void CControlsDialog::vOnClick_Button_BUY(void)  {
   double ask = MarketInfo(Sym,MODE_ASK);
   double lots = (double)ObjectGetString(0,m_name+"Edit_Lots",OBJPROP_TEXT);
   
   Sym=ctlComboBox_PAIR.Select();
   Spread = MarketInfo(Sym,MODE_SPREAD);
   if (SL==0) SL=3*Spread;
   if (TP==0) TP=5*Spread;   
   ExtDialog1.vSetSL(SL);
   ExtDialog1.vSetTP(TP); 

   double sl = 0.0;  
   double tp = 0.0;  
   
   pips_point=getPips_point();
   sl = ask-(int)ObjectGetString(0,m_name+"Edit_SL",OBJPROP_TEXT)*pips_point;
   tp = ask+(int)ObjectGetString(0,m_name+"Edit_TP",OBJPROP_TEXT)*pips_point;
   //Print(" Lots=",lots," sl=",sl," tp=",tp);

   int OrdCnt = ctlSpinEdit_OrdCnt.Value();
   for (int i=0;i<OrdCnt;i++) {
     int op_tkt=OrderSend(Sym,OP_BUY,lots,ask,0,sl,tp,"");    
     if(op_tkt<0) Print("OP_BUY failed with error #",_LastError, Error(_LastError),sl,tp);
   }
}

//+------------------------------------------------------------------+
//| SELL 按鈕事件處理器                                              |
//+------------------------------------------------------------------+

void CControlsDialog::vOnClick_Button_SELL(void) {
   double bid = MarketInfo(Sym,MODE_BID);
   double lots = (double)ObjectGetString(0,m_name+"Edit_Lots",OBJPROP_TEXT);  
   Sym=ctlComboBox_PAIR.Select();
   Spread = MarketInfo(Sym,MODE_SPREAD);
   if (SL==0) SL=3*Spread;
   if (TP==0) TP=5*Spread;   
   ExtDialog1.vSetSL(SL);
   ExtDialog1.vSetTP(TP); 

   double sl = 0.0;  
   double tp = 0.0;  
   
   pips_point=getPips_point();
   sl = bid+(int)ObjectGetString(0,m_name+"Edit_SL",OBJPROP_TEXT)*pips_point;
   tp = bid-(int)ObjectGetString(0,m_name+"Edit_TP",OBJPROP_TEXT)*pips_point;
   //Print(" Lots=",lots," sl=",sl," tp=",tp);
   
   int OrdCnt = ctlSpinEdit_OrdCnt.Value();
   for (int i=0;i<OrdCnt;i++) {
      int op_tkt=OrderSend(Sym,OP_SELL,lots,bid,0,sl,tp,"");   
     if(op_tkt<0) Print("OP_SELL failed with error #",_LastError, Error(_LastError),sl,tp);
   }
}


// 全域變數 //
CControlsDialog ExtDialog1;
int counter=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   
   if (ExtDialog1.Name() == NULL)
   {
      if(!ExtDialog1.Create(0,"下單助理",0,Dpi(20),Dpi(20),Dpi(230),Dpi(150)))  // CREATING THE APPLICATION DIALOG //
      {
               Print ("ERROR: GAGAL CREATE");
      }else{
         //--- run application
         ExtDialog1.Run();
      }
   }

   ExtDialog1.vSetOrdCnt(OrdCnt);
   ExtDialog1.vSetLots(Lots);
   ExtDialog1.ctlComboBox_PAIR.SelectByText(Symbol()); //設定下拉選單select到圖表品種
   
   Sym = ExtDialog1.ctlComboBox_PAIR.Select();
   Spread = MarketInfo(Sym,MODE_SPREAD);
   if (SL==0) SL=3*Spread;
   if (TP==0) TP=5*Spread;   
   ExtDialog1.vSetSL(SL);
   ExtDialog1.vSetTP(TP);
   
   return(0);
}

//+------------------------------------------------------------------+
//|  getPips_point 查算平台的交易點數 單位                           |
//+------------------------------------------------------------------+

double getPips_point()
{
   string sym = ExtDialog1.ctlComboBox_PAIR.Select();
   double dp=0;
   if (SymbolInfoInteger(sym,SYMBOL_DIGITS)==3 || SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)==5)
      dp=10;
   else 
      dp=1;   
   double pips_point = MarketInfo(sym,MODE_POINT)*dp;//
   return (pips_point);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if (reason != REASON_CHARTCHANGE) {
      ExtDialog1.Destroy();                               // DESTROYING THE DIALOG
   }
}

// CHART EVENT HANDLER //
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   ExtDialog1.ChartEvent(id,lparam,dparam,sparam);        // HANDLING THE EVENT 
}
//+------------------------------------------------------------------+
//|Dpi：換算圖形化介面的大小以相容於Apple電腦和PC螢幕的解析度差異    |
//+------------------------------------------------------------------+
int Dpi(int Size)
  {
   int screen_dpi=TerminalInfoInteger(TERMINAL_SCREEN_DPI);//192(Mac Retina) vs. 96(PC)
   int base_width=Size;
   int width=(base_width*screen_dpi)/96;
   int scale_factor=(TerminalInfoInteger(TERMINAL_SCREEN_DPI)*100)/96; //---adaptive factor

   width=(base_width*scale_factor)/100;

   return(width);
  } 
  
//+------------------------------------------------------------+
//| 查詢錯誤碼說明，以記錄到日誌                               |
//+------------------------------------------------------------+
string Error(int error_code)
  {
   string error_string;
   switch(error_code)
     {
      case 0:
         error_string="no error returned.";                                                                  break;
      case 1:
         error_string="no error returned, but the result is unknown.";                                       break;
      case 2:
         error_string="common error.";                                                                       break;
      case 3:
         error_string="invalid trade parameters.";                                                           break;
      case 4:
         error_string="trade server is busy.";                                                               break;
      case 5:
         error_string="old version of the client terminal.";                                                 break;
      case 6:
         error_string="no connection with trade server.";                                                    break;
      case 7:
         error_string="not enough rights.";                                                                  break;
      case 8:
         error_string="too frequent requests.";                                                              break;
      case 9:
         error_string="malfunctional trade operation.";                                                      break;
      case 64:
         error_string="account disabled.";                                                                   break;
      case 65:
         error_string="invalid account.";                                                                    break;
      case 128:
         error_string="trade timeout.";                                                                      break;
      case 129:
         error_string="invalid price.";                                                                      break;
      case 130:
         error_string="invalid stops.";                                                                      break;
      case 131:
         error_string="invalid trade volume.";                                                               break;
      case 132:
         error_string="market is closed.";                                                                   break;
      case 133:
         error_string="trade is disabled.";                                                                  break;
      case 134:
         error_string="not enough money.";                                                                   break;
      case 135:
         error_string="price changed.";                                                                      break;
      case 136:
         error_string="off quotes.";                                                                         break;
      case 137:
         error_string="broker is busy.";                                                                     break;
      case 138:
         error_string="requote.";                                                                            break;
      case 139:
         error_string="order is locked.";                                                                    break;
      case 140:
         error_string="long positions only allowed.";                                                        break;
      case 141:
         error_string="too many requests.";                                                                  break;
      case 145:
         error_string="modification denied because an order is too close to market.";                        break;
      case 146:
         error_string="trade context is busy.";                                                              break;
      case 147:
         error_string="expirations are denied by broker.";                                                   break;
      case 148:
         error_string="the amount of opened and pending orders has reached the limit set by a broker.";      break;
      case 4000:
         error_string="no error.";                                                                           break;
      case 4001:
         error_string="wrong function pointer.";                                                             break;
      case 4002:
         error_string="array index is out of range.";                                                        break;
      case 4003:
         error_string="no memory for function call stack.";                                                  break;
      case 4004:
         error_string="recursive stack overflow.";                                                           break;
      case 4005:
         error_string="not enough stack for parameter.";                                                     break;
      case 4006:
         error_string="no memory for parameter string.";                                                     break;
      case 4007:
         error_string="no memory for temp string.";                                                          break;
      case 4008:
         error_string="not initialized string.";                                                             break;
      case 4009:
         error_string="not initialized string in an array.";                                                 break;
      case 4010:
         error_string="no memory for an array string.";                                                      break;
      case 4011:
         error_string="too long string.";                                                                    break;
      case 4012:
         error_string="remainder from zero divide.";                                                         break;
      case 4013:
         error_string="zero divide.";                                                                        break;
      case 4014:
         error_string="unknown command.";                                                                    break;
      case 4015:
         error_string="wrong jump.";                                                                         break;
      case 4016:
         error_string="not initialized array.";                                                              break;
      case 4017:
         error_string="DLL calls are not allowed.";                                                          break;
      case 4018:
         error_string="cannot load library.";                                                                break;
      case 4019:
         error_string="cannot call function.";                                                               break;
      case 4020:
         error_string="EA function calls are not allowed.";                                                  break;
      case 4021:
         error_string="not enough memory for a string returned from a function.";                            break;
      case 4022:
         error_string="system is busy.";                                                                     break;
      case 4050:
         error_string="invalid function parameters count.";                                                  break;
      case 4051:
         error_string="invalid function parameter value.";                                                   break;
      case 4052:
         error_string="string function internal error.";                                                     break;
      case 4053:
         error_string="some array error.";                                                                   break;
      case 4054:
         error_string="incorrect series array using.";                                                       break;
      case 4055:
         error_string="custom indicator error.";                                                             break;
      case 4056:
         error_string="arrays are incompatible.";                                                            break;
      case 4057:
         error_string="global variables processing error.";                                                  break;
      case 4058:
         error_string="global variable not found.";                                                          break;
      case 4059:
         error_string="function is not allowed in testing mode.";                                            break;
      case 4060:
         error_string="function is not confirmed.";                                                          break;
      case 4061:
         error_string="mail sending error.";                                                                 break;
      case 4062:
         error_string="string parameter expected.";                                                          break;
      case 4063:
         error_string="integer parameter expected.";                                                         break;
      case 4064:
         error_string="double parameter expected.";                                                          break;
      case 4065:
         error_string="array as parameter expected.";                                                        break;
      case 4066:
         error_string="requested history data in updating state.";                                           break;
      case 4067:
         error_string="some error in trade operation execution.";                                            break;
      case 4099:
         error_string="end of a file.";                                                                      break;
      case 4100:
         error_string="some file error.";                                                                    break;
      case 4101:
         error_string="wrong file name.";                                                                    break;
      case 4102:
         error_string="too many opened files.";                                                              break;
      case 4103:
         error_string="cannot open file.";                                                                   break;
      case 4104:
         error_string="incompatible access to a file.";                                                      break;
      case 4105:
         error_string="no order selected.";                                                                  break;
      case 4106:
         error_string="unknown symbol.";                                                                     break;
      case 4107:
         error_string="invalid price param.";                                                                break;
      case 4108:
         error_string="invalid ticket.";                                                                     break;
      case 4109:
         error_string="trade is not allowed.";                                                               break;
      case 4110:
         error_string="longs are not allowed.";                                                              break;
      case 4111:
         error_string="shorts are not allowed.";                                                             break;
      case 4200:
         error_string="object already exists.";                                                              break;
      case 4201:
         error_string="unknown object property.";                                                            break;
      case 4202:
         error_string="object does not exist.";                                                              break;
      case 4203:
         error_string="unknown object type.";                                                                break;
      case 4204:
         error_string="no object name.";                                                                     break;
      case 4205:
         error_string="object coordinates error.";                                                           break;
      case 4206:
         error_string="no specified subwindow.";                                                             break;
      case 4207:
         error_string="ERR_SOME_OBJECT_ERROR.";                                                              break;
      default:
         error_string="error is not known.";
     }
   return(error_string);
  } 