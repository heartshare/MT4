//多策略多幣對，交易管理面板，
//將multi-pursuits1.0整合至Trading Panel-Combo.mq4(使用Pairs ComboBox OnChange能切換symbol)
//應用Fibonacci daily pivot, Resistance,Support，aryRS[][8]，Fibonacci Support, Resistances設定TP， 
//TP = getTakeProfit(magic,OrderType(),OrderTakeProfit()+150)來實現
//掛上,exTrailingStop和TrailingStop


#property strict
//Controls =====================
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\CheckBox.mqh>

#define Copyright    "Findex ©2021"
#property copyright  Copyright
#property link      "playhigh@gmail.com"
#import "stdlib.ex4"
#import

extern double  Lots = 0.1;               //單幣種單策略下單手數
//extern double  AllowLots = 0.5;        //(可加碼)手數上限

extern bool    useHeikenAshiMacd= true;   //啟用Heiken Ashi加MACD
extern bool    useZZReturn = true;        //啟用ZZReturn
extern bool    useMaCross = true;         //啟用MaCross
//extern bool    useBBSwing = true;  //啟用BBSwing

extern  int exTrailingStop=100;        // Trailing Stop(pips)
extern  int exTakeProfit=0;            //停利，若設為0，由EA根據Fibonacci ATR調控
extern  int exTrailingProfit=500;      //Trailing Profit start(pips)
extern int TrailingTPStep=100;         //也Trailing Profit step(pips)    
extern  int exmaxSpread=30;            //Max Spread  
extern double  Slippage = 2.5;          //

int    exSlippage=(Digits==5 || Digits==3)?20:2;   //Maximum Slippage 30 pips 
double pips_point = 0.0;
string SymbolInp = "";                 //--for Combo_pair.Select() 傳遞值

extern double  UpdateInterval = 0;     // update orders every x minutes
double LastUpdate = 0;                 // counter used to note time of last update
bool TimerIsEnabled        = false;
int TimerInterval          = 250;

static datetime newAllowed_1, newAllowed_2, newAllowed_3;

extern  double exStopLoss=0;      //Stop Loss(pips)

//string   desc1="========= Trade Line =====";  //=========================
int       InpDepth                = 12;  // Depth
int       InpDeviation            = 5;   // Deviation
int       InpBackstep             = 3;   // Backstep
int       ZigZagNum               = 12;  // Number Of High And Low
color     Color_UPLine            = clrMagenta; // Color Of Sell Line
color     Color_DWLine            = clrAqua;    // Color Of Buy Line

//+------------------------------------------------------------------+
//| Expert Money Managemnet                                          |
//+------------------------------------------------------------------+
extern string mm="=======[Money Management]=======";  //=======[ <Money Management> ]=========
extern  bool   RiskMM=false;   //Risk Management
extern  double RiskPercent=10; //Risk Percentage

//input bool     PositionLock=true;   //允許EA鎖倉
//bool           locked = false;      //flag indicating if whole position locked
//bool           StopTradeFlag = true;
double  aryRS[][9];
static int  aryPre_ZZTurnDn_State[], aryPre_ZZTurnUp_State[];
//double aryExtreme_Loss[];

enum ENUM_Strategies
   {
    HeinkenAshiMacd=1,
    MaCross=2,
    ZZReturn=3
   };
   
enum ENUM_FX_PAIRS
  {
   EURUSDg=1,
   GBPUSDg=2,
   AUDUSDg=3,
   USDCADg=4,
   USDCHFg=5,
   USDJPYg=6
   //EURJPYg=5,
   //EURGBPg=4,
   //NZDUSDg=7,
  }; 
  
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (5)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (5)       // gap by Y coordinate
#define GROUP_WIDTH                         (60)     // size by X coordinate

#define COMBOBOX_WIDTH                      (130)     // size by X coordinate
#define CHECKBOX_WIDTH                      (115)     // size by X coordinate
#define CHECKBOX_HEIGHT                     (36)      // size by Y coordinate
#define BUTTON_WIDTH                        (105)     // size by X coordinate
#define BUTTON_HEIGHT                       (36)      // size by Y coordinate

//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
{
private:
   CButton           m_buttonCloseShort, m_buttonCloseAll, m_buttonCloseLong; 
   CButton           m_buttonTrailShort, m_buttonTrailAll, m_buttonTrailLong; 
   
   CLabel            m_labelShortPos, m_labelLongPos;
   
   CLabel            m_labelShortOrders,m_labelShortLots, m_labelShortProfits;
   CLabel            m_labelLongOrders,m_labelLongLots, m_labelLongProfits;
   
   CLabel            m_labelStrategySymbol1, m_labelStrategySymbol2, m_labelStrategySymbol3, m_labelStrategySymbol4, m_labelStrategySymbol5, m_labelStrategySymbol6, m_labelStrategySymbol99;
//   CLabel            m_labelTotalProfits;
   
   CLabel            m_labelShortProfits_A1, m_labelShortProfits_B1, m_labelShortProfits_C1, m_labelLongProfits_A1, m_labelLongProfits_B1, m_labelLongProfits_C1;
   CLabel            m_labelShortProfits_A2, m_labelShortProfits_B2, m_labelShortProfits_C2, m_labelLongProfits_A2, m_labelLongProfits_B2, m_labelLongProfits_C2;
   CLabel            m_labelShortProfits_A3, m_labelShortProfits_B3, m_labelShortProfits_C3, m_labelLongProfits_A3, m_labelLongProfits_B3, m_labelLongProfits_C3;
   CLabel            m_labelShortProfits_A4, m_labelShortProfits_B4, m_labelShortProfits_C4, m_labelLongProfits_A4, m_labelLongProfits_B4, m_labelLongProfits_C4;
   CLabel            m_labelShortProfits_A5, m_labelShortProfits_B5, m_labelShortProfits_C5, m_labelLongProfits_A5, m_labelLongProfits_B5, m_labelLongProfits_C5;
   CLabel            m_labelShortProfits_A6, m_labelShortProfits_B6, m_labelShortProfits_C6, m_labelLongProfits_A6, m_labelLongProfits_B6, m_labelLongProfits_C6;
   CLabel            m_labelShortProfits_A, m_labelShortProfits_B, m_labelShortProfits_C, m_labelLongProfits_A, m_labelLongProfits_B, m_labelLongProfits_C;
   
   CLabel            m_labelSelectedSymbol;
   
   CComboBox         m_comboPair;
   CCheckBox         m_check_box1;                    
   CCheckBox         m_check_box2;                      
   CCheckBox         m_check_box3;                       

public:
                     CControlsDialog(void);
                    ~CControlsDialog(void);
   //--- create //--- chart event handler
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

   bool              UpdateLabelShortPos(string newText1,string newText2,string newText3);
   bool              UpdateLabelLongPos(string newText1,string newText2,string newText3);

   bool              UpdateLabelPos_1(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_2(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_3(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_4(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_5(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_6(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);
   bool              UpdateLabelPos_99(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6);

   //bool              UpdateLabelShortPos_2(string newText1,string newText2,string newText3);
   //bool              UpdateLabelLongPos_2(string newText1,string newText2,string newText3);

   //bool              UpdateLabelShortPos_3(string newText1,string newText2,string newText3);
   //bool              UpdateLabelLongPos_3(string newText1,string newText2,string newText3);

   bool              UpdateLabelSelectedSymbol(string newText1);
 
protected:

   //--- create dependent controls  //--- handlers of the dependent controls events
   bool              ButtonClosePos(void);
   void              OnClickButtonCloseShort(void);
   void              OnClickButtonCloseAll(void);
   void              OnClickButtonCloseLong(void);

   bool              ButtonTrailProfit(void);
   void              OnClickButtonTrailShort(void);
   void              OnClickButtonTrailAll(void);
   void              OnClickButtonTrailLong(void);
   
   //--- create dependent controls  //--- handlers of the dependent controls events
   bool              CreateLabel(void);
   bool              CreateLabelShortPos(void);
   bool              CreateLabelLongPos(void);
   
   bool              CreateLabelStrategyPos_Pair1(void);
   bool              CreateLabelStrategyPos_Pair2(void);
   bool              CreateLabelStrategyPos_Pair3(void);
   bool              CreateLabelStrategyPos_Pair4(void);
   bool              CreateLabelStrategyPos_Pair5(void);
   bool              CreateLabelStrategyPos_Pair6(void);
   bool              CreateLabelStrategyPos_Pair99(void);
   
   //void              OnClickLabel(void);
   
   bool              CreateCombo(void);
   void              OnChangeComboBox(void);

   bool              CreateCheckBox1(void);
   bool              CreateCheckBox2(void);
   bool              CreateCheckBox3(void);
   void              OnChangeCheckBox1(void);
   void              OnChangeCheckBox2(void);  
   void              OnChangeCheckBox3(void);  
};

//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CHANGE,m_comboPair,OnChangeComboBox)
ON_EVENT(ON_CHANGE,m_check_box1,OnChangeCheckBox1)
ON_EVENT(ON_CHANGE,m_check_box2,OnChangeCheckBox2)
ON_EVENT(ON_CHANGE,m_check_box3,OnChangeCheckBox3)
ON_EVENT(ON_CLICK,m_buttonCloseShort,OnClickButtonCloseShort)
ON_EVENT(ON_CLICK,m_buttonCloseAll,OnClickButtonCloseAll)
ON_EVENT(ON_CLICK,m_buttonCloseLong,OnClickButtonCloseLong)
ON_EVENT(ON_CLICK,m_buttonTrailShort,OnClickButtonTrailShort)
ON_EVENT(ON_CLICK,m_buttonTrailAll,OnClickButtonTrailAll)
ON_EVENT(ON_CLICK,m_buttonTrailLong,OnClickButtonTrailLong)
EVENT_MAP_END(CAppDialog)

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlsDialog::CControlsDialog(void)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlsDialog::~CControlsDialog(void)
{
}

//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
   
   if(!ButtonClosePos())
      return(false);
      
   if(!ButtonTrailProfit())
      return(false);
   
   if(!CreateLabel())
      return(false);
   
   if(!CreateLabelShortPos())
      return(false);
   if(!CreateLabelLongPos())
      return(false);

//========= 
   if(!CreateLabelStrategyPos_Pair1())return(false);
   if(!CreateLabelStrategyPos_Pair2())return(false);
   if(!CreateLabelStrategyPos_Pair3())return(false);
   if(!CreateLabelStrategyPos_Pair4())return(false);
   if(!CreateLabelStrategyPos_Pair5())return(false);
   if(!CreateLabelStrategyPos_Pair6())return(false);
   if(!CreateLabelStrategyPos_Pair99())return(false);

//========= 

   if (!CreateCombo())
      return(false);

   if(!CreateCheckBox1())
      return(false);

   if(!CreateCheckBox2())
      return(false);      
   
      if(!CreateCheckBox3())
      return(false);      
//--- succeed
   return(true);
}

//+------------------------------------------------------------------+
//| Create Button ClosePos                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::ButtonClosePos(void)//m_buttonCloseShort, m_buttonCloseAll, m_buttonCloseLong
{
   int x1=35+INDENT_LEFT+BUTTON_WIDTH;
   int y1=125+ (2*CONTROLS_GAP_Y+BUTTON_HEIGHT)*5;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);
   
   if(!m_buttonCloseShort.Create(m_chart_id,m_name+"CloseShort",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonCloseShort.Text("平空倉"))
      return(false);
   if(!Add(m_buttonCloseShort))
      return(false);
      
   x1=x2+Dpi(CONTROLS_GAP_X);
   x2=x1+Dpi(BUTTON_WIDTH);
   if(!m_buttonCloseAll.Create(m_chart_id,m_name+"CloseAll",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonCloseAll.Text("全平倉"))
      return(false);
   if(!Add(m_buttonCloseAll))
      return(false);   
   
   x1=x2+Dpi(CONTROLS_GAP_X);
   x2=x1+Dpi(BUTTON_WIDTH);
   if(!m_buttonCloseLong.Create(m_chart_id,m_name+"CloseLong",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonCloseLong.Text("平多倉"))
      return(false);
   if(!Add(m_buttonCloseLong))
      return(false);   
   return(true);//--- succeed
}

//+------------------------------------------------------------------+
//| CreateButton  TrailProfit                                        |
//+------------------------------------------------------------------+
bool CControlsDialog::ButtonTrailProfit(void)//m_buttonTrailShort, m_buttonTrailAll, m_buttonTrailLong
{
   int x1=35+INDENT_LEFT+BUTTON_WIDTH;
   int y1=125 + (2*CONTROLS_GAP_Y+BUTTON_HEIGHT)*6;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);
   
   if(!m_buttonTrailShort.Create(m_chart_id,m_name+"TrailShort",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonTrailShort.Text("追盈空"))
      return(false);
   if(!Add(m_buttonTrailShort))
      return(false);
      
   x1=x2+Dpi(CONTROLS_GAP_X);
   x2=x1+Dpi(BUTTON_WIDTH);

   if(!m_buttonTrailAll.Create(m_chart_id,m_name+"TrailAll",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonTrailAll.Text("追盈"))
      return(false);
   if(!Add(m_buttonTrailAll))
      return(false);   
   
   x1=x2+Dpi(CONTROLS_GAP_X);
   x2=x1+Dpi(BUTTON_WIDTH);

   if(!m_buttonTrailLong.Create(m_chart_id,m_name+"TrailLong",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_buttonTrailLong.Text("追盈多"))
      return(false);
   if(!Add(m_buttonTrailLong))
      return(false);   
   return(true);//--- succeed
}

//+------------------------------------------------------------------+
//| Create the "CLabel"  ShortPos, LongPos                           |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabel(void)
{
   int x1=30+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+(CHECKBOX_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+100;
   int y2=y1+20;
/*   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelShortPos.Create(m_chart_id,m_name+"ShortPos",m_subwin,x1,y1,x2,y2))//--- create
      return(false);
      
   if(!m_labelShortPos.Text("【空倉】"))return(false);
   if(!m_labelShortPos.Color(clrOrangeRed))return(false);
   if(!Add(m_labelShortPos))return(false);
   
   x1 = x1+Dpi(170);
   if(!m_labelLongPos.Create(m_chart_id,m_name+"LongPos",m_subwin,x1,y1,x2,y2))
      return(false);
      
   if(!m_labelLongPos.Text("【多倉】"))return(false);
   if(!m_labelLongPos.Color(clrNavy))return(false);
   if(!Add(m_labelLongPos))return(false);
*/   
//----------------------
   x1 = Dpi(20);
   y1 = Dpi(375);
   x2=x1+Dpi(100);
   y2=y1+Dpi(20);
   
   if(!m_labelSelectedSymbol.Create(m_chart_id,m_name+"SelectedSymbol",m_subwin,x1,y1,x2,y2))//--- create
      return(false);
   if(!m_labelSelectedSymbol.Text("【幣種】"))return(false);
   if(!m_labelSelectedSymbol.Color(clrBlue))return(false);
   if(!Add(m_labelSelectedSymbol))return(false);

   return(true);//--- succeed
}

//+------------------------------------------------------------------+
//| Create the "CLabel"  ShortOrders, ShortLots, ShortProfits        |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelShortPos(void)
{
   int x1=5+INDENT_LEFT;
   int y1=INDENT_TOP+(CHECKBOX_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+100;
   int y2=y1+30;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);
   
   x1 = x1+Dpi((COMBOBOX_WIDTH+CONTROLS_GAP_X));
   if(!m_labelShortOrders.Create(m_chart_id,m_name+"ShortOrders",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortOrders.Color(clrMagenta))return(false);
   if(!Add(m_labelShortOrders))return(false);
   
   x1 = x1+Dpi(26);
   if(!m_labelShortLots.Create(m_chart_id,m_name+"ShortLots",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortLots.Color(clrMagenta))return(false);
   if(!Add(m_labelShortLots))return(false);

   x1 = x1+Dpi(75);
   if(!m_labelShortProfits.Create(m_chart_id,m_name+"ShortProfits",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits.Color(clrMagenta))return(false);
   if(!Add(m_labelShortProfits))return(false);

   return(true);//--- succeed
}  

//+---------------------------------------------------------------+
//| Create the "CLabel"  LongOrders, LongLots, LongProfits        |
//+---------------------------------------------------------------+
bool CControlsDialog::CreateLabelLongPos(void)
{
   int x1=200+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+(CHECKBOX_HEIGHT+CONTROLS_GAP_Y);
   int x2=x1+5;
   int y2=y1+30;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongOrders.Create(m_chart_id,m_name+"LongOrders",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongOrders.Color(clrDodgerBlue))return(false);
   if(!Add(m_labelLongOrders))return(false);
   
   x1 = x1+Dpi(26);
   if(!m_labelLongLots.Create(m_chart_id,m_name+"LongtLots",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongLots.Color(clrDodgerBlue))return(false);
   if(!Add(m_labelLongLots))return(false);

   x1 = x1+Dpi(75);
   if(!m_labelLongProfits.Create(m_chart_id,m_name+"LongProfits",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits.Color(clrDodgerBlue))return(false);
   if(!Add(m_labelLongProfits))return(false);

   return(true);//--- succeed
}
//+------------------------------------------------------------+
//| UpdateLabelShortPos                                        |
//+------------------------------------------------------------+
bool CControlsDialog::UpdateLabelShortPos(string newText1,string newText2,string newText3)
  {
//--- update the content
   if(!m_labelShortOrders.Text(string(newText1)))
      return(false);
   if(!m_labelShortLots.Text("("+string(newText2)+")"))
      return(false);
   if(!m_labelShortProfits.Text(string(newText3)))
      return(false);
//--- succeed
   return(true);
  }

//+-----------------------------------------------------------+
//| UpdateLabelLongPos                                        |
//+-----------------------------------------------------------+
bool CControlsDialog::UpdateLabelLongPos(string newText1,string newText2,string newText3)
  {
//--- update the content
   if(!m_labelLongOrders.Text(string(newText1)))
      return(false);
   if(!m_labelLongLots.Text("("+string(newText2)+")"))
      return(false);
   if(!m_labelLongProfits.Text(string(newText3)))
      return(false);
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//| UpdateLabelSelectedSymbol                                        |
//+------------------------------------------------------------------+
bool CControlsDialog::UpdateLabelSelectedSymbol(string newText1)
  {
//--- update the content
   if(!m_labelSelectedSymbol.Text(string(newText1)))
      return(false);
//--- succeed
   return(true);
  }


//--FX Pair #1
bool CControlsDialog::CreateLabelStrategyPos_Pair1(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*2;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

//+---------------------------------------------------------------+
//| Create the "CLabel"  LongOrders, LongLots, LongProfits        |
//+---------------------------------------------------------------+
//---- Pair1 SYMBOL ------------------
   if(!m_labelStrategySymbol1.Create(m_chart_id,m_name+"StrategySymbol1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol1.Text(EnumToString(ENUM_FX_PAIRS(1))))return(false);
   if(!m_labelStrategySymbol1.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol1))return(false);

//----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A1.Create(m_chart_id,m_name+"ShortProfits_A1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A1.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A1))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B1.Create(m_chart_id,m_name+"ShortProfits_B1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B1.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B1))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C1.Create(m_chart_id,m_name+"ShortProfits_C1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C1.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C1))return(false);

//---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*2;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A1.Create(m_chart_id,m_name+"LongProfits_A1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A1.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A1))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B1.Create(m_chart_id,m_name+"LongProfits_B1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B1.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B1))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C1.Create(m_chart_id,m_name+"LongProfits_C1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C1.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C1))return(false);

   return(true);//--- succeed
}

//--FX Pair #2
bool CControlsDialog::CreateLabelStrategyPos_Pair2(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*3;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair2 SYMBOL ------------------
   if(!m_labelStrategySymbol2.Create(m_chart_id,m_name+"StrategySymbol2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol2.Text(EnumToString(ENUM_FX_PAIRS(2))))return(false);
   if(!m_labelStrategySymbol2.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol2))return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A2.Create(m_chart_id,m_name+"ShortProfits_A2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A2.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A2))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B2.Create(m_chart_id,m_name+"ShortProfits_B2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B2.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B2))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C2.Create(m_chart_id,m_name+"ShortProfits_C2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C2.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C2))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*3;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A2.Create(m_chart_id,m_name+"LongProfits_A2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A2.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A2))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B2.Create(m_chart_id,m_name+"LongProfits_B2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B2.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B2))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C2.Create(m_chart_id,m_name+"LongProfits_C2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C2.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C2))return(false);

   return(true);//--- succeed
}

//--FX Pair #3
bool CControlsDialog::CreateLabelStrategyPos_Pair3(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*4;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair3 SYMBOL ------------------
   if(!m_labelStrategySymbol3.Create(m_chart_id,m_name+"StrategySymbol3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol3.Text(EnumToString(ENUM_FX_PAIRS(3))))return(false);
   if(!m_labelStrategySymbol3.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol3))return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A3.Create(m_chart_id,m_name+"ShortProfits_A3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A3.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A3))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B3.Create(m_chart_id,m_name+"ShortProfits_B3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B3.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B3))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C3.Create(m_chart_id,m_name+"ShortProfits_C3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C3.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C3))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*4;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A3.Create(m_chart_id,m_name+"LongProfits_A3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A3.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A3))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B3.Create(m_chart_id,m_name+"LongProfits_B3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B3.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B3))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C3.Create(m_chart_id,m_name+"LongProfits_C3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C3.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C3))return(false);

   return(true);//--- succeed
}

//--FX Pair #4
bool CControlsDialog::CreateLabelStrategyPos_Pair4(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*5;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair4 SYMBOL ------------------
   if(!m_labelStrategySymbol4.Create(m_chart_id,m_name+"StrategySymbol4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol4.Text(EnumToString(ENUM_FX_PAIRS(4))))return(false);
   if(!m_labelStrategySymbol4.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol4))return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A4.Create(m_chart_id,m_name+"ShortProfits_A4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A4.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A4))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B4.Create(m_chart_id,m_name+"ShortProfits_B4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B4.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B4))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C4.Create(m_chart_id,m_name+"ShortProfits_C4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C4.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C4))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*5;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A4.Create(m_chart_id,m_name+"LongProfits_A4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A4.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A4))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B4.Create(m_chart_id,m_name+"LongProfits_B4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B4.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B4))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C4.Create(m_chart_id,m_name+"LongProfits_C4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C4.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C4))return(false);

   return(true);//--- succeed
}

//--FX Pair #5
bool CControlsDialog::CreateLabelStrategyPos_Pair5(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*6;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair5 SYMBOL ------------------
   if(!m_labelStrategySymbol5.Create(m_chart_id,m_name+"StrategySymbol5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol5.Text(EnumToString(ENUM_FX_PAIRS(5))))return(false);
   if(!m_labelStrategySymbol5.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol5))return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A5.Create(m_chart_id,m_name+"ShortProfits_A5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A5.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A5))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B5.Create(m_chart_id,m_name+"ShortProfits_B5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B5.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B5))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C5.Create(m_chart_id,m_name+"ShortProfits_C5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C5.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C5))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*6;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A5.Create(m_chart_id,m_name+"LongProfits_A5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A5.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A5))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B5.Create(m_chart_id,m_name+"LongProfits_B5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B5.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B5))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C5.Create(m_chart_id,m_name+"LongProfits_C5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C5.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C5))return(false);

   return(true);//--- succeed
}

//--FX Pair #6
bool CControlsDialog::CreateLabelStrategyPos_Pair6(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*7;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair6 SYMBOL ------------------
   if(!m_labelStrategySymbol6.Create(m_chart_id,m_name+"StrategySymbol6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelStrategySymbol6.Text(EnumToString(ENUM_FX_PAIRS(6))))return(false);
   if(!m_labelStrategySymbol6.Color(clrForestGreen))return(false);
   if(!Add(m_labelStrategySymbol6))return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A6.Create(m_chart_id,m_name+"ShortProfits_A6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A6.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_A6))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B6.Create(m_chart_id,m_name+"ShortProfits_B6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B6.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_B6))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C6.Create(m_chart_id,m_name+"ShortProfits_C6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C6.Color(clrRed))return(false);
   if(!Add(m_labelShortProfits_C6))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*7;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A6.Create(m_chart_id,m_name+"LongProfits_A6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A6.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_A6))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B6.Create(m_chart_id,m_name+"LongProfits_B6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B6.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_B6))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C6.Create(m_chart_id,m_name+"LongProfits_C6",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C6.Color(clrBlue))return(false);
   if(!Add(m_labelLongProfits_C6))return(false);

   return(true);//--- succeed
}

//--FX Pair #99
bool CControlsDialog::CreateLabelStrategyPos_Pair99(void)
{
   int x1=10+INDENT_LEFT;
   int y1=INDENT_TOP+CHECKBOX_HEIGHT*8;
   int x2=x1+100;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   //---- Pair99 SYMBOL ------------------
   if(!m_labelStrategySymbol99.Create(m_chart_id,m_name+"StrategySymbol99",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_labelStrategySymbol99))return(false);
   if(!m_labelStrategySymbol99.Text("策略統計")) return(false);
   if(!m_labelStrategySymbol99.Color(clrPurple))return(false);
   //if(!ObjectSetText("m_labelStrategySymbol99","策略分計",6,"Times New Roman",clrPurple)) return(false);

   //----Short------------------
   x1 = x1+Dpi(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   if(!m_labelShortProfits_A.Create(m_chart_id,m_name+"ShortProfits_A",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_A.Color(clrDarkViolet))return(false);
   if(!Add(m_labelShortProfits_A))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_B.Create(m_chart_id,m_name+"ShortProfits_B",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_B.Color(clrDarkViolet))return(false);
   if(!Add(m_labelShortProfits_B))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelShortProfits_C.Create(m_chart_id,m_name+"ShortProfits_C",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelShortProfits_C.Color(clrDarkViolet))return(false);
   if(!Add(m_labelShortProfits_C))return(false);

   //---Long------------
    x1=10+INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X)*2+GROUP_WIDTH;
    y1=INDENT_TOP+CHECKBOX_HEIGHT*8;
    x2=x1+5;
    y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_labelLongProfits_A.Create(m_chart_id,m_name+"LongProfits_A",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_A.Color(clrIndigo))return(false);
   if(!Add(m_labelLongProfits_A))return(false);
   
   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_B.Create(m_chart_id,m_name+"LongProfits_B",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_B.Color(clrIndigo))return(false);
   if(!Add(m_labelLongProfits_B))return(false);

   x1 = x1+Dpi(60);
   if(!m_labelLongProfits_C.Create(m_chart_id,m_name+"LongProfits_C",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_labelLongProfits_C.Color(clrIndigo))return(false);
   if(!Add(m_labelLongProfits_C))return(false);

   return(true);//--- succeed
}


//+------------------------------------------------------------------+
bool CControlsDialog::CreateCombo(void)
{
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP;
   int x2=x1+COMBOBOX_WIDTH;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_comboPair.Create(m_chart_id,m_name+"ComboPair",m_subwin,x1,y1,x2,y2))//--- create
      return(false);
   if(!Add(m_comboPair))
      return(false);

   for(int j = EURUSDg; j <= USDJPYg; j++)
   {
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      //int magic=int("1"+string(j));
      
      if(!m_comboPair.ItemAdd(symb))
       return(false);
   }
   m_comboPair.SelectByText(Symbol());
   
   SymbolInp=m_comboPair.Select();
   UpdateLabelSelectedSymbol(m_comboPair.Select());

   m_comboPair.SelectByText(SymbolInp);

   return(true);//--- succeed
}
  
//+------------------------------------------------------------------+
//| Create the "CheckBox" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckBox1(void)
  {
   int x1=INDENT_LEFT+(COMBOBOX_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+CHECKBOX_WIDTH;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_check_box1.Create(m_chart_id,m_name+"CheckBox1",m_subwin,x1,y1,x2,y2)) return(false);//--- create
   if(!m_check_box1.Text("HA.M"))return(false); //策略#1
   if(!m_check_box1.Color(clrDarkViolet))return(false);
   if(!Add(m_check_box1))return(false);
   m_check_box1.Checked(true);
   //Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box1.Checked()));

   return(true);//--- succeed
  }
  
//+------------------------------------------------------------------+
//| Create the "CheckBox2" element                                   |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckBox2(void)
  {
   int x1=INDENT_LEFT+COMBOBOX_WIDTH+CONTROLS_GAP_X+(CHECKBOX_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP;
   int x2=x1+CHECKBOX_WIDTH;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_check_box2.Create(m_chart_id,m_name+"CheckBox2",m_subwin,x1,y1,x2,y2)) return(false);//--- create
   if(!m_check_box2.Text("MA.C"))return(false);  //策略#2
   if(!m_check_box2.Color(clrDarkViolet))return(false);
   if(!Add(m_check_box2))return(false);
   m_check_box2.Checked(true);
   //Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box2.Checked()));

   return(true);//--- succeed
  }  

//+------------------------------------------------------------------+
//| Create the "CheckBox3" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckBox3(void)
  {
   int x1=INDENT_LEFT+COMBOBOX_WIDTH+CONTROLS_GAP_X+(CHECKBOX_WIDTH+CONTROLS_GAP_X)*2;
   int y1=INDENT_TOP;
   int x2=x1+CHECKBOX_WIDTH;
   int y2=y1+CHECKBOX_HEIGHT;
   x1=Dpi(x1);
   y1=Dpi(y1);
   x2=Dpi(x2);
   y2=Dpi(y2);

   if(!m_check_box3.Create(m_chart_id,m_name+"CheckBox3",m_subwin,x1,y1,x2,y2))return(false); //- create
   if(!m_check_box3.Text("ZZ.R")) return(false); //策略#3
   if(!m_check_box3.Color(clrDarkViolet))return(false);
   if(!Add(m_check_box3))return(false);
   m_check_box3.Checked(true);
   //Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box3.Checked()));

   return(true);//--- succeed
  }  

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButtonCloseShort(void)
{
   CloseShortOrders();
}
void CControlsDialog::OnClickButtonCloseAll(void)
{
   CloseShortOrders();
   CloseLongOrders();
}
void CControlsDialog::OnClickButtonCloseLong(void)
{
   CloseLongOrders();
}

void CControlsDialog::OnClickButtonTrailShort(void)
{
   TrailingTakeProfit("Short");
}
void CControlsDialog::OnClickButtonTrailAll(void)
{
   TrailingTakeProfit("");
}
void CControlsDialog::OnClickButtonTrailLong(void)
{
   TrailingTakeProfit("Long");
}

void CControlsDialog::OnChangeComboBox(void)
{
   SymbolInp=m_comboPair.Select();
   UpdateLabelSelectedSymbol(m_comboPair.Select());
   ChartSetSymbolPeriod(0, m_comboPair.Select(), PERIOD_CURRENT);
   m_comboPair.SelectByText(SymbolInp);
}
  
void CControlsDialog::OnChangeCheckBox1(void)
  {
   if (m_check_box1.Checked()){ m_check_box1.Color(clrDarkViolet);useHeikenAshiMacd=true;}
   else
     {
      m_check_box1.Color(clrPlum); 
      useHeikenAshiMacd=false;
     }
     // Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box2.Checked())+" useHeikenAshiMacd=",useHeikenAshiMacd);
  }

void CControlsDialog::OnChangeCheckBox2(void)
  {
   if (m_check_box2.Checked()) {m_check_box2.Color(clrDarkViolet); useMaCross=true;}
   else
     {
     m_check_box2.Color(clrPlum);
     useMaCross=false;
     }
    // Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box1.Checked())+" useMaCross=",useMaCross);
  }  
void CControlsDialog::OnChangeCheckBox3(void)
  {
   if (m_check_box3.Checked()) {m_check_box3.Color(clrDarkViolet); useZZReturn=true;}
   else
     {
     m_check_box3.Color(clrPlum);
     useZZReturn=false;
     }
   //  Comment(__FUNCTION__+" : Checked="+IntegerToString(m_check_box3.Checked())+" useZZReturn=",useZZReturn);
  }  

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CControlsDialog ExtDialog;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
      
//--- create application dialog ExtDialog --------------------
   if (ExtDialog.Name() == NULL)
   {
      if(!ExtDialog.Create(0,"Unity",0,Dpi(40),Dpi(40),Dpi(580),Dpi(550)))
      {
         Print ("ERROR: GAGAL CREATE");
      }else{
         //--- run application
         ExtDialog.Run();
      }
   }

   pips_point = MarketInfo(Symbol(),MODE_POINT); 
   
//--- create Fibonachi ATR --------------------
   for(int j = EURUSDg; j <= USDJPYg; j++)
   {
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      ArrayResize(aryRS,j);
      ArrayResize(aryPre_ZZTurnDn_State,j);
      ArrayResize(aryPre_ZZTurnUp_State,j);
      //ArrayResize(aryExtreme_Loss,j);
      
      double H_d1=iHigh(symb,PERIOD_D1,1);
      double L_d1=iLow(symb,PERIOD_D1,1);
      double C_d1=iClose(symb,PERIOD_D1,1);
       
      double pivot=(H_d1+L_d1+C_d1)/3;
      //double Range=(H_d1-L_d1);
      double range=iATR(symb,PERIOD_D1,3,0)/3 +(H_d1-L_d1)*2/3;      
          
          aryRS[j-1,0]=pivot-range;
          aryRS[j-1,1]=pivot-0.782*range;
          aryRS[j-1,2]=pivot-0.618*range;
          aryRS[j-1,3]=pivot-0.382*range;
          aryRS[j-1,4]=pivot;
          aryRS[j-1,5]=pivot+0.382*range;
          aryRS[j-1,6]=pivot+0.618*range;
          aryRS[j-1,7]=pivot+0.782*range;
          aryRS[j-1,8]=pivot+range;
        
     for(int i=100; i>=0; i--)
     {
        aryPre_ZZTurnDn_State [j-1]= 0;
        aryPre_ZZTurnUp_State [j-1]= 0;
        if (ZZTurnDn_Check(symb,i)>0) {aryPre_ZZTurnDn_State [j-1]= ZZTurnDn_Check(symb,i); break;}
        else 
         if (ZZTurnUp_Check(symb,i)>0){aryPre_ZZTurnUp_State [j-1]= ZZTurnUp_Check(symb,i); break;}
     } 
     
   }
   
   AccTradeInfo();     //-- DisplayAccount&TradeInfo

//---
   ResetLastError();
   
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Week days Agenda                                                 |
//+------------------------------------------------------------------+
extern string WeekDays="===========[ <WEEK DAYS> ]========="; //===========[ <WEEK DAYS> ]=========
extern string exemple = "Hour settings: set to 24 for no limitations";
extern bool   Monday=true;              //Monday Trade
extern int    Monday_Start_Hour =24;    //Monday Start Hour
extern int    Monday_Finish_Hour=24;    //Monday Finish Hour
extern bool   Tuesday=true;             //Tuesday Trade
extern int    Tuesday_Start_Hour =24;   //Tuesday Start Hour
extern int    Tuesday_Finish_Hour=24;   //Tuesday Finish Hour
extern bool   Wednesday=true;           //Wednesday Trade
extern int    Wednesday_Start_Hour =24; //Wednesday Start Hour
extern int    Wednesday_Finish_Hour=24; //Wednesday Finish Hour
extern bool   Thursday=true;            //Thursday Trade
extern int    Thursday_Start_Hour =24;  //Thursday Start Hour
extern int    Thursday_Finish_Hour=24;  //Thursday Finish Hour
extern bool   Friday=true;              //Friday Trade
extern int    Friday_Start_Hour =24;    //Friday Start Hour
extern int    Friday_Finish_Hour=24;    //Friday Finish Hour

//+------------------------------------------------------------------+
//| Functions and procedures and sequences                           |
//+------------------------------------------------------------------+
void in(string a) {}

//+------------------------------------------------------------------+
//| Class EA                                                         |
//+------------------------------------------------------------------+
class EA
  {
public:
//   bool              flipme;
   double            maxspread;
   bool              M;
   int               Ms,Mf;
   bool              T;
   int               Ts,Tf;
   bool              W;
   int               Ws,Wf;
   bool              TH;
   int               THs,THf;
   bool              F;
   int               Fs,Ff;
   double            StopLoss,TakeProfit,Lots,TrailingProfit,TrailingStop;
   int               Slippage,Magic;
   string            Comt;
   string            Sym;
   bool              TL;
   bool              TS;
   bool              TCL;
   bool              TCS;
   int               LongTicket;
   int               ShortTicket;
   int               PreviousTime;
   bool              RManagement;
   double            RPercent;
   void              EA();
   void             ~EA();
   double            PipsToDecimal(double Pips);

   int               Buy(int magic);//, string comment
   int               Sell(int magic);//, string comment
   void              CloseBuy(int magic);
   void              CloseSell(int magic);

   double            getTakeProfit(int magic,int type, double OpenPrice);
   void              DoLongTrailingStop(int Ticket);
   void              DoShortTrailingStop(int Ticket);

   void              Trade(int magict,bool a,bool b,bool c,bool d);//,string commen

   bool              TimeDayOk();
   double            CalculateLots();
   double            CountPositions(string strSymbol, int intMagic, int Type);
   //string            getComment(string strSymbol, int intMagic, int Type);
   
   void              Create(double ALots,
                            int ASlippage,
                            string AComment,
                            int AMagic,
                            //bool flipme,
                            bool rm,double rp,
                            string APSymbol,
                            double AStopLoss,
                            double ATakeProfit,
                            double ATrailingProfit,
                            double ATrailingStop,
                            double mxspread,
                            bool M__,
                            int Ms__,int Mf__,
                            bool T__,
                            int Ts__,int Tf__,
                            bool W__,
                            int Ws__,int Wf__,
                            bool TH__,
                            int THs__,int THf__,
                            bool F__,
                            int Fs__,int Ff__);
  };
  
//+------------------------------------------------------------------+
//| EA create, the "constructor"                                     |
//+------------------------------------------------------------------+
void EA::Create(double ALots,
                int ASlippage,
                string AComment,
                int AMagic,
                //bool flipflop,
                bool rm,
                double rp,
                string APSymbol,
                double AStopLoss,
                double ATakeProfit,
                double ATrailingProfit,
                double ATrailingStop,
                double mxspread,
                bool M__,int Ms__,int Mf__,
                bool T__,int Ts__,int Tf__,
                bool W__,int Ws__,int Wf__,
                bool TH__,int THs__,int THf__,
                bool F__,int Fs__,int Ff__)
  {
   Lots=ALots;
   Slippage=ASlippage;
   Comt=AComment;
   Magic=AMagic;
   Sym=APSymbol;
   StopLoss=(AStopLoss>0)?PipsToDecimal(AStopLoss):0;
   TakeProfit=(ATakeProfit>0)?PipsToDecimal(ATakeProfit):0;
   TrailingProfit=(ATrailingProfit>0)?PipsToDecimal(ATrailingProfit):0;  //=====check it!!
   TrailingStop=(ATrailingStop>0)?PipsToDecimal(ATrailingStop):0;

   TL = false;
   TS = false;
   TCL = false;
   TCS = false;
   LongTicket=-1;
   ShortTicket=-1;
   PreviousTime=0;
   M=M__; Ms = Ms__; Mf = Mf__;
   T=T__; Ts = Ts__;Tf = Tf__;
   W=W__; Ws = Ws__; Wf = Wf__;
   TH = TH__; THs = THs__; THf = THf__;
   F=F__; Fs = Fs__; Ff = Ff__;
   maxspread=mxspread;
   RManagement=rm;
   RPercent=rp;
   //flipme=flipflop;
  }
    
//+------------------------------------------------------------------+
//| EA Constructor                                                   |
//+------------------------------------------------------------------+
void EA::EA()
  {
  }
  
//+------------------------------------------------------------------+
//| EA Destructor                                                    |
//+------------------------------------------------------------------+
void EA::~EA()
  {
  }
  
//+---------------------------------------------------------+
//| (Method) CountPositions                                 |
//+---------------------------------------------------------+
double EA::CountPositions(string strSymbol, int intMagic, int Type)
  {
   double _CountPosition=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      int o=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==strSymbol && OrderMagicNumber()==intMagic && OrderType()==Type )
        {
         _CountPosition+=OrderLots();
        }
     }
   return(_CountPosition);
  }
  
/*//+---------------------------------------------------------+
//| (Method) getComment                                 |
//+---------------------------------------------------------+
string EA::getComment(string strSymbol, int intMagic, int Type)
  {
   string _Comment="";
   for(int i=0;i<OrdersTotal();i++)
     {
      int o=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==strSymbol && OrderMagicNumber()==intMagic && OrderType()==Type )
        {
         _Comment=OrderComment();
        }
     }
   return(_Comment);
  }*/
  
bool  EA::TimeDayOk()
  {
//+------------------------------------------------------------------+
//| Monday                                                           |
//+------------------------------------------------------------------+
   if((DayOfWeek() == MONDAY && M))
     {
      int Start_Hour=Ms;
      int Finish_Hour=Mf;
      double Current_Time=TimeHour(TimeCurrent());
      if(Start_Hour==0) Start_Hour=24; if(Finish_Hour==0) Finish_Hour=24; if(Current_Time==0) Current_Time=24;
      if(Start_Hour<Finish_Hour)
         if( (Current_Time < Start_Hour) || (Current_Time >= Finish_Hour) ) return(false);
      if(Start_Hour>Finish_Hour)
         if( (Current_Time < Start_Hour) && (Current_Time >= Finish_Hour) ) return(false);
      return(true);
     }
//+------------------------------------------------------------------+
//| Tuesday                                                          |
//+------------------------------------------------------------------+
   if((DayOfWeek() == TUESDAY && T))
     {
      int Start_Hour=Ts;
      int Finish_Hour=Tf;
      double Current_Time=TimeHour(TimeCurrent());
      if(Start_Hour==0) Start_Hour=24; if(Finish_Hour==0) Finish_Hour=24; if(Current_Time==0) Current_Time=24;
      if(Start_Hour<Finish_Hour)
         if( (Current_Time < Start_Hour) || (Current_Time >= Finish_Hour) ) return(false);
      if(Start_Hour>Finish_Hour)
         if( (Current_Time < Start_Hour) && (Current_Time >= Finish_Hour) ) return(false);
      return(true);
     }
//+------------------------------------------------------------------+
//| Wednesday                                                        |
//+------------------------------------------------------------------+
   if((DayOfWeek() == WEDNESDAY && W))
     {
      int Start_Hour=Ws;
      int Finish_Hour=Wf;
      double Current_Time=TimeHour(TimeCurrent());
      if(Start_Hour==0) Start_Hour=24; if(Finish_Hour==0) Finish_Hour=24; if(Current_Time==0) Current_Time=24;
      if(Start_Hour<Finish_Hour)
         if( (Current_Time < Start_Hour) || (Current_Time >= Finish_Hour) ) return(false);
      if(Start_Hour>Finish_Hour)
         if( (Current_Time < Start_Hour) && (Current_Time >= Finish_Hour) ) return(false);
      return(true);
     }
//+------------------------------------------------------------------+
//| Thursday                                                         |
//+------------------------------------------------------------------+
   if((DayOfWeek() == THURSDAY && TH))
     {
      int Start_Hour=THs;
      int Finish_Hour=THf;
      double Current_Time=TimeHour(TimeCurrent());
      if(Start_Hour==0) Start_Hour=24; if(Finish_Hour==0) Finish_Hour=24; if(Current_Time==0) Current_Time=24;
      if(Start_Hour<Finish_Hour)
         if( (Current_Time < Start_Hour) || (Current_Time >= Finish_Hour) ) return(false);
      if(Start_Hour>Finish_Hour)
         if( (Current_Time < Start_Hour) && (Current_Time >= Finish_Hour) ) return(false);
      return(true);
     }
//+------------------------------------------------------------------+
//| Friday                                                           |
//+------------------------------------------------------------------+
   if((DayOfWeek() == FRIDAY && F))
     {
      int Start_Hour=Fs;
      int Finish_Hour=Ff;
      double Current_Time=TimeHour(TimeCurrent());
      if(Start_Hour==0) Start_Hour=24; if(Finish_Hour==0) Finish_Hour=24; if(Current_Time==0) Current_Time=24;
      if(Start_Hour<Finish_Hour)
         if( (Current_Time < Start_Hour) || (Current_Time >= Finish_Hour) ) return(false);
      if(Start_Hour>Finish_Hour)
         if( (Current_Time < Start_Hour) && (Current_Time >= Finish_Hour) ) return(false);
      return(true);
     }

//very important
   return false;
  }
  
//+---------------------------------------+
//|      Trade                            |
//+---------------------------------------+
void EA::Trade(int magic,bool TL1,bool TS1,bool TCL1,bool TCS1)//,string comment
  {
   TL  =  TL1;  //Trade Long
   TS  =  TS1;  //Trade Short
   TCL =  TCL1; //Trade Close Long
   TCS =  TCS1; //Trade Close Short
   
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(TCL && (OrderMagicNumber()== magic) && (OrderType()==OP_BUY) ) CloseBuy(magic);//&& OrderProfit()>0
      if(TCS && (OrderMagicNumber()== magic) && (OrderType()==OP_SELL)) CloseSell(magic);//&& OrderProfit()>0
     }
   
   if(TL)
     {
      if(TimeDayOk() && MarketInfo(Sym,MODE_SPREAD)<=maxspread)
         LongTicket=Buy(magic);  //, comment
     }

   if(TS)
     {
      if(TimeDayOk() && MarketInfo(Sym,MODE_SPREAD)<=maxspread)
         ShortTicket=Sell(magic); //, comment
     }
     
   //--- 呼叫getTakeProfit()，設定OrderTakeProfit()及TrailingProfit ----
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()== magic)
      {
       double tp = 0;
       string txt=""; //- prompt messenge
         
         if (OrderType()==OP_BUY)
         {
            if (OrderTakeProfit()==0.0)   
               {tp = getTakeProfit(magic,OrderType(),OrderOpenPrice()+50*pips_point);
                txt= txt+" ... Long Order modifying Zero tp";}
            else if(!TS && (MarketInfo(Sym, MODE_BID) < OrderTakeProfit()&&(OrderTakeProfit() - MarketInfo(Sym, MODE_BID))< 50*pips_point))
               {tp = getTakeProfit(magic,OP_BUY,OrderTakeProfit()+150*pips_point);
                txt= txt+" >>> Long Position Trailing tp";
               }
         }
         else if (OrderType()==OP_SELL)
            {
            if (OrderTakeProfit()==0.0)
               {tp = getTakeProfit(magic,OrderType(),OrderOpenPrice()-50*pips_point);
                txt= txt+" ... Short Order modifying Zero tp";}
            else if(!TL && (MarketInfo(Sym, MODE_ASK) > OrderTakeProfit() && (MarketInfo(Sym, MODE_ASK)-OrderTakeProfit()) < 50*pips_point))
               {tp = getTakeProfit(magic,OP_SELL,OrderTakeProfit()-150*pips_point);   
                txt= txt+" >>> Short Position Trailing tp";}
             }
         
         bool modSuceed;
         if ( tp>0 && (MathAbs(tp-OrderOpenPrice())> MarketInfo(Sym,MODE_SPREAD)*pips_point) && (MathAbs(tp-OrderTakeProfit())> MarketInfo(Sym,MODE_SPREAD)*pips_point))//- tp要大於0且獲利要高於spread
             modSuceed=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tp,0,clrMagenta);
         
         if (modSuceed) Print(OrderTicket(),txt,"--SUCCEED"," magic=",magic, " tp=",tp);
         //else Print(OrderTicket(),txt," FAILED"," magic=",magic, " tp=",tp);
      
      //if (magic==11)
      /*if (tp!=0)
      {
         //if (OrderType()==OP_BUY)
         Print(" 【magic】=",magic, OrderSymbol()," ",OrderType()," OrderTakeProfit()=",OrderTakeProfit(), " 【tp】=",tp
         ,"  【DIF(pips)】 = ",MathAbs((OrderTakeProfit() - tp)/pips_point)," spread=",MarketInfo(Sym,MODE_SPREAD));
         //if (OrderType()==OP_SELL)
         //Print(OrderSymbol()," ",OrderType()," OrderTakeProfit()=",OrderTakeProfit(), " 【tp】=",tp);
         //,"  >>>>DIF = ",(OrderTakeProfit() - MarketInfo(Sym, MODE_ASK))," 50*pips_point=",50*pips_point);
      }*/
      
      }
     }
     
   if(LongTicket>-1)  DoLongTrailingStop(LongTicket);
   if(ShortTicket>-1) DoShortTrailingStop(ShortTicket);
  }
  
//+------------------------------------------------------------------+
//| (Method)Pips to decimal for all digits broker                    |
//+------------------------------------------------------------------+
double EA::PipsToDecimal(double Pips)
  {
   double ThePoint=SymbolInfoDouble(Sym,SYMBOL_POINT);
   if(ThePoint==0.0001 || ThePoint==0.00001)
     {
      return Pips * 0.0001;
     }
   else if(ThePoint==0.01 || ThePoint==0.001)
     {
      return Pips * 0.01;
     }
   else
     {
      return 0;
     }
  }
  
//+------------------------------------------------------------------+
//| (Method)CalculateLots on rrisk and money   managements           |
//+------------------------------------------------------------------+
double EA::CalculateLots()
  {
//+------------------------------------------------------------------+
//| Return default lot size if no money management                   |
//+------------------------------------------------------------------+
   if(!RManagement)
     {
      if(Lots<MarketInfo(Sym,MODE_MINLOT))
        { return MarketInfo(Sym,MODE_MINLOT); }

      if(Lots>MarketInfo(Sym,MODE_MAXLOT))
        { return MarketInfo(Sym,MODE_MAXLOT); }
      return Lots;
     }

   else// Calcute Lots With Risk Management 
     {
      double lottoreturn=0;
      double MinLots=MarketInfo(Sym,MODE_MINLOT);
      double MaxLots=MarketInfo(Sym,MODE_MAXLOT);
      lottoreturn=AccountFreeMargin()/100000*RPercent;
      lottoreturn=MathMin(MaxLots,MathMax(MinLots,lottoreturn));
      if(MinLots<0.1)lottoreturn=NormalizeDouble(lottoreturn,2);
      else
        {
         if(MinLots<1)lottoreturn=NormalizeDouble(lottoreturn,1);
         else lottoreturn=NormalizeDouble(lottoreturn,0);
        }
      if(lottoreturn<MinLots) Lots = MinLots;
      if(lottoreturn>MaxLots) Lots = MaxLots;
      return(lottoreturn);
     }
   return Lots;
  }
  
//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
int EA::Buy(int magic)//, string comment
  {
   PreviousTime=(int)TimeMinute(TimeLocal());
   double SL = (StopLoss>0)?MarketInfo(Sym,MODE_BID)-StopLoss:0;
   double TP = (TakeProfit>0)?MarketInfo(Sym,MODE_ASK)+TakeProfit:0;
   while(IsTradeContextBusy()) Sleep(1000);
   RefreshRates();
   return OrderSend(
                    Sym,
                    OP_BUY,
                    CalculateLots(),
                    MarketInfo(Sym,MODE_ASK),
                    Slippage,
                    SL,
                    TP,
                    IntegerToString(magic),// comment
                    magic
                    );
  }
  
//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
int EA::Sell(int magic)//, string comment
  {
   PreviousTime=(int)TimeMinute(TimeLocal());
   double SL = (StopLoss>0)?MarketInfo(Sym,MODE_ASK)+StopLoss:0;
   double TP = (TakeProfit>0)?MarketInfo(Sym,MODE_BID)-TakeProfit:0;
   while(IsTradeContextBusy()) Sleep(1000);
   RefreshRates();
   return OrderSend(
                    Sym,
                    OP_SELL,
                    CalculateLots(),
                    MarketInfo(Sym,MODE_BID),
                    Slippage,
                    SL,
                    TP,
                    IntegerToString(magic),// comment
                    magic
                    );
  }
  
//+------------------------------------------------------------------+
//| Close buy                                                        |
//+------------------------------------------------------------------+
void EA::CloseBuy(int magic)
  {
   string symb=EnumToString(ENUM_FX_PAIRS(StrToInteger(StringSubstr(IntegerToString(magic),1,1))));
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
    bool result = false;
    if (OrderSelect(i, SELECT_BY_POS))
    {
     if(OrderMagicNumber()== magic && OrderSymbol()== symb && OrderType()==OP_BUY)
         result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(symb,MODE_BID),Slippage,Red);
     if (result) Print("Notice: CloseBuy completed.", symb,OrderTicket());
     //if (!result)Print(" Closebuy NOT Succeed, ticket=", symb,OrderTicket()," Error=", GetLastError());
    }
   }
  }
  
//+------------------------------------------------------------------+
//| Close sell                                                       |
//+------------------------------------------------------------------+
void EA::CloseSell(int magic)
  {
  string symb=EnumToString(ENUM_FX_PAIRS(StrToInteger(StringSubstr(IntegerToString(magic),1,1))));
  for(int i=OrdersTotal()-1;i>=0;i--)
   {
    bool result = false;
    if (OrderSelect(i, SELECT_BY_POS))
    {
     if(OrderMagicNumber()== magic && OrderSymbol()== symb && OrderType()==OP_SELL)
         result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(symb,MODE_ASK),Slippage,Red);
     if (result) Print("Notice: CloseSell completed.", symb, OrderTicket());
     //if (!result)Print(" Closesell NOT Succeed, ticket=", symb,OrderTicket()," Error=", GetLastError());
    }
   }
  }

/*  
//+------------------------------------------------------------------+
//| Long trailing Profit                                             |
//+------------------------------------------------------------------+
void EA::DoLongTrailingProfit(int intMagic)
  {
   string symb = (EnumToString(ENUM_FX_PAIRS(StrToInteger(StringSubstr(IntegerToString(intMagic),1,1)))));
   //if(TrailingProfit>0)
   if(TrailingProfit > exTakeProfit*pips_point)
     {
      RefreshRates();
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
       bool result = false;
       if (OrderSelect(i, SELECT_BY_POS))
       {
        if(OrderMagicNumber()==intMagic && MarketInfo(symb,MODE_BID)-OrderOpenPrice()>TrailingProfit)
        {
        // Print("Ticket=",OrderTicket()," Long magic=",intMagic," symb=",symb);
         if(MarketInfo(symb,MODE_BID)+TrailingTPStep*pips_point>OrderTakeProfit() || OrderTakeProfit()==0)
           {
            int o0=OrderModify(OrderTicket(),
                               OrderOpenPrice(),
                               OrderStopLoss(),
                               MarketInfo(symb,MODE_BID)+TrailingTPStep*pips_point,
                               0
                               );
           }
         }
      }  
    }
     }
  }
  
//+------------------------------------------------------------------+
//| Short trailing Profit                                            |
//+------------------------------------------------------------------+
void EA::DoShortTrailingProfit(int intMagic)
  {
   string symb = (EnumToString(ENUM_FX_PAIRS(StrToInteger(StringSubstr(IntegerToString(intMagic),1,1)))));
   
   if(TrailingProfit>0)
     {
      RefreshRates();
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
       bool result = false;
       if (OrderSelect(i, SELECT_BY_POS))
         {
            if(OrderMagicNumber()==intMagic && OrderOpenPrice()-MarketInfo(symb,MODE_ASK)>TrailingProfit)
              {
               //Print("Ticket=",OrderTicket()," Short magic=",intMagic," symb=",symb);
               if(OrderTakeProfit()>MarketInfo(symb,MODE_ASK)-TrailingTPStep*pips_point || OrderTakeProfit()==0)
                 {
                  int o02=OrderModify(OrderTicket(),
                                      OrderOpenPrice(),
                                      OrderStopLoss(),
                                      MarketInfo(symb,MODE_ASK)-TrailingTPStep*pips_point,
                                      0
                                      );
                 }
              }
          }
       }   
     }
  }*/
  

//+------------------------------------------------------------------+
//| TrailingTakeProfit() 追(蹤止)盈(手動按鈕)                        |
//+------------------------------------------------------------------+
void TrailingTakeProfit(string posType) 
{
  double newTP=0.0;
  for(int cnt = OrdersTotal() - 1; cnt >= 0; cnt--) 
  {
    if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)&& OrderSymbol() == SymbolInp) 
    {
       if ((posType=="Long" || posType=="")&& OrderType()==OP_BUY) 
       {
         if (OrderTakeProfit()==0)  newTP = MathMax(MarketInfo(OrderSymbol(), MODE_ASK),OrderOpenPrice()) + TrailingTPStep*pips_point; 
         else newTP=OrderTakeProfit()+ TrailingTPStep*pips_point;
       }
       if ((posType=="Short"|| posType=="") && OrderType()==OP_SELL)
       {
          if (OrderTakeProfit()==0)  newTP=MathMin(MarketInfo(OrderSymbol(), MODE_BID),OrderOpenPrice())-TrailingTPStep*pips_point; 
         else newTP=OrderTakeProfit()- TrailingTPStep*pips_point;
       }
      bool resSuceed;
      resSuceed=OrderModify(OrderTicket(),OrderOpenPrice(),0,newTP,0,CLR_NONE);
      //if (resSuceed) PlaySound("::Files\\Sounds\\switch.wav");;
    }
  }
   //return;
}

/*
//+--------------------------------------------------------------+
//| TrailingTakeProfit() 追盈(自動)                              |         
//|  改在EA::Trade() 中判斷，透過getTakePrpfit()實現             |
//+--------------------------------------------------------------+
void ExtraTrailingProfit(int magic, int extraProfit) 
{
  double newTP=0.0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
    if (OrderSelect(i, SELECT_BY_POS))
    {
     if(OrderMagicNumber()==magic)
      {
       switch (OrderType()) 
       {
       case OP_BUY:
         newTP = OrderTakeProfit()+ extraProfit*pips_point; 
         break;
       case OP_SELL:
         newTP=OrderTakeProfit() - extraProfit*pips_point; 
         break;
       default: newTP=OrderTakeProfit();
       }
         
      bool resSuceed;
      resSuceed=OrderModify(OrderTicket(),OrderOpenPrice(),0,newTP,0,clrAqua);
      if (resSuceed) PlaySound("::Files\\Sounds\\switch.wav");;
      }
    }
  }  
   //return;
}*/  

//+------------------------------------------------------------------+
//| Instances of class EA, the parallele strategies                  |
//+------------------------------------------------------------------+
EA HeinkenAshiMacd_EA, MaCross_EA, ZZReturn_EA;   //MaCross_EA,SARMaCross_EA, ZZTrendMaAlign_EA

//+------------------------------------------------------------------+
//| Init Trade function                                              |
//+------------------------------------------------------------------+
int   magic;
bool  bolBuy,bolSell,bolStopBuy,bolStopSell;

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   TimerIsEnabled=false;
  // Print (__FUNCTION__, " Findex Co. - playhigh@gmail.com");
//--- destroy dialog
//   ExtDialog.Destroy(reason);//不能Destroy，否則UpdateLabelSelectedSymbol時會關閉Controls
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!TimerIsEnabled && !IsTesting()) TimerIsEnabled=EventSetMillisecondTimer(TimerInterval);

//---- time checker
  if ((MathAbs(CurTime()-LastUpdate)> UpdateInterval*60) ) //&& (StopTradeFlag == false)
            //update at the first time it is called and every UpdateInterval minutes
   {
      LastUpdate = CurTime();
   }//time check "if" end here
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   AccTradeInfo();     //-- DisplayAccount&TradeInfo
   if (useHeikenAshiMacd)  Run_HeikenAshiMacd();
   if (useMaCross)         Run_MaCross();
   if (useZZReturn)        Run_ZZReturn();   
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
{
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
}

//+------------------------------------------------------------------+
//| Account And Trade Information                                    |
//+------------------------------------------------------------------+
void AccTradeInfo()
  {
      int LongOpenOrders = 0;
      int ShortOpenOrders = 0;
      double LongLots=0.0;
      double ShortLots=0.0;
      double LongProfits=0.0;
      double ShortProfits=0.0;

      double LongProfits_A1=0.0;
      double LongProfits_B1=0.0;
      double LongProfits_C1=0.0;
      double ShortProfits_A1=0.0;
      double ShortProfits_B1=0.0;
      double ShortProfits_C1=0.0;

      double LongProfits_A2=0.0;
      double LongProfits_B2=0.0;
      double LongProfits_C2=0.0;
      double ShortProfits_A2=0.0;
      double ShortProfits_B2=0.0;
      double ShortProfits_C2=0.0;

      double LongProfits_A3=0.0;
      double ShortProfits_A3=0.0;
      double LongProfits_B3=0.0;
      double ShortProfits_B3=0.0;
      double LongProfits_C3=0.0;
      double ShortProfits_C3=0.0;

      double LongProfits_A4=0.0;
      double ShortProfits_A4=0.0;
      double LongProfits_B4=0.0;
      double ShortProfits_B4=0.0;
      double LongProfits_C4=0.0;
      double ShortProfits_C4=0.0;


      double LongProfits_A5=0.0;
      double ShortProfits_A5=0.0;
      double LongProfits_B5=0.0;
      double ShortProfits_B5=0.0;
      double LongProfits_C5=0.0;
      double ShortProfits_C5=0.0;

      double LongProfits_A6=0.0;
      double ShortProfits_A6=0.0;
      double LongProfits_B6=0.0;
      double ShortProfits_B6=0.0;
      double LongProfits_C6=0.0;
      double ShortProfits_C6=0.0;

      double LongProfits_A=0.0;
      double ShortProfits_A=0.0;
      double LongProfits_B=0.0;
      double ShortProfits_B=0.0;
      double LongProfits_C=0.0;
      double ShortProfits_C=0.0;

      for(int k=0;k<OrdersTotal();k++)
      {
         OrderSelect(k,SELECT_BY_POS);
      //Print("EA=",k," Magic=",OrderMagicNumber()," subMagic=",StringSubstr(IntegerToString(OrderMagicNumber()),0,1)," ShortOpenOrders=",ShortOpenOrders," LongOpenOrders=",LongOpenOrders);
         
         //---pair #1----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "1")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")//A
            {
               if(OrderType() == OP_BUY){
               LongProfits_A1=LongProfits_A1+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A1=ShortProfits_A1+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")//B
            {
               if(OrderType() == OP_BUY){
               LongProfits_B1=LongProfits_B1+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B1=ShortProfits_B1+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")//C
            {
               if(OrderType() == OP_BUY){
               LongProfits_C1=LongProfits_C1+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C1=ShortProfits_C1+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
          }
          
         //---pair #2----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "2")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")//A
            {
               if(OrderType() == OP_BUY){
               LongProfits_A2=LongProfits_A2+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A2=ShortProfits_A2+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")//B
            {
               if(OrderType() == OP_BUY){
               LongProfits_B2=LongProfits_B2+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B2=ShortProfits_B2+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")//C
            {
               if(OrderType() == OP_BUY){
               LongProfits_C2=LongProfits_C2+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C2=ShortProfits_C2+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
      //Print(" Magic=",OrderMagicNumber()," ShortProfits_C2=",ShortProfits_C2," LongProfits_C2=",LongProfits_C2);
            }
          }
          
         //---pair #3----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "3")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")
            {
               if(OrderType() == OP_BUY){
               LongProfits_A3=LongProfits_A3+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A3=ShortProfits_A3+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")
            {
               if(OrderType() == OP_BUY){
               LongProfits_B3=LongProfits_B3+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B3=ShortProfits_B3+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")
            {
               if(OrderType() == OP_BUY){
               LongProfits_C3=LongProfits_C3+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C3=ShortProfits_C3+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
          }
          
         //---pair #4----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "4")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")
            {
               if(OrderType() == OP_BUY){
               LongProfits_A4=LongProfits_A4+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A4=ShortProfits_A4+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")
            {
               if(OrderType() == OP_BUY){
               LongProfits_B4=LongProfits_B4+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B4=ShortProfits_B4+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")
            {
               if(OrderType() == OP_BUY){
               LongProfits_C4=LongProfits_C4+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C4=ShortProfits_C4+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
          }
          
         //---pair #5----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "5")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")
            {
               if(OrderType() == OP_BUY){
               LongProfits_A5=LongProfits_A5+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A5=ShortProfits_A5+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")
            {
               if(OrderType() == OP_BUY){
               LongProfits_B5=LongProfits_B5+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B5=ShortProfits_B5+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")
            {
               if(OrderType() == OP_BUY){
               LongProfits_C5=LongProfits_C5+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C5=ShortProfits_C5+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
          }
          
         //---pair #6----------
         if (StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == "6")
         {
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "1")
            {
               if(OrderType() == OP_BUY){
               LongProfits_A6=LongProfits_A6+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_A=LongProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_A6=ShortProfits_A6+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_A=ShortProfits_A+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "2")
            {
               if(OrderType() == OP_BUY){
               LongProfits_B6=LongProfits_B6+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_B=LongProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_B6=ShortProfits_B6+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_B=ShortProfits_B+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
            if (StringSubstr(IntegerToString(OrderMagicNumber()),0,1) == "3")
            {
               if(OrderType() == OP_BUY){
               LongProfits_C6=LongProfits_C6+OrderProfit()+OrderCommission()+OrderSwap();
               LongProfits_C=LongProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
               if(OrderType() == OP_SELL){
               ShortProfits_C6=ShortProfits_C6+OrderProfit()+OrderCommission()+OrderSwap();
               ShortProfits_C=ShortProfits_C+OrderProfit()+OrderCommission()+OrderSwap();
               }
            }
          }

         if(OrderType() == OP_BUY)
           {
            LongOpenOrders++;
            LongLots=LongLots+OrderLots();
            LongProfits=LongProfits+OrderProfit()+OrderCommission()+OrderSwap();
           }
         if(OrderType() == OP_SELL)
           {
            ShortOpenOrders++;
            ShortLots=ShortLots+OrderLots();
            ShortProfits=ShortProfits+OrderProfit()+OrderCommission()+OrderSwap();
         }
         
     }
            
      ExtDialog.UpdateLabelShortPos(DoubleToString(ShortOpenOrders,0),DoubleToString(ShortLots,2),DoubleToString(ShortProfits,1));
      ExtDialog.UpdateLabelLongPos(DoubleToString(LongOpenOrders,0),DoubleToString(LongLots,2),DoubleToString(LongProfits,1));
      
//------------
      ExtDialog.UpdateLabelPos_1(DoubleToString(ShortProfits_A1,0),DoubleToString(ShortProfits_B1,0),DoubleToString(ShortProfits_C1,0),
                                 DoubleToString(LongProfits_A1,0),DoubleToString(LongProfits_B1,0),DoubleToString(LongProfits_C1,0));

      ExtDialog.UpdateLabelPos_2(DoubleToString(ShortProfits_A2,0),DoubleToString(ShortProfits_B2,0),DoubleToString(ShortProfits_C2,0),
                                 DoubleToString(LongProfits_A2,0),DoubleToString(LongProfits_B2,0),DoubleToString(LongProfits_C2,0));

      ExtDialog.UpdateLabelPos_3(DoubleToString(ShortProfits_A3,0),DoubleToString(ShortProfits_B3,0),DoubleToString(ShortProfits_C3,0),
                                 DoubleToString(LongProfits_A3,0),DoubleToString(LongProfits_B3,0),DoubleToString(LongProfits_C3,0));

      ExtDialog.UpdateLabelPos_4(DoubleToString(ShortProfits_A4,0),DoubleToString(ShortProfits_B4,0),DoubleToString(ShortProfits_C4,0),
                                 DoubleToString(LongProfits_A4,0),DoubleToString(LongProfits_B4,0),DoubleToString(LongProfits_C4,0));

      ExtDialog.UpdateLabelPos_5(DoubleToString(ShortProfits_A5,0),DoubleToString(ShortProfits_B5,0),DoubleToString(ShortProfits_C5,0),
                                 DoubleToString(LongProfits_A5,0),DoubleToString(LongProfits_B5,0),DoubleToString(LongProfits_C5,0));

      ExtDialog.UpdateLabelPos_6(DoubleToString(ShortProfits_A6,0),DoubleToString(ShortProfits_B6,0),DoubleToString(ShortProfits_C6,0),
                                 DoubleToString(LongProfits_A6,0),DoubleToString(LongProfits_B6,0),DoubleToString(LongProfits_C6,0));

      ExtDialog.UpdateLabelPos_99(DoubleToString(ShortProfits_A,0),DoubleToString(ShortProfits_B,0),DoubleToString(ShortProfits_C,0),
                                 DoubleToString(LongProfits_A,0),DoubleToString(LongProfits_B,0),DoubleToString(LongProfits_C,0));


//------------
      //ExtDialog.UpdateLabelShortPos_2(DoubleToString(ShortOpenOrders_2,0),DoubleToString(ShortLots_2,2),DoubleToString(ShortProfits_B1,0));
      //ExtDialog.UpdateLabelLongPos_2(DoubleToString(LongOpenOrders_2,0),DoubleToString(LongLots_2,2),DoubleToString(LongProfits_B1,0));
//------------
      //ExtDialog.UpdateLabelShortPos_3(DoubleToString(ShortOpenOrders_3,0),DoubleToString(ShortLots_3,2),DoubleToString(ShortProfits_C1,0));
      //ExtDialog.UpdateLabelLongPos_3(DoubleToString(LongOpenOrders_3,0),DoubleToString(LongLots_3,2),DoubleToString(LongProfits_C1,0));

/*   if(BetOnShorts)
     {
      ObjectSetInteger(0,OBJPREFIX+"ShortSignal§",OBJPROP_COLOR,clrRed);
     }  else     ObjectSetInteger(0,OBJPREFIX+"ShortSignal§",OBJPROP_COLOR,clrMistyRose);
   if(BetOnLongs)
     {
      ObjectSetInteger(0,OBJPREFIX+"LongSignal§",OBJPROP_COLOR,clrBlue);
     }  else     ObjectSetInteger(0,OBJPREFIX+"LongSignal§",OBJPROP_COLOR,clrLavender);
*/     
     
  }

//+------------------------------------------------------------------------+
//|  close open long positions               |
//+------------------------------------------------------------------------+
void CloseLongOrders()
{
  for(int i=OrdersTotal()-1;i>=0;i--)
   {
    bool result = false;
    if (OrderSelect(i, SELECT_BY_POS))
    {
     if(OrderSymbol()==SymbolInp
      //&& StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == ""
      && OrderType()==OP_BUY)
         result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),Slippage,Red);
     if (!result) Print("CloseLongOrders-Warning/Error: CloseLongOrders not executed. Error:" , GetLastError());
    }
   }
  return;
}
    
//+------------------------------------------------------------------------+
//| close open short positions             |
//+------------------------------------------------------------------------+
void CloseShortOrders()
{
  for(int i=OrdersTotal()-1;i>=0;i--)
   {
    bool result = false;
    if (OrderSelect(i, SELECT_BY_POS))
    {
     if(OrderSymbol()==SymbolInp 
      //&& StringSubstr(IntegerToString(OrderMagicNumber()),1,1) == ""
      && OrderType()==OP_SELL)
         result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),Slippage,Red);
     if (!result) Print("CloseShortOrders-Warning/Error: CloseShortOrders not executed");
    }
   }
  return;
}

//+------------------------+
//| Heiken_MACD            |
//+------------------------+
void  Run_HeikenAshiMacd()
  {
   for(int j = EURUSDg; j <= USDJPYg; j++)
   {
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      int magic=int("1"+string(j));

      HeinkenAshiMacd_EA.Create(Lots,exSlippage,"",magic,RiskMM,RiskPercent,symb,exStopLoss,exTakeProfit,exTrailingProfit,exTrailingStop,exmaxSpread,Monday,Monday_Start_Hour,Monday_Finish_Hour,Tuesday,Tuesday_Start_Hour,Tuesday_Finish_Hour,Wednesday,Wednesday_Start_Hour,Wednesday_Finish_Hour,Thursday,Thursday_Start_Hour,Thursday_Finish_Hour,Friday,Friday_Start_Hour,Friday_Finish_Hour);
      
      double HAOpen = iCustom(symb, PERIOD_M15, "Heiken_Ashi_Smoothed", 2, 4, 2, 1, 2, 0);   //最後一個2=open
      double HAClose = iCustom(symb, PERIOD_M15, "Heiken_Ashi_Smoothed", 2, 4, 2, 1, 3, 0);  //最後一個3=close
      double HAOpen1 = iCustom(symb, PERIOD_M15, "Heiken_Ashi_Smoothed", 2, 4, 2, 1, 2, 1); 
      double HAClose1 = iCustom(symb, PERIOD_M15, "Heiken_Ashi_Smoothed", 2, 4, 2, 1, 3, 1);
      double MA1    =iMA(symb,PERIOD_M15,12,0,MODE_EMA,PRICE_OPEN,1);      

      bolBuy =
            HeinkenAshiMacd_EA.CountPositions(symb,magic,OP_BUY) < Lots 
         && (CurTime() > newAllowed_1)   
         && GetHeikenAshiTrend(symb,0) == OP_BUY //PERIOD_H1 //&& GetHeikenAshiTrend(symb,0)!= GetHeikenAshiTrend(symb,1)
         &&(HAOpen1 > HAClose1 && HAOpen<HAClose && iOpen(symb,PERIOD_M5,1) > MA1)//lonewolf
         &&(macd_main(symb,0) > macd_main(symb,1) || macd_main(symb,1) > macd_main(symb,2))//M15
         ;
      
      bolSell =
            HeinkenAshiMacd_EA.CountPositions(symb,magic,OP_SELL) < Lots
         && (CurTime() > newAllowed_1)   
         && GetHeikenAshiTrend(symb,0) ==OP_SELL //&& GetHeikenAshiTrend(symb,0) != GetHeikenAshiTrend(symb,1)
         &&(HAOpen1 < HAClose1 && HAOpen > HAClose && iOpen(symb,PERIOD_M5,1) < MA1)//(lonewolf)
         && (macd_main(symb,0) < macd_main(symb,1) || macd_main(symb,1) < macd_main(symb,2))
         ;
      
      bolStopBuy  = ((bolSell && SymbLongProfits(symb,magic)>=0)
                     || SymbLongProfits(symb,magic) > 32);
      
      bolStopSell = ((bolBuy && SymbShortProfits(symb,magic)>=0)
                     || SymbShortProfits(symb,magic) > 32);
      
      if (bolBuy || bolSell) newAllowed_1 = CurTime() + 60 * 5; // No new trade until this one closes
       
      HeinkenAshiMacd_EA.Trade
      (
        magic,
        bolBuy,        
        bolSell,       
        bolStopBuy,
        bolStopSell
      );      
   }
  }

/*
//+------------------------+
//|  Run_BBSwing           |
//+------------------------+
void Run_BBSwing()
  {
   for(int j = EURUSDg; j <= EURJPYg; j++)
   {
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      int magic=int("2"+string(j));

      double f_MA0=iMA(symb,PERIOD_M15,6,0,MODE_LWMA,PRICE_TYPICAL,0); //(Fast values: 1-20)=6
      double s_MA0=iMA(symb,PERIOD_M15,20,0,MODE_LWMA,PRICE_TYPICAL,0); //(Slow values: 50-200)=85
      double f_MA1=iMA(symb,PERIOD_M15,6,0,MODE_LWMA,PRICE_TYPICAL,1); //(Fast values: 1-20)=6
      double s_MA1=iMA(symb,PERIOD_M15,20,0,MODE_LWMA,PRICE_TYPICAL,1); //(Slow values: 50-200)=85
      double f_MA2=iMA(symb,PERIOD_M15,6,0,MODE_LWMA,PRICE_TYPICAL,2); //(Fast values: 1-20)=6
      double s_MA2=iMA(symb,PERIOD_M15,20,0,MODE_LWMA,PRICE_TYPICAL,2); //(Slow values: 50-200)=85
      //double f_MA3=iMA(symb,PERIOD_M15,6,0,MODE_LWMA,PRICE_TYPICAL,3); //(Fast values: 1-20)=6
      //double s_MA3=iMA(symb,PERIOD_M15,20,0,MODE_LWMA,PRICE_TYPICAL,3); //(Slow values: 50-200)=85
      //----------------------------------------------------------------------------
      //double MBB=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_MAIN,1);//middle
      double LBB0=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_LOWER,0);//lower
      double UBB0=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_UPPER,0);//upper        
      double LBB1=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_LOWER,1);//lower
      double UBB1=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_UPPER,1);//upper        
      double LBB2=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_LOWER,2);//lower
      double UBB2=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_UPPER,2);//upper        
      double LBB3=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_LOWER,3);//lower
      double UBB3=iBands(symb,PERIOD_M15,20, 2,0,0,MODE_UPPER,3);//upper        
                     
      BBSwing_EA.Create(Lots,exSlippage,magic,RiskMM,RiskPercent,symb,exStopLoss,exTakeProfit,exTrailingProfit,exmaxSpread,Monday,Monday_Start_Hour,Monday_Finish_Hour,Tuesday,Tuesday_Start_Hour,Tuesday_Finish_Hour,Wednesday,Wednesday_Start_Hour,Wednesday_Finish_Hour,Thursday,Thursday_Start_Hour,Thursday_Finish_Hour,Friday,Friday_Start_Hour,Friday_Finish_Hour);
      
      bolBuy  = BBSwing_EA.CountPositions(symb, magic, OP_BUY) < Lots 
                 && (iLow(symb,PERIOD_M15,3)<=LBB3 || iLow(symb,PERIOD_M15,2)<=LBB2|| iLow(symb,PERIOD_M15,1)<=LBB1)
                 && (MarketInfo(symb,MODE_ASK) > iClose(symb,PERIOD_M15,1))
                 && iClose(symb,PERIOD_M15,1)>= iClose(symb,PERIOD_M15,2) && iClose(symb,PERIOD_M15,2)>= iClose(symb,PERIOD_M15,3)
                 && (f_MA0 > s_MA0 || ((f_MA0 <= s_MA0)&&((s_MA1-f_MA1)<(s_MA2-f_MA2))));
                 //&& (iClose(symb,PERIOD_M15,1)-iOpen(symb,PERIOD_M15,1)>MathAbs(iOpen(symb,PERIOD_M15,2)-iClose(symb,PERIOD_M15,2)))

      bolSell = BBSwing_EA.CountPositions(symb, magic, OP_SELL) < Lots 
                 && (iHigh(symb,PERIOD_M15,3)>=UBB3 || iHigh(symb,PERIOD_M15,2)>=UBB2 || iHigh(symb,PERIOD_M15,1)>=UBB1)
                 && (MarketInfo(symb,MODE_BID) < iClose(symb,PERIOD_M15,1))
                 && iClose(symb,PERIOD_M15,1)<= iClose(symb,PERIOD_M15,2) && iClose(symb,PERIOD_M15,2)<= iClose(symb,PERIOD_M15,3)
                 && (f_MA0 < s_MA0 || ((f_MA0 >= s_MA0)&&((f_MA1-s_MA1)<(f_MA2-s_MA2))));
                 //&& (iOpen(symb,PERIOD_M15,1)-iClose(symb,PERIOD_M15,1) > MathAbs(iOpen(symb,PERIOD_M15,2)-iClose(symb,PERIOD_M15,2)))

      bolStopBuy  = (bolSell && SymbLongProfits(symb,magic)>=0);
      bolStopSell = (bolBuy && SymbShortProfits(symb,magic)>=0);
      
      BBSwing_EA.Trade
      (
        magic,
        bolBuy,
        bolSell,
        bolStopBuy,
        bolStopSell
      );
   }
  }  
*/

//+-----------------------------+
//|  Run_MaCross                |
//+-----------------------------+
void Run_MaCross()
  {
   for(int j = EURUSDg; j <= USDJPYg; j++)
   {
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      int magic=int("2"+string(j));

      //double fMA=iMA(symb,PERIOD_M15, 10, 0, MODE_SMA, PRICE_CLOSE, 1);
      //double sMA=iMA(symb,PERIOD_M15, 80, 0, MODE_SMA, PRICE_CLOSE, 1);
      //double Ema=iMA(Symb,PERIOD_M15,12,0,MODE_EMA,PRICE_CLOSE,0);//MovingPeriod=12,MovingShift=6
      //double Ema1=iMA(symb,PERIOD_M15,12,0,MODE_EMA,PRICE_CLOSE,1); //**PRICE_MEDIAN
      double SMA5=iMA(symb,PERIOD_M15,5,0,MODE_EMA,PRICE_CLOSE,0);
      double SMA5_pre=iMA(symb,PERIOD_M15,5,0,MODE_EMA,PRICE_CLOSE,1);
      double SMA13=iMA(symb,PERIOD_M15,13,0,MODE_EMA,PRICE_CLOSE,0);
      double SMA21=iMA(symb,PERIOD_M15,21,0,MODE_EMA,PRICE_CLOSE,0);
      double SMA21_pre=iMA(symb,PERIOD_M15,21,0,MODE_EMA,PRICE_CLOSE,1);
      double Macd0=iMACD(symb,PERIOD_M15,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
      double Macd1=iMACD(symb,PERIOD_M15,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
      double Macd2=iMACD(symb,PERIOD_M15,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
      
      MaCross_EA.Create(Lots,exSlippage,"",magic,RiskMM,RiskPercent,symb,exStopLoss,exTakeProfit,exTrailingProfit,exTrailingStop,exmaxSpread,Monday,Monday_Start_Hour,Monday_Finish_Hour,Tuesday,Tuesday_Start_Hour,Tuesday_Finish_Hour,Wednesday,Wednesday_Start_Hour,Wednesday_Finish_Hour,Thursday,Thursday_Start_Hour,Thursday_Finish_Hour,Friday,Friday_Start_Hour,Friday_Finish_Hour);
      bolBuy  = MaCross_EA.CountPositions(symb, magic, OP_BUY) < Lots 
               && (CurTime() > newAllowed_2)   
               && (SMA5>SMA13 && SMA13>SMA21 && (SMA5-SMA21)/SMA21 > 0.00036)//&& SMA21>SMA60 && SMA60>SMA200 
               && (iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_MAIN,0)-iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_SIGNAL,0))> 2
               && Macd0 >= Macd1  &&  Macd1 >= Macd2               
               ;
      
      bolSell = MaCross_EA.CountPositions(symb, magic, OP_SELL) < Lots  
               && (CurTime() > newAllowed_2)   
               && (SMA5<SMA13 && SMA13<SMA21 && (SMA21-SMA5)/SMA21 > 0.00036)//&& SMA21<SMA60 && SMA60<SMA200 
               && (iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_SIGNAL,0)-iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_MAIN,0)) > 2
               && Macd0 <= Macd1 &&  Macd1 <= Macd2      
            ;
      
      if (bolBuy || bolSell) newAllowed_2 = CurTime() + 60 * 5; // No new trade until this one closes
      
      bolStopBuy  = ((SMA5_pre < SMA21_pre && SMA5 <= SMA5_pre && SymbLongProfits(symb,magic)>=0)
                     || SymbLongProfits(symb,magic) > 32);
      bolStopSell = ((SMA21_pre > SMA5_pre && SMA5 >= SMA5_pre && SymbShortProfits(symb,magic)>=0)
                     || SymbShortProfits(symb,magic) > 32);

     // Print(symb," K-D=",NormalizeDouble((iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_MAIN,0)-iStochastic(symb,PERIOD_M15,5,3,3,MODE_EMA,0,MODE_SIGNAL,0)),0)
     // ," SMA5=", NormalizeDouble(SMA5,1)," SMA13=", NormalizeDouble(SMA13,1)," SMA21=", NormalizeDouble(SMA21,1)," (SMA5-SMA21)/SMA21=", NormalizeDouble(((SMA5-SMA21)/SMA21),5));
      
      MaCross_EA.Trade
      (
        magic,
        bolBuy,
        bolSell,
        bolStopBuy,
        bolStopSell
      );
   }
  }

//+---------------------------------------------+
//|  Run_ZZReturn = SAR+Fuzzy(K,CCI,RVI)        |
//+---------------------------------------------+
void  Run_ZZReturn()
  {
   int Cur_ZZTurnDn_State=0, Cur_ZZTurnUp_State=0; 
   static bool flag_Alert=false;
      
   for(int j = EURUSDg; j <= USDJPYg; j++)
   {
      int magic=int("3"+string(j));
      string symb = (EnumToString(ENUM_FX_PAIRS(j)));
      
      Cur_ZZTurnUp_State = ZZTurnUp_Check(symb,0);
      Cur_ZZTurnDn_State = ZZTurnDn_Check(symb,0);
      if(Cur_ZZTurnUp_State>0 && Cur_ZZTurnUp_State != aryPre_ZZTurnUp_State[j-1]) //ZZTurnUp_State改變才動作
       {
         aryPre_ZZTurnUp_State[j-1] = Cur_ZZTurnUp_State;
         aryPre_ZZTurnDn_State[j-1] =0;
         flag_Alert=true;
       }
      else 
      if(Cur_ZZTurnDn_State>0 && Cur_ZZTurnDn_State != aryPre_ZZTurnDn_State[j-1]) //ZZTurnDn_State改變才動作
       {
         aryPre_ZZTurnDn_State[j-1] = Cur_ZZTurnDn_State;
         aryPre_ZZTurnUp_State[j-1] =0;
         flag_Alert=true;
       }
       
     /*
     if ((aryPre_ZZTurnUp_State[j-1]>=2 || aryPre_ZZTurnDn_State[j-1]>=2) && flag_Alert)
     {
      string txt="";
      if (aryPre_ZZTurnUp_State[j-1]>=2){txt+=" UP"+aryPre_ZZTurnUp_State[j-1]; flag_Alert=false;}
      else 
      if (aryPre_ZZTurnDn_State[j-1]>=2){txt+=" Dn"+aryPre_ZZTurnDn_State[j-1];flag_Alert=false;}
      Alert(symb," ZZ=",txt);
     }
     */
     
     ZZReturn_EA.Create(Lots,"",exSlippage,magic,RiskMM,RiskPercent,symb,exStopLoss,exTakeProfit,exTrailingProfit,exTrailingStop,exmaxSpread,Monday,Monday_Start_Hour,Monday_Finish_Hour,Tuesday,Tuesday_Start_Hour,Tuesday_Finish_Hour,Wednesday,Wednesday_Start_Hour,Wednesday_Finish_Hour,Thursday,Thursday_Start_Hour,Thursday_Finish_Hour,Friday,Friday_Start_Hour,Friday_Finish_Hour);
      
     //ZZ_TrendLine(symb, PERIOD_M15);
     //ZZ_LineUpper = NormalizeDouble(ObjectGetValueByShift("Trend.HighLine", 0),Digits );
     //ZZ_LineLower  = NormalizeDouble(ObjectGetValueByShift("Trend.LowLine", 0),Digits );
     //double K= iStochastic(NULL,PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,0);
     //double Ema1=iMA(symb,PERIOD_M15,4,0,MODE_EMA,PRICE_CLOSE,1);

      bolBuy = ZZReturn_EA.CountPositions(symb,magic,OP_BUY) < Lots 
         && aryPre_ZZTurnUp_State[j-1] >=2
         //&& (iLow(symb,PERIOD_M15,2)< LBB2 || iLow(symb,PERIOD_M15,1)<LBB1)
         //&& (MarketInfo(symb,MODE_ASK) > iClose(symb,PERIOD_M15,1))
         && FuzzyReturn(symb) >= 0.7
         ;
         //&& iClose(symb,PERIOD_M15,0) >= ZZ_LineLower
         //&& (iLow(symb,PERIOD_M15,4)<= ZZ_LineLower || iLow(symb,PERIOD_M15,3)<=ZZ_LineLower || iLow(symb,PERIOD_M15,2)<=ZZ_LineLower|| iLow(symb,PERIOD_M15,1)<=ZZ_LineLower)
         //&& (f_MA0 > s_MA0 ||(f_MA0 < s_MA0)&&((s_MA1-f_MA1)<(s_MA2-f_MA2)));
         //&& (UBB0-LBB0) >= 285 * pips_point
         //&& MarketInfo(symb,MODE_ASK) < (UBB0+LBB0)/2
         //&& K < 30
         //&& iOpen(symb,PERIOD_M15,0) > Ema1
         //&& iClose(symb,PERIOD_M15,0) - LBB0 > iClose(symb,PERIOD_M15,1) - LBB1 
         //&& iClose(symb,PERIOD_M15,1) - LBB1 > iClose(symb,PERIOD_M15,2) - LBB2
         //&& (iClose(symb,PERIOD_M15,1)-iOpen(symb,PERIOD_M15,1)>MathAbs(iOpen(symb,PERIOD_M15,2)-iClose(symb,PERIOD_M15,2)))
         
      bolSell = ZZReturn_EA.CountPositions(symb,magic,OP_SELL) < Lots 
         && aryPre_ZZTurnDn_State[j-1] >=2
         //&& (iHigh(symb,PERIOD_M15,2)>UBB2 || iHigh(symb,PERIOD_M15,1)>UBB1)
         //&& (MarketInfo(symb,MODE_BID) < iClose(symb,PERIOD_M15,1))
         && FuzzyReturn(symb) >= 0.7
         ;
         //&& iClose(symb,PERIOD_M15,0) <= ZZ_LineUpper
         //&& (iHigh(symb,PERIOD_M15,4)>= ZZ_LineUpper || iHigh(symb,PERIOD_M15,3)>=ZZ_LineUpper || iHigh(symb,PERIOD_M15,2)>=ZZ_LineUpper || iHigh(symb,PERIOD_M15,1)>=ZZ_LineUpper)
         //&& (UBB0-LBB0) >= 285 * pips_point
         //&& MarketInfo(symb,MODE_BID) > (UBB0+LBB0)/2
         //&& K > 70
         //&& iOpen(symb,PERIOD_M15,0) < Ema1
         //&& (iOpen(symb,PERIOD_M15,1)-iClose(symb,PERIOD_M15,1) > MathAbs(iOpen(symb,PERIOD_M15,2)-iClose(symb,PERIOD_M15,2)))
         //&& UBB0 - iClose(symb,PERIOD_M15,0) > UBB1 - iClose(symb,PERIOD_M15,1)
         //&& UBB1 - iClose(symb,PERIOD_M15,1) > UBB2 - iClose(symb,PERIOD_M15,2)
         
      //if (symb=="GBPUSDg"){
      //Print(symb, " 【Up_pre】=", aryPre_ZZTurnUp_State[j-1], " 【Dn_pre】=", aryPre_ZZTurnDn_State[j-1], bolBuy,bolSell
      //, " 【Up】=", Cur_ZZTurnUp_State, " 【Dn】=", Cur_ZZTurnDn_State);
      //Print("K=", K, bolBuy,bolSell);
      //Print(" LB0>>",LBB0 - iClose(symb,PERIOD_M15,0) , "   LB1>>",LBB1 - iClose(symb,PERIOD_M15,1)," LB2>>",LBB2 - iClose(symb,PERIOD_M15,2));
      //Print("BBW>>",(UBB0-LBB0), "  OPEN=",iOpen(symb,PERIOD_M5,0),"  Ema1=", Ema1);
      //Print(symb," FuzzyScore=", FuzzyReturn(symb));
      //}
      
      bolStopBuy  = (bolSell && SymbLongProfits(symb,magic)>=0 );
      
      bolStopSell = (bolBuy && SymbShortProfits(symb,magic)>=0);
     
     ZZReturn_EA.Trade
      (
        magic,
        bolBuy,
        bolSell,
        bolStopBuy,
        bolStopSell
      );
   }
}

//+----------------------------------+
//|   FuzzyReturn()                  |
//+----------------------------------+
double FuzzyReturn(string symb)
{
      double K=0.0, CCI=0.0, RVI=0.0, fuzzy_return=0.0;  
      double Membership[3];
      
      //- Membership definition
      double aryK[3]   = {20,50,80};
      double aryCCI[3] = {-100,0,100};
      double aryRVI[3] = {-0.3, 0, 0.3};

      double aryWeight[3]  = {0.333, 0.333, 0.334};
            
      K = iStochastic(symb,PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,1);
      CCI = iCCI(symb,PERIOD_M15,12,PRICE_CLOSE,1); 
      RVI = iRVI(symb,PERIOD_M15,12,PRICE_CLOSE,1);
            
      ArrayInitialize(Membership,0);      

//1)=== K Membership ===(V-type membership function)=========
      if (K <  aryK[0]){
               Membership[0]=1.0;}
      if (K >= aryK[0] && K < aryK[1]){
               Membership[0]=1.0-(K-aryK[0])/(aryK[1]-aryK[0]);}
      if (K>=aryK[1] && K < aryK[2]){
               Membership[0]=(aryK[2]-K)/(aryK[2]-aryK[1]);}
      if (K>=aryK[2]){
               Membership[0]=1.0;}         
               
//2)=== CCI Membership ===(V-type membership function)=========     
      if ( CCI < aryCCI[0]){
               Membership[1]=1.0;}
      if (CCI >= aryCCI[0] && CCI < aryCCI[1]){
               Membership[1]=1.0-(CCI-aryCCI[0])/(aryCCI[1]-aryCCI[0]);}
      if (CCI>=aryCCI[1] && CCI < aryCCI[2]){
               Membership[1]=(aryCCI[2]-CCI)/(aryCCI[2]-aryCCI[1]);}
      if (CCI>=aryCCI[2]){
               Membership[1]=1.0;}         

//3)=== RVI Membership ===(V-type membership function)=========
      if ( RVI < aryRVI[0]){
               Membership[2]=1.0;}
      if (RVI >= aryRVI[0] && RVI < aryRVI[1]){
               Membership[2]=1.0-(RVI-aryRVI[0])/(aryRVI[1]-aryRVI[0]);}
      if (RVI>=aryRVI[1] && RVI < aryRVI[2]){
               Membership[2]=(aryRVI[2]-RVI)/(aryRVI[2]-aryRVI[1]);}
      if (RVI>=aryRVI[2]){
               Membership[2]=1.0;}         

//---Fuzzy Score  -------------------
    for(int a=0;a<=2;a++)
         {
            fuzzy_return = fuzzy_return + Membership[a] * aryWeight[a];
         }
   return fuzzy_return;
}

/*      
//+------------------------------------------------------------------+
//| getFasMa                                                         |
//+------------------------------------------------------------------+
double getFasMa(string symb, int Shift)
  {
   return iMA(symb, PERIOD_M15, 6, 0, MODE_SMA, PRICE_CLOSE, Shift);
  }
  
//+------------------------------------------------------------------+
//|   getSlowMa                                                      |
//+------------------------------------------------------------------+
double getSlowMa(string symb,int Shift)
  {
   return iMA(symb, PERIOD_M15, 12, 0, MODE_SMA, PRICE_CLOSE, Shift);
  }
*/

//+------------------------------------------------------------------+
//| CLOSE function                                                   |
//+------------------------------------------------------------------+
double CLOSE(string symb,int shift)
  {
   return iClose(symb,0, shift);
  }
/*
//+------------------------------------------------------------------+
//|    rhigh function                                                |
//+------------------------------------------------------------------+
double rhigh(string symb)
  {
   int cnt=3;
   return iHigh(symb, PERIOD_M15, iHighest(symb, PERIOD_M15, MODE_HIGH, cnt, 0));
  }

//+------------------------------------------------------------------+
//|      rlow  function                                              |
//+------------------------------------------------------------------+
double rlow(string symb)
  {
   int cnt=3;
   return   iLow(symb, PERIOD_M15, iLowest(symb, PERIOD_M15, MODE_LOW, cnt, 0));
  }
*/
//+------------------------------------------------------------------+
//|   macd_main function                                             |
//+------------------------------------------------------------------+
double macd_main(string symb,int shift)
  {
   int    MACD_FastEMA             = 12;
   int    MACD_SlowEMA             = 26;
   int    MACD_SignalPeriod        = 9;
   return iMACD(symb, PERIOD_M15, MACD_FastEMA, MACD_SlowEMA, MACD_SignalPeriod, PRICE_CLOSE, MODE_MAIN,shift);
  }

//+------------------------------------------------------------------+
//|   macd_signal function                                           |
//+------------------------------------------------------------------+
double macd_signal(string symb,int shift)
  {
   int    MACD_FastEMA             = 12;
   int    MACD_SlowEMA             = 26;
   int    MACD_SignalPeriod        = 9;
   return iMACD(symb, PERIOD_M15, MACD_FastEMA, MACD_SlowEMA, MACD_SignalPeriod, PRICE_CLOSE, MODE_SIGNAL, shift);
  }

//+------------------------------------------------------------------+
//| GetHeikenAshiTrend   function                                    |
//+------------------------------------------------------------------+
int GetHeikenAshiTrend(string symb,int shift)
  {
   int    MaMetod                  = 2;   //Smoothed
   int    MaPeriod                 = 6;   //
   int    MaMetod2                 = 2;   //3Linear-weighted
   int    MaPeriod2                = 2;   //
   double _open  = iCustom(symb, PERIOD_H1,"Heiken_Ashi_Smoothed", MaMetod, MaPeriod, MaMetod2, MaPeriod2, 4, shift);//4=open
   double _close = iCustom(symb, PERIOD_H1,"Heiken_Ashi_Smoothed", MaMetod, MaPeriod, MaMetod2, MaPeriod2, 5, shift);//5=close
   if(_close > _open) return(OP_BUY);
   return(OP_SELL);
  }
  

//+------------------------------------------------------------------+
//| ZZTurnUp_Check() function                                        |
//+------------------------------------------------------------------+
int ZZTurnUp_Check(string symb, int shift)
{
   int   period_TF1=15;    //ZZ短期
   int   period_TF2=30;    //ZZ中期
   int   period_TF3=60;    //ZZ長期
   int   ZZ_TurnUp_Level=0; 
   if (iCustom(symb,period_TF3,"ZigZag_3_Level",4,shift)>0 
         && iCustom(symb,period_TF2,"ZigZag_3_Level",4,shift)>0
         && iCustom(symb,period_TF1,"ZigZag_3_Level",4,shift)>0
      ) 
      {
         ZZ_TurnUp_Level=3;
      }
      else 
      if (iCustom(symb,period_TF2,"ZigZag_3_Level",4,shift)>0 
         && iCustom(symb,period_TF1,"ZigZag_3_Level",4,shift)>0)
         {
            ZZ_TurnUp_Level=2; 
         }
         else 
         if (iCustom(symb,period_TF1,"ZigZag_3_Level",4,shift)>0 ) 
            {
               ZZ_TurnUp_Level=1;
            }
            else 
               ZZ_TurnUp_Level=0;
      return(ZZ_TurnUp_Level);
}
//+------------------------------------------------------------------+
//| ZZTurnDn_Check() function                                   |
//+------------------------------------------------------------------+
int ZZTurnDn_Check(string symb, int shift)
{
   int   period_TF1=15;    //ZZ短期
   int   period_TF2=30;    //ZZ中期
   int   period_TF3=60;    //ZZ長期
   int   ZZ_TurnDn_Level=0; 
   if (iCustom(symb,period_TF3,"ZigZag_3_Level",5,shift)>0 
         && iCustom(symb,period_TF2,"ZigZag_3_Level",5,shift)>0
         && iCustom(symb,period_TF1,"ZigZag_3_Level",5,shift)>0
       ) 
      {
         ZZ_TurnDn_Level=3;
      }
      else 
      if (iCustom(symb,period_TF2,"ZigZag_3_Level",5,shift)>0 && iCustom(symb,period_TF1,"ZigZag_3_Level",5,shift)>0)
         {
            ZZ_TurnDn_Level=2; 
         }
         else 
         if (iCustom(symb,period_TF1,"ZigZag_3_Level",5,shift)>0)
            {
               ZZ_TurnDn_Level=1; 
            }
            else 
               ZZ_TurnDn_Level=0;
      return(ZZ_TurnDn_Level);
}


//+-------------------------------+
//|  get Fibonacci Take Profit    |
//+-------------------------------+
double EA::getTakeProfit(int magic, int type, double OpenPrice)
 {   
   string symb=EnumToString(ENUM_FX_PAIRS(StrToInteger(StringSubstr(IntegerToString(magic),1,1))));
   double price=0.0, tp=0.0;
   int idx = StrToInteger(StringSubstr(magic,1,1))-1; //idx=symb
   if (type == OP_BUY)
      {
         price= MathMax(OpenPrice,MarketInfo(symb,MODE_ASK));
         if (price<aryRS[idx,0])      tp=aryRS[idx,0];                                               
         if (price>=aryRS[idx,0] && price<aryRS[idx,1]) tp=aryRS[idx,1];
         if (price>=aryRS[idx,1] && price<aryRS[idx,2]) tp=aryRS[idx,2];
         if (price>=aryRS[idx,2] && price<aryRS[idx,3]) tp=aryRS[idx,3];
         if (price>=aryRS[idx,3] && price<aryRS[idx,4]) tp=aryRS[idx,4];
         if (price>=aryRS[idx,4] && price<aryRS[idx,5]) tp=aryRS[idx,5];
         if (price>=aryRS[idx,5] && price<aryRS[idx,6]) tp=aryRS[idx,6];
         if (price>=aryRS[idx,6] && price<aryRS[idx,7]) tp=aryRS[idx,7];
         if (price>=aryRS[idx,7] && price<aryRS[idx,8]) tp=aryRS[idx,8];
         if (price>=aryRS[idx,8])   tp=price+0.41*(aryRS[idx,4]-aryRS[idx,0]); 
         tp+=MarketInfo(symb,MODE_SPREAD)*pips_point;
     //Print(" symb=",symb," magic=",magic," Long_p=", OpenPrice, " price=",price," tp=",tp);
      }
   else 
   if (type == OP_SELL)
      {
         price = MathMin(OpenPrice,MarketInfo(symb,MODE_BID));
         if (price<aryRS[idx,0])    tp=price-0.41*(aryRS[idx,4]-aryRS[idx,0]);                                               
         if (price>=aryRS[idx,0] && price<aryRS[idx,1]) tp=aryRS[idx,0];
         if (price>=aryRS[idx,1] && price<aryRS[idx,2]) tp=aryRS[idx,1];
         if (price>=aryRS[idx,2] && price<aryRS[idx,3]) tp=aryRS[idx,2];
         if (price>=aryRS[idx,3] && price<aryRS[idx,4]) tp=aryRS[idx,3];
         if (price>=aryRS[idx,4] && price<aryRS[idx,5]) tp=aryRS[idx,4];
         if (price>=aryRS[idx,5] && price<aryRS[idx,6]) tp=aryRS[idx,5];
         if (price>=aryRS[idx,6] && price<aryRS[idx,7]) tp=aryRS[idx,6];
         if (price>=aryRS[idx,7] && price<aryRS[idx,8]) tp=aryRS[idx,7];
         if (price>=aryRS[idx,8])   tp=aryRS[idx,8]; 
         tp-=MarketInfo(symb,MODE_SPREAD)*pips_point;
     //Print(" symb=",symb," magic=",magic," Short_p=", OpenPrice, " price=",price," tp=",tp);
     }
    return tp;
 }

//+------------------------------------------------------------------+
//| Long trailing stop                                               |
//+------------------------------------------------------------------+
void EA::DoLongTrailingStop(int Ticket)
  {
   if(TrailingStop>0)
     {
      RefreshRates();
      int o20=OrderSelect(Ticket,SELECT_BY_TICKET);
      if(MarketInfo(Sym,MODE_BID)-OrderOpenPrice() > TrailingStop*pips_point)
        {
         if(MarketInfo(Sym,MODE_BID)-TrailingStop*pips_point > OrderStopLoss() || OrderStopLoss()==0)
           {
            bool o0=OrderModify(OrderTicket(),
                               OrderOpenPrice(),
                               MarketInfo(Sym,MODE_BID)-TrailingStop*pips_point,
                               OrderTakeProfit(),
                               0
                               );
           if (o0) Print(" Sym",OrderTicket()," DoLongTrailingStop succeed." );                    
           }
        }
     }
  }
  
//+------------------------------------------------------------------+
//| Short trailing stop                                              |
//+------------------------------------------------------------------+
void EA::DoShortTrailingStop(int Ticket)
  {
   if(TrailingStop>0)
     {
      RefreshRates();
      int o0=OrderSelect(Ticket,SELECT_BY_TICKET);
      if(OrderOpenPrice()-MarketInfo(Sym,MODE_ASK) > TrailingStop*pips_point)
        {
         if(OrderStopLoss() > MarketInfo(Sym,MODE_ASK)+TrailingStop*pips_point || OrderStopLoss()==0)
           {
            bool o02=OrderModify(OrderTicket(),
                                OrderOpenPrice(),
                                MarketInfo(Sym,MODE_ASK)+TrailingStop*pips_point,
                                OrderTakeProfit(),
                                0
                                );
           if (o0) Print(" Sym",OrderTicket()," DoShortTrailingStop succeed." );                    
           }
        }
     }
  }
 
//+--------------------------------------------------+
//|  Adjusting lot size fit to system specification  |
//+--------------------------------------------------+
double SpecifiedLot(string symb, double lot)
  {
   double minSysDeal_Vol = SymbolInfoDouble(symb,SYMBOL_VOLUME_MIN);//Minimal volume for a deal
   double maxSysDeal_Vol = SymbolInfoDouble(symb,SYMBOL_VOLUME_MAX);
   double minSysDealStep_Vol= SymbolInfoDouble(symb,SYMBOL_VOLUME_STEP);//Minimal volume change step for deal execution
   if(lot>0)
     {
      lot = MathMax(minSysDeal_Vol,lot);
      lot = MathMin(maxSysDeal_Vol,lot);
      lot = minSysDeal_Vol+NormalizeDouble((lot-minSysDeal_Vol)/minSysDealStep_Vol,0)*minSysDealStep_Vol;
     }
   else
      lot=0;
   return lot;
  }

//+------------------------------------------------------------------+
//| SymbLongProfits                                                  |
//+------------------------------------------------------------------+
double SymbLongProfits(string symb, int magic)
  {
   double profit=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==symb && OrderType()==OP_BUY && OrderMagicNumber()==magic)
           {
            profit=OrderProfit()+OrderCommission()+OrderSwap();
           }
        }
     }
   return(profit);
  }
  
//+------------------------------------------------------------------+
//| SymbShortProfits                                                  |
//+------------------------------------------------------------------+
double SymbShortProfits(string symb, int magic)
  {
   double profit=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES ))
        {
         if(OrderSymbol()==symb && OrderType()==OP_SELL && OrderMagicNumber()==magic)
           {
            profit=OrderProfit()+OrderCommission()+OrderSwap();
           }
        }
     }
   return(profit);
  }

//+----------------------------------------------------------+
//|      CloseOpenOrderByTicket                                   |
//+----------------------------------------------------------+
void CloseOpenOrderByTicket(int ticket)
{
  double close_return=0;
  int total = OrdersTotal();
  for(int i=total-1;i>=0;i--)
  {
    OrderSelect(i, SELECT_BY_POS);
    int type    = OrderType();
    bool result = false;

    if (OrderTicket()==ticket)
     {
        switch(type)
         {
           case OP_BUY       : result = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), Slippage, White);
                               break;
           case OP_SELL      : result = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), Slippage, White);
                               break;
           //Close pending orders
           //case OP_BUYLIMIT  : result = true ;
           //case OP_BUYSTOP   : result = true ;
           //case OP_SELLLIMIT : result = true ;
           //case OP_SELLSTOP  : result = true ;
         }
          //close_return=(OrderProfit()+OrderCommission()+OrderSwap());
          if(result == false)
          {
            //Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
            Print("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
            Sleep(3000);
          }  
      }
  }
  //return(close_return);  
}

//+------------------------------------------------------------------+
//| Dpi                                                              |
//+------------------------------------------------------------------+
int Dpi(int Size)
  {
   int screen_dpi=TerminalInfoInteger(TERMINAL_SCREEN_DPI);//192(Mac Retina) vs. 96
   int base_width=Size;
   int width=(base_width*screen_dpi)/192;
   int scale_factor=(TerminalInfoInteger(TERMINAL_SCREEN_DPI)*100)/192; //---adaption factor

   width=(base_width*scale_factor)/100;

   return(width);
  }  

//---------------------------------
bool CControlsDialog::UpdateLabelPos_1(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A1.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B1.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C1.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A1.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B1.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C1.Text(string(newText6)))return(false);
   return(true);
  }

//--------------------------------------------------------------------------------------------
bool CControlsDialog::UpdateLabelPos_2(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A2.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B2.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C2.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A2.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B2.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C2.Text(string(newText6)))return(false);
   return(true);
  }
//--------------------------------------------------------------------------------------------
bool CControlsDialog::UpdateLabelPos_3(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A3.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B3.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C3.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A3.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B3.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C3.Text(string(newText6)))return(false);
   return(true);
  }
//--#4--:UpdateLabelPos_4--BODY ---------------------------------------------
bool CControlsDialog::UpdateLabelPos_4(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A4.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B4.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C4.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A4.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B4.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C4.Text(string(newText6)))return(false);
   return(true);
  }

//--#5--:UpdateLabelPos_5--BODY ---------------------------------------------
bool CControlsDialog::UpdateLabelPos_5(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A5.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B5.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C5.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A5.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B5.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C5.Text(string(newText6)))return(false);
   return(true);
  }
  
//--#6--:UpdateLabelPos_6--BODY ---------------------------------------------
bool CControlsDialog::UpdateLabelPos_6(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A6.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B6.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C6.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A6.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B6.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C6.Text(string(newText6)))return(false);
   return(true);
  }

//--#99--:UpdateLabelPos_99--BODY ---------------------------------------------
bool CControlsDialog::UpdateLabelPos_99(string newText1,string newText2,string newText3,string newText4,string newText5,string newText6)
  {
   if(!m_labelShortProfits_A.Text(string(newText1)))return(false);
   if(!m_labelShortProfits_B.Text(string(newText2)))return(false);
   if(!m_labelShortProfits_C.Text(string(newText3)))return(false);
   if(!m_labelLongProfits_A.Text(string(newText4)))return(false);
   if(!m_labelLongProfits_B.Text(string(newText5)))return(false);
   if(!m_labelLongProfits_C.Text(string(newText6)))return(false);
   return(true);
  }

/*
//string  MODE = "none"; //trendLine mode
//double Bullish = EMPTY_VALUE, Bearish = EMPTY_VALUE, 
double ZigZagHigh[], ZigZagLow[],ZZ_LineLower=0,ZZ_LineUpper=0;
bool DrawLine = true;
int  First_Low_Candel=0,Secund_Low_Candel=3,First_High_Candel=0,Secund_High_Candel=3,ZigHCandel[],ZigLCandel[];
//+------------------------------------------------------------------+ 
//| ZigZag Highest And Lowest ZZ_TrendLine Show                      | 
//+------------------------------------------------------------------+ 
void ZZ_TrendLine(string symb, int Timeframe)
{
 ArrayResize(ZigZagHigh,ZigZagNum,1);
 ArrayResize(ZigZagLow,ZigZagNum,1);
 ArrayResize(ZigHCandel,ZigZagNum,1);
 ArrayResize(ZigLCandel,ZigZagNum,1);
 double z_high = -1, z_low = -1;
 double data=0;
 int    lowcount = 0, highcount = 0;

for (int i = 0; i < Bars; i++)
 {
   z_high = iCustom(symb,Timeframe, "ZigZag", InpDepth,InpDeviation,InpBackstep, 1, i);
   if ( (z_high > 0) && ( z_high == iCustom(symb,Timeframe, "ZigZag", InpDepth,InpDeviation,InpBackstep, 0, i)) ) 
   {
      ZigZagHigh[highcount] = z_high; ZigHCandel[highcount] = i; highcount++;
   }
   z_high = -1;
   if (highcount == ZigZagNum) break;
 }
 
 for (int i = 0; i < Bars; i++)
 {
   z_low = iCustom(symb,Timeframe, "ZigZag", InpDepth,InpDeviation,InpBackstep, 2, i);
   if ( (z_low > 0) && ( z_low == iCustom(symb,Timeframe, "ZigZag", InpDepth,InpDeviation,InpBackstep, 0, i)) ) 
   {
      ZigZagLow[lowcount] = z_low; ZigLCandel[lowcount] = i; lowcount++;
   }
   z_low = -1;
   if (lowcount == ZigZagNum) break;
 }
 
 
for (int j = 0; j <= ZigZagNum-1; j++) {
//ObjectDelete("Trend.ZigZagHigh."+IntegerToString(j));
   if(ObjectFind(0,"Trend.ZigZagHigh") < 0) {
   ObjectCreate(0,"Trend.ZigZagHigh."+IntegerToString(j),OBJ_ARROW,0,0,0,0,0);          // Create an arrow
   ObjectSetInteger(0,"Trend.ZigZagHigh."+IntegerToString(j),OBJPROP_ARROWCODE,238);    // Set the arrow code
   ObjectSetInteger(0,"Trend.ZigZagHigh."+IntegerToString(j),OBJPROP_COLOR,clrMagenta);  
   }  
   ObjectSetInteger(0,"Trend.ZigZagHigh."+IntegerToString(j),OBJPROP_TIME,Time[ZigHCandel[j]]);        // Set time
   ObjectSetDouble(0,"Trend.ZigZagHigh."+IntegerToString(j),OBJPROP_PRICE,ZigZagHigh[j]+(10+(Period()/100))*pips_point);// Set price
 } 
 

   for (int j = 0; j <= ZigZagNum-1; j++) {
      if(ObjectFind(0,"Trend.ZigZagLow") < 0) 
      {
         ObjectDelete("Trend.ZigZagLow."+IntegerToString(j));
         ObjectCreate(0,"Trend.ZigZagLow."+IntegerToString(j),OBJ_ARROW,0,0,0,0,0);          // Create an arrow
         ObjectSetInteger(0,"Trend.ZigZagLow."+IntegerToString(j),OBJPROP_ARROWCODE,236);    // Set the arrow code
         ObjectSetInteger(0,"Trend.ZigZagLow."+IntegerToString(j),OBJPROP_COLOR,clrAqua);
      }
   ObjectSetInteger(0,"Trend.ZigZagLow."+IntegerToString(j),OBJPROP_TIME,Time[ZigLCandel[j]]);        // Set time
   ObjectSetDouble(0,"Trend.ZigZagLow."+IntegerToString(j),OBJPROP_PRICE,ZigZagLow[j]-(10+(Period()/250))*pips_point);// Set price
 }
 
First_Low_Candel=0;  Secund_Low_Candel=3;
First_High_Candel=0; Secund_High_Candel=3;
 //MODE = "none";
 
/////////////////////////////////////////////////////////////////////////////////////////////
 if ( (highcount > 2) && (DrawLine == true))
 {
   //ObjectDelete("Trend.HighLine");
   ObjectCreate("Trend.HighLine", OBJ_TREND, 0, Time[ZigHCandel[Secund_High_Candel]],ZigZagHigh[Secund_High_Candel],Time[ZigHCandel[First_High_Candel]],ZigZagHigh[First_High_Candel]);
   ObjectSet   ("Trend.HighLine", OBJPROP_COLOR, Color_UPLine);
   ObjectSet   ("Trend.HighLine", OBJPROP_STYLE, STYLE_DASH);
   ObjectSet   ("Trend.HighLine", OBJPROP_WIDTH, 1);
   ObjectSet   ("Trend.HighLine", OBJPROP_RAY,   true);
   ObjectSet   ("Trend.HighLine", OBJPROP_BACK,  true);
 }
 if ( (lowcount > 2) && (DrawLine == true))
 {
   ObjectDelete("Trend.LowLine");
   ObjectCreate("Trend.LowLine", OBJ_TREND, 0, Time[ZigLCandel[Secund_Low_Candel]],ZigZagLow[Secund_Low_Candel],Time[ZigLCandel[First_Low_Candel]],ZigZagLow[First_Low_Candel]);
   ObjectSet   ("Trend.LowLine", OBJPROP_COLOR, Color_DWLine);
   ObjectSet   ("Trend.LowLine", OBJPROP_STYLE, STYLE_DASH);
   ObjectSet   ("Trend.LowLine", OBJPROP_WIDTH, 1);
   ObjectSet   ("Trend.LowLine", OBJPROP_RAY,   true);
   ObjectSet   ("Trend.LowLine", OBJPROP_BACK,  true);
 }
}
*/