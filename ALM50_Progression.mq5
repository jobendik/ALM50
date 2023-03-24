//+------------------------------------------------------------------+
//|                                       CustomDottedLinesEA.mq5    |
//|                        Copyright 2023, Your Name.                |
//|                                             Your Company Name    |
//+------------------------------------------------------------------+

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
double priceLevels[];
CTrade trade;

int OnInit()
{

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
   for (int i = -NumLines; i <= NumLines; ++i)
   {
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


void OnTick()
{
    static int prevPositions = 0;

    static double prevAsk = 0;
    static double prevBid = 0;
    static int lastBuyLevel = -1;
    static int lastSellLevel = -1;
    static bool firstTick = true;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    if (firstTick)
    {
        prevAsk = ask;
        prevBid = bid;
        firstTick = false;
        return;
    }

    int currentPositionCount = PositionsTotal();
if (currentPositionCount < prevPositions)
{
    // A position was closed
// A position was closed
double lastClosedProfit = 0.0;

for (int i = prevPositions - 1; i >= 0; --i)
{
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol)
    {
        MqlTradeCheckResult result;
        MqlTradeRequest request;
        MqlTradeResult trade_result;

        request.action = TRADE_ACTION_DEAL;
        request.symbol = _Symbol;
        request.volume = 0.0;
        request.price = 0.0;
        request.sl = 0.0;
        request.tp = 0.0;
        request.deviation = 0;
        request.type_filling = ORDER_FILLING_FOK;
        request.type_time = ORDER_TIME_GTC;
        request.magic = ExpertMagicNumber;

        if (!HistorySelectByPosition(ticket))
            continue;

        int deals = HistoryDealsTotal();
        double deal_profit, deal_swap, deal_commission;
        for (int j = deals - 1; j >= 0; j--)
        {
            ulong deal_ticket = HistoryDealGetTicket(j);
            if (HistoryDealSelect(deal_ticket))
            {
                deal_profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
                deal_swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
                deal_commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);

                if (HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID) == ticket)
                {
                    lastClosedProfit = deal_profit + deal_swap + deal_commission;
                    break;
                }
            }
        }

        // Update wins or losses counter based on lastClosedProfit
// Get the current profit of the trade (if any)
double currentProfit = 0.0;
if (OrderExists(POSITION_TYPE_BUY))
{
    currentProfit = PositionGetDouble(POSITION_PROFIT);
}
else if (OrderExists(POSITION_TYPE_SELL))
{
    currentProfit = -PositionGetDouble(POSITION_PROFIT);
}

// If the current profit is positive, consider it a win
if (currentProfit > 0)
{
    wins++;
    losses = 0;
}
// If the current profit is negative, consider it a loss
else if (currentProfit < 0)
{
    wins = 0;
    losses++;
}

// Reset wins and losses if the progression is completed or lost
if (wins == ArrayRange(progression_table, 0) || losses == ArrayRange(progression_table, 1))
{
    wins = 0;
    losses = 0;
}

// Print the current win/loss status
if (wins == 0 && losses == 0)
{
    Print("Progression started");
}
else if (wins == ArrayRange(progression_table, 0))
{
    Print("Progression completed. All levels reached. Wins: ", wins, ", Losses: ", losses);
}
else if (losses == ArrayRange(progression_table, 1))
{
    Print("Progression lost. Maximum losses reached. Wins: ", wins, ", Losses: ", losses);
}
else
{
    double currentRiskPercentage = progression_table[losses][wins] * 100;
    Print("Progression: ", wins, " wins, ", losses, " losses. Current risk: ", currentRiskPercentage, "%");
}
    }
}
Print("Last closed position profit: ", lastClosedProfit); // Print last closed profit
    if (lastClosedProfit > 0)
    {
        wins++;
        losses = 0;
    }
    else
    {
        wins = 0;
        losses++;
    }
        // Reset wins and losses if the progression is completed or lost
if (wins == ArrayRange(progression_table, 0) || losses == ArrayRange(progression_table, 1))
        {
            wins = 0;
            losses = 0;
        }
          
   if (wins == 0 && losses == 0) {
    Print("Progression started");
}       
          
           // Progression completed
   if (wins == ArrayRange(progression_table, 0))
   {
       Print("Progression completed. All levels reached. Wins: ", wins, ", Losses: ", losses);
   }
   // Progression lost
   else if (losses == ArrayRange(progression_table, 1))
   {
       Print("Progression lost. Maximum losses reached. Wins: ", wins, ", Losses: ", losses);
   }

    }
    prevPositions = currentPositionCount;

    if (PositionsTotal() == 0)
    {
        for (int i = 0; i < ArraySize(priceLevels); ++i)
        {
            double level = priceLevels[i];

            // Check if price crossed the level from below (buy condition)
    if (prevAsk < level && ask >= level && i != lastBuyLevel)            {
                lastBuyLevel = i;

                double sl = ask - PipsDistance * SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
                double tp = 0; // No take profit

double lotSize = calculateLotSize(); // Calculate lot size based on risk
                //Print("Buy order placed. Level: ", level, " Lot size: ", lotSize, " SL: ", sl, " TP: ", tp); // Added print statement
                trade.Buy(lotSize, _Symbol, ask, sl, tp);
            }
            // Check if price crossed the level from above (sell condition)
else if (prevBid > level && bid <= level && i != lastSellLevel)            {
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
    if (OrderExists(POSITION_TYPE_BUY))
    {
        ModifyStopLoss();
    }
    if (OrderExists(POSITION_TYPE_SELL))
    {
        ModifyStopLoss();
    }

    prevAsk = ask;
    prevBid = bid;
    
    // Check if the price moves beyond the current levels and create new levels if necessary
    double highestLevel = priceLevels[ArraySize(priceLevels) - 1];
    double lowestLevel = priceLevels[0];

    if (ask > highestLevel)
    {
        //Print("Creating new levels above the current price"); // Added print statement
        CreateNewLevels(ask, true);
    }
    else if (bid < lowestLevel)
    {
        //Print("Creating new levels below the current price"); // Added print statement
        CreateNewLevels(bid, false);
    }
}













bool OrderExists(ENUM_POSITION_TYPE type)
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (PositionGetInteger(POSITION_TYPE) == type && PositionGetString(POSITION_SYMBOL) == _Symbol)
      {
         return true;
      }
   }
   return false;
}

  
double calculateLotSize()
{
    if (losses > 5) losses = 5;
    if (wins > 4) wins = 4;

    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double progressionRisk = accountBalance * 0.01; // Allocate 1% of account balance as progression risk
double requiredRisk = progression_table[losses][wins] * progressionRisk;
    double riskPerPoint = requiredRisk / PipsDistance;

double lotSize = progression_table[losses][wins] * progressionRisk / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * _lot_digits * _leverage);

    double minVolumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    /*Print("Account balance: ", accountBalance);
    Print("Progression risk: ", progressionRisk);
    Print("Required risk: ", requiredRisk);
    Print("Risk per point: ", riskPerPoint);
    Print("Lot size: ", lotSize);*/
    
    //Print("Progression: ", wins, " wins, ", losses, " losses");
   // Print("Current risk: ", riskPerPoint, " per point");
   double currentRiskPercentage = progression_table[losses][wins] * 100;
    Print("Progression: ", wins, " wins, ", losses, " losses, Current Risk Percentage: ", currentRiskPercentage, "% ", "Lot Size: ", riskPerPoint);
Print("Account Balance: ", accountBalance);

    return NormalizeDouble(riskPerPoint, 2);
}






void CreateNewLevels(double price, bool isAbove)
{
    double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    while (isAbove ? price > priceLevels[ArraySize(priceLevels) - 1] : price < priceLevels[0])
    {
        int newIndex = isAbove ? ArraySize(priceLevels) : 0;
        double newPrice = isAbove ? priceLevels[newIndex - 1] + PipsDistance * pointSize * 10
                                  : priceLevels[0] - PipsDistance * pointSize * 10;

        if (isAbove)
        {
            ArrayResize(priceLevels, ArraySize(priceLevels) + 1);
            priceLevels[newIndex] = newPrice;
        }
        else
        {
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



void ModifyStopLoss()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if (PositionGetString(POSITION_SYMBOL) == _Symbol)
        {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);

            int nearestIndex = -1;
            double minDistance = DBL_MAX;

            for (int j = 0; j < ArraySize(priceLevels); ++j)
            {
                double distance = 0;
                if (type == POSITION_TYPE_BUY)
                {
                    distance = currentPrice - priceLevels[j];
                }
                else if (type == POSITION_TYPE_SELL)
                {
                    distance = priceLevels[j] - currentPrice;
                }

                if (distance > 0 && distance < minDistance)
                {
                    minDistance = distance;
                    nearestIndex = j;
                }
            }

            if (nearestIndex != -1)
            {
                int nextIndex = (type == POSITION_TYPE_BUY) ? nearestIndex - 1 : nearestIndex + 1;

                if (nextIndex >= 0 && nextIndex < ArraySize(priceLevels))
                {
                    double pipsToNextLevel = MathAbs((priceLevels[nextIndex] - currentPrice) / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10));

                    if (pipsToNextLevel >= PipsDistance)
                    {
                        double newStopLoss = priceLevels[nextIndex];

                        // Round the new stop loss value
                        int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
                        newStopLoss = NormalizeDouble(newStopLoss, digits);

                        if (type == POSITION_TYPE_BUY && currentSL < newStopLoss)
                        {
                            trade.PositionModify(ticket, newStopLoss, currentTP);
                            // Get the current profit of the trade
double currentProfit = PositionGetDouble(POSITION_PROFIT);

// If the current profit is positive, consider it a win
if (currentProfit > 0)
{
    wins++;
    losses = 0;
}
// If the current profit is negative, consider it a loss
else if (currentProfit < 0)
{
    wins = 0;
    losses++;
}

// Reset wins and losses if the progression is completed or lost
if (wins == ArrayRange(progression_table, 0) || losses == ArrayRange(progression_table, 1))
{
    wins = 0;
    losses = 0;
}

// Print the current win/loss status
if (wins == 0 && losses == 0)
{
    Print("Progression started");
}
else if (wins == ArrayRange(progression_table, 0))
{
    Print("Progression completed. All levels reached. Wins: ", wins, ", Losses: ", losses);
}
else if (losses == ArrayRange(progression_table, 1))
{
    Print("Progression lost. Maximum losses reached. Wins: ", wins, ", Losses: ", losses);
}
else
{
    double currentRiskPercentage = progression_table[losses][wins] * 100;
    Print("Progression: ", wins, " wins, ", losses, " losses, Current Risk Percentage: ", currentRiskPercentage, "%");
}

                        }
                        else if (type == POSITION_TYPE_SELL && currentSL > newStopLoss)
                        {
                            trade.PositionModify(ticket, newStopLoss, currentTP);
                            // Get the current profit of the trade
double currentProfit = PositionGetDouble(POSITION_PROFIT);

// If the current profit is positive, consider it a win
if (currentProfit > 0)
{
    wins++;
    losses = 0;
}
// If the current profit is negative, consider it a loss
else if (currentProfit < 0)
{
    wins = 0;
    losses++;
}

// Reset wins and losses if the progression is completed or lost
if (wins == ArrayRange(progression_table, 0) || losses == ArrayRange(progression_table, 1))
{
    wins = 0;
    losses = 0;
}

// Print the current win/loss status
if (wins == 0 && losses == 0)
{
    Print("Progression started");
}
else if (wins == ArrayRange(progression_table, 0))
{
    Print("Progression completed. All levels reached. Wins: ", wins, ", Losses: ", losses);
}
else if (losses == ArrayRange(progression_table, 1))
{
    Print("Progression lost. Maximum losses reached. Wins: ", wins, ", Losses: ", losses);
}
else
{
Print("Wins: ", wins);
Print("Losses: ", losses);
Print("Rows: ", ArrayRange(progression_table, 0));
Print("Columns: ", ArrayRange(progression_table, 1));

    double currentRiskPercentage = progression_table[losses][wins] * 100;

    Print("Range of progression table - Rows: ", ArrayRange(progression_table, 0), ", Columns: ", ArrayRange(progression_table, 1));
    Print("Progression: ", wins, " wins, ", losses, " losses, Current Risk Percentage: ", currentRiskPercentage, "%");
    Print("Progression table size: rows=", ArrayRange(progression_table, 0), ", columns=", ArrayRange(progression_table, 0));

}

                        }
                    }
                }
            }
        }
    }
}
