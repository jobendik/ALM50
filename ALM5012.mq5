#property copyright "Copyright 2023, Your Name."
#property link      "https://www.example.com"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Arrays\ArrayObj.mqh>
input double BasePrice = 1.12500; // Base price for the dotted lines
input int NumLines = 50; // Number of lines above and below the base price
input int PipsDistance = 50; // Distance between lines in pips
input double Lots = 0.01; // Order size in lots
input double RiskPerTrade = 0.1; // Risk per trade as a percentage of account balance
// Declare the progression_table as a global variable
double progression_table[6][5];
int _leverage = 50; // Leverage value, adjust according to your account settings
int _lot_digits = 2; // Number of digits for lot size, usually 2 for most brokers
int ExpertMagicNumber = 123456;
// Initialize wins and losses
int wins = 0;
int losses = 0;
bool stopLossModified = false;
int prevPositions = 0;
double priceLevels[];
CTrade trade;
int OnInit(){
double temp[6][5] = {
    {0.1975, 0.1755, 0.1317, 0.0752, 0.0251},
    {0.2194, 0.2194, 0.1881, 0.1254, 0.0502},
    {0.2194, 0.2508, 0.2508, 0.2006, 0.1003},
    {0.1881, 0.2508, 0.3009, 0.3009, 0.2006},
    {0.1254, 0.2006, 0.3009, 0.4013, 0.4013},
    {0.0502, 0.1003, 0.2006, 0.4013, 0.8025}
};
ArrayCopy(progression_table, temp);
   // Get the correct pip size for the current symbol
   double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   // Draw the lines and store the price levels in an array
   ArrayResize(priceLevels, 2 * NumLines + 1);
   for (int i = -NumLines; i <= NumLines; ++i){
      double price = BasePrice + i * PipsDistance * pointSize * 10;
      priceLevels[i + NumLines] = price;
      string lineName = "DottedLine_" + IntegerToString(i + NumLines);
      ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrBlue);
   }
   return(INIT_SUCCEEDED);
}

void OnTick(){
    static double prevAsk = 0;
    static double prevBid = 0;
    static int lastBuyLevel = -1;
    static int lastSellLevel = -1;
    static bool firstTick = true;
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if (firstTick){
        prevAsk = ask;
        prevBid = bid;
        firstTick = false;
        return;
    }
    if (PositionsTotal() == 0){
        for (int i = 0; i < ArraySize(priceLevels); ++i){
            double level = priceLevels[i];

    // Check if price crossed the level from below (buy condition)
if (prevAsk < level && ask >= level && i != lastBuyLevel){
      lastBuyLevel = i;
      double sl = ask - PipsDistance * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
      double tp = 0; // No take profit
      double lotSize = calculateLotSize(); // Calculate lot size based on risk
         
         //Print("Buy order placed. Level: ", level, " Lot size: ", lotSize, " SL: ", sl, " TP: ", tp); // Added print statement
         trade.Buy(lotSize, _Symbol, ask, sl, tp);
         }
         // Check if price crossed the level from above (sell condition)
else if (prevBid > level && bid <= level && i != lastSellLevel){
            lastSellLevel = i;
            double sl = bid + PipsDistance * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
            double tp = 0; // No take profit
            double lotSize = calculateLotSize(); // Calculate lot size based on risk
            //Print("Sell order placed. Level: ", level, " Lot size: ", lotSize, " SL: ", sl, " TP: ", tp); // Added print statement
            trade.Sell(lotSize, _Symbol, bid, sl, tp);
            }
        }
    }
// Update stop loss if necessary
    bool buyStopLossHit = false;
    bool sellStopLossHit = false;
    if (OrderExists(POSITION_TYPE_BUY)){
        buyStopLossHit = ModifyStopLoss();
    }
    if (OrderExists(POSITION_TYPE_SELL)){
        sellStopLossHit = ModifyStopLoss();
    }
    
    if (buyStopLossHit || sellStopLossHit){
        if (buyStopLossHit && losses < 5) losses++;
        if (sellStopLossHit && wins < 4) wins++;
        printWinLossStatus();
    }

    prevAsk = ask;
    prevBid = bid;
      
    // Check if the price moves beyond the current levels and create new levels if necessary
    double highestLevel = priceLevels[ArraySize(priceLevels) - 1];
    double lowestLevel = priceLevels[0];

    if (ask > highestLevel){
        //Print("Creating new levels above the current price"); // Added print statement
        CreateNewLevels(ask, true);
    }
    else if (bid < lowestLevel){
        //Print("Creating new levels below the current price"); // Added print statement
        CreateNewLevels(bid, false);
    }
}


void printWinLossStatus() {
// Print the current win/loss status
if (wins == 0 && losses == 0){
    Print("Progression started");
}else if (wins == ArrayRange(progression_table, 0)){
    Print("Progression completed. All levels reached. Wins: ", wins, ", Losses: ", losses);
}else if (losses == ArrayRange(progression_table, 0) - 1){
    Print("Progression lost. Maximum losses reached. Wins: ", wins, ", Losses: ", losses);
}else{
    double currentRiskPercentage = progression_table[losses][wins] * 100;
    Print("Progression: ", wins, " wins, ", losses, " losses. Current risk: ", NormalizeDouble(currentRiskPercentage, 2), "% ", "Lot size: ");
}
}

bool OrderExists(ENUM_POSITION_TYPE type){
   for (int i = PositionsTotal() - 1; i >= 0; i--){
      ulong ticket = PositionGetTicket(i);
      if (PositionGetInteger(POSITION_TYPE) == type && PositionGetString(POSITION_SYMBOL) == _Symbol){
         return true;
      }
   }
   return false;
}
 
double calculateLotSize(){
    if (losses > 5) losses = 5;
    if (wins > 4) wins = 4;

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double progressionRisk = accountBalance * 0.01; // Allocate 1% of account balance as progression risk
   double requiredRisk = progression_table[losses][wins] * progressionRisk;
   double riskPerPoint = requiredRisk / PipsDistance;
   double lotSize = progression_table[losses][wins] * progressionRisk / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * _lot_digits * _leverage);
   double minVolumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double currentRiskPercentage = progression_table[losses][wins] * 100;
   Print("Progression: ", wins, " wins, ", losses, " losses, Current Risk Percentage: ", currentRiskPercentage, "% ", "Lot Size: ", riskPerPoint);
   Print("Account Balance: ", accountBalance);
   return NormalizeDouble(riskPerPoint, 2);
}

void CreateNewLevels(double price, bool isAbove){
    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    while (isAbove ? price > priceLevels[ArraySize(priceLevels) - 1] : price < priceLevels[0]){
        int newIndex = isAbove ? ArraySize(priceLevels) : 0;
        double newPrice = isAbove ? priceLevels[newIndex - 1] + PipsDistance * pointSize * 10
                                  : priceLevels[0] - PipsDistance * pointSize * 10;

        if (isAbove){
            ArrayResize(priceLevels, ArraySize(priceLevels) + 1);
            priceLevels[newIndex] = newPrice;
        }
        else{
            ArrayResize(priceLevels, ArraySize(priceLevels) + 1, 0);
            priceLevels[0] = newPrice;
        }
        string lineName = "DottedLine_" + IntegerToString(newIndex);
        ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, newPrice);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrBlue);
    }
}

bool ModifyStopLoss(){
    bool stopLossHit = false;

    for (int i = PositionsTotal() - 1; i >= 0; i--){
        ulong ticket = PositionGetTicket(i);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if (PositionGetString(POSITION_SYMBOL) == _Symbol){
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);

            int nearestIndex = -1;
            double minDistance = DBL_MAX;

            for (int j = 0; j < ArraySize(priceLevels); ++j){
                double distance = 0;
                if (type == POSITION_TYPE_BUY){
                    distance = currentPrice - priceLevels[j];
                }else if (type == POSITION_TYPE_SELL){
                    distance = priceLevels[j] - currentPrice;
                }
                if (distance > 0 && distance < minDistance){
                    minDistance = distance;
                    nearestIndex = j;
                }
            }

            if (nearestIndex != -1){
                int nextIndex = (type == POSITION_TYPE_BUY) ? nearestIndex - 1 : nearestIndex + 1;
                if (nextIndex >= 0 && nextIndex < ArraySize(priceLevels)){
                    double pipsToNextLevel = MathAbs((priceLevels[nextIndex] - currentPrice) / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10));

                    if (pipsToNextLevel >= PipsDistance){
                        double newStopLoss = priceLevels[nextIndex];

                        // Round the new stop loss value
                        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
                        newStopLoss = NormalizeDouble(newStopLoss, digits);

                        if (type == POSITION_TYPE_BUY && currentSL < newStopLoss){
                            trade.PositionModify(ticket, newStopLoss, currentTP);
                            stopLossHit = true;
                            if (losses >= 5){
            losses = 0;
            wins = 0;
            Print("Progression counter reset after reaching maximum losses.");
        }
                        }else if (type == POSITION_TYPE_SELL && currentSL > newStopLoss){
                            trade.PositionModify(ticket, newStopLoss, currentTP);
                            stopLossHit = true;
                            if (wins >= 4){
            losses = 0;
            wins = 0;
            Print("Progression counter reset after reaching maximum wins.");
        }
                        }
                    }
                }
            }
        }
    }
    return stopLossHit;
}
