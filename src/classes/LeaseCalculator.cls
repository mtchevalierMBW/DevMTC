/**
 * LeaseCalculator
 * Tested by: LeaseCalculator_TEST
 * Date: Aug 9, 2017
 * Programmer: Bryan Leaman
 *
 * Test coverage: 
 *  2017-08-10  LeaseCalculator_TEST    93% (148/158)
 *  2017-09-07  LeaseCalculator_TEST    96% (161/167)
 *  2017-10-06  LeaseCalculator_TEST    96% (174/181)
 * 
 */
public with sharing class LeaseCalculator {

    public Decimal SalesPrice {get;set;}
    public Decimal Residual {get;set;}
    public Decimal SalesTaxPct {get;set;}
    public Decimal AcquisitionFee {get;set;}
    public Decimal LeaseTerm {get;set;}
    public Decimal MoneyFactor {get;set;}
    public Decimal Deposit {get;set;} 
    public Decimal DownPayment {get;set;} 
    public Decimal OutsideFunding {get;set;}
    public Decimal TaxExemptFunding {get;set;} 
    public Decimal TradeAllowance {get;set;}
    public Decimal TradePayoff {get;set;}
    public Decimal Discounts {get;set;} 
    public Decimal TaxExemptDiscounts {get;set;}
    public Decimal Additions {get;set;}
    public Decimal SalesTax {get;set;}
    public String SalesTaxMethod {get;set;}
    public Decimal UpFrontSalesTax {get;set;}
    public Decimal MonthlySalesTax {get;set;}
    public Decimal TaxOnCostReduction {get;set;}
    public Decimal DispositionFee {get;set;}
    public String SalesTaxHandling {get;set;}

    public Decimal Depreciation {get;set;}
    public Decimal AdjustedCapCostBeforeTax {get;set;}
    public Decimal AdjustedCapCost {get;set;}
    public Decimal MonthlyUnitCharge {get;set;}
    public Decimal RentBase {get;set;}
    public Decimal MonthlyRentBeforeTax {get;set;}
    public Decimal TotalRentCharge {get;set;}
    public Decimal MonthlyRentCharge {get;set;}
    public Decimal MonthlyPmtBeforeTax {get;set;}
    public Decimal MonthlyPayment {get;set;}
    
    public Decimal TotalOfPaymentsBeforeTax {get;set;}
    public Decimal TotalOfPayments {get;set;}

    public Decimal CapCostReduction {get;private set;}
    public Decimal TotalUpFrontCash {get;private set;}

    private dealer__Deal__c deal;

    // LeaseCalculator
    //---------------------------------------
    public LeaseCalculator() { 
        System.debug('LeaseCalculator constructor/exit');
    }
    public LeaseCalculator(Id dealId) {
        System.debug('LeaseCalculator(dealId) constructor');
        Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Deal__c.SObjectType.getDescribe().fields.getMap();
        List<String> objFieldList = new List<String>();
        for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
        
        // additional fields expected by AvaTax_MBW
        objFieldList.add('dealer__Vehicle__r.Name');
        objFieldList.add('dealer__Vehicle__r.dealer__Make__c');
        objFieldList.add('dealer__Vehicle__r.New_Used_Other__c');
        objFieldList.add('dealer__Buyer__r.Name');
        
        String objfields = String.join(objFieldList,',');
        String soql = 'select ' + objfields + ' from dealer__Deal__c where Id=\'' + dealId + '\' ';
        List<dealer__Deal__c> deals = Database.query(soql);
        if (deals.size()>0) 
            this(deals[0]);
        System.debug('LeaseCalculator(dealId) exit');
    }
    public LeaseCalculator(dealer__Deal__c obj) {
        System.debug('LeaseCalculator(deal) constructor');
        deal = obj;

        //AvaTax_MBW tax = AvaTax_MBW.getInstanceDealId(deal.Id);
        AvaTax_MBW tax = AvaTax_MBW.getInstanceDeal(deal);

        System.debug('after AvaTax_MBW setup');
        SalesPrice = deal.Chassis_Price__c + deal.Conversion_Price__c;
        Additions = nullZero(deal.Total_Additional_Equipment__c) + nullZero(deal.Total_Protection_Products__c)
            + nullZero(deal.dealer__Total_Fees__c) - nullZero(deal.dealer__Sales_Tax__c) - nullZero(deal.LeaseAcquisitionFee__c);       
        Residual = nullZero(deal.ChassisResidualAmt__c) + nullZero(deal.ConversionResidualAmt__c);
        SalesTaxPct = nullZero(deal.Chassis_tax_rate__c);
        AcquisitionFee = nullZero(deal.LeaseAcquisitionFee__c);
        LeaseTerm = nullZero(deal.Contract_Number_of_Payments__c);
        MoneyFactor = nullZero(deal.LeaseMoneyFactor__c);
        Deposit = nullZero(deal.dealer__Deposit__c);
        DownPayment = nullZero(deal.dealer__Down_Pymt__c);
        TaxExemptFunding = nullZero(deal.AutoGrant__c);
        OutsideFunding = nullZero(deal.dealer__Deferred_Down_1__c)
            + nullZero(deal.dealer__Deferred_Down_2__c) + nullZero(deal.dealer__Deferred_Down_3__c);
        TradeAllowance = nullZero(deal.dealer__Trade_Allowance__c);
        TradePayoff = nullZero(deal.dealer__Trade_Payoff__c);
        Discounts = nullZero(deal.dealer__Rebate__c) + nullZero(deal.Rebate_2__c) + nullZero(deal.Rebate_3__c)
            + nullZero(deal.MBW_Rewards__c) + nullZero(deal.Conversion_Discount__c);
        TaxExemptDiscounts = 0; 
        SalesTaxMethod = tax.getLeaseTaxMethod();
        UpFrontSalesTax = nullZero(deal.dealer__Sales_Tax__c);  // in lieu of LeaseUpfrontSalesTax__c ?
        MonthlySalesTax = nullZero(deal.LeaseMonthlySalesTax__c);
        DispositionFee = nullZero(deal.LeaseDispositionFee__c);
        SalesTaxHandling = deal.LeaseSalesTaxHandling__c;
        System.debug('LeaseCalculator exit');
    }

    public Decimal nullZero(Decimal d) {
        return d==null ? 0 : d;
    }

    // returns monthly pmt amt
    public void calculate() {
        System.debug('calculate');
        CapCostReduction =  nullZero(DownPayment) + nullZero(Deposit) + nullZero(OutsideFunding) + nullZero(TaxExemptFunding) + nullZero(TradeAllowance) - nullZero(TradePayoff) 
            + Discounts + TaxExemptDiscounts;
        AdjustedCapCostBeforeTax = nullZero(SalesPrice) + nullZero(Additions) + nullZero(AcquisitionFee) - CapCostReduction;
        Depreciation = AdjustedCapCostBeforeTax - nullZero(Residual);
        MonthlyUnitCharge = Depreciation / LeaseTerm;   // ?? round here or after adding into final pmt amt? 
        RentBase = AdjustedCapCostBeforeTax + nullZero(Residual);
        MonthlyRentBeforeTax = RentBase * MoneyFactor;  // ?? round here or after combining into final pmt?

        MonthlyRentBeforeTax = MonthlyRentBeforeTax.setScale(2);
        MonthlyUnitCharge = MonthlyUnitCharge.setScale(2);
        
        MonthlyPmtBeforeTax = MonthlyRentBeforeTax + MonthlyUnitCharge;
        MonthlyPmtBeforeTax = MonthlyPmtBeforeTax.setScale(2);
        TotalOfPaymentsBeforeTax = MonthlyPmtBeforeTax * LeaseTerm;

        System.debug('calculate:sales tax processes...' + SalesTaxMethod);
        // Sales tax processes - default to Avalara's taxes
        SalesTax = nullZero(deal!=null ? deal.dealer__Sales_Tax__c : 0);
        MonthlySalesTax = 0;

        //if (SalesTaxMethod=='Up-front') {
            // use Avalara-calculated sales tax (or override sales tax)
            //SalesTax = nullZero(deal.dealer__Sales_Tax__c);
            //MonthlySalesTax = 0;
        //}
        if (SalesTaxMethod=='Monthly') {
            SalesTax = 0;
            MonthlySalesTax = SalesTaxPct/100 * MonthlyPmtBeforeTax;
            MonthlySalesTax = MonthlySalesTax.setScale(2);
            // ?? set sales tax override to 1 month? 
            // ?? or $0 because BancLease is going to pay it all
        }
        if (SalesTaxMethod=='Monthly Up-front') {
            SalesTax = SalesTaxPct/100 * (TotalofPaymentsBeforeTax+Deposit+DownPayment-MonthlyPmtBeforeTax);
            SalesTax = SalesTax.setScale(2);
        }
        MonthlyRentCharge = MonthlyRentBeforeTax;   // default
        if (SalesTaxMethod!='Monthly' && SalesTaxHandling=='Capitalized') {
            if (SalesTax!=null && SalesTax!=0) {
                MonthlyRentCharge = (RentBase+SalesTax) * MoneyFactor;
            }
        }
        UpfrontSalesTax = nullZero(SalesTax);

        System.debug('calculate:monthly payment');
        //System.debug(MonthlyRentCharge);
        //System.debug(MonthlyUnitCharge);
        //System.debug(LeaseTerm);
        //System.debug(SalesTax);
        MonthlyPayment = MonthlyRentCharge + MonthlyUnitCharge;
        if (SalesTaxMethod=='Monthly') MonthlyPayment += (SalesTax/LeaseTerm);
        MonthlyPayment = MonthlyPayment.setScale(2);
 
        System.debug('calculate:round results');
        //MonthlyUnitCharge = MonthlyUnitCharge.setScale(2);
        //MonthlyRentBeforeTax = MonthlyRentBeforeTax.setScale(2);
        MonthlyRentCharge = MonthlyRentCharge.setScale(2);
        TotalRentCharge = MonthlyRentCharge * LeaseTerm;
        TotalRentCharge = TotalRentCharge.setScale(2);
        
        System.debug('calculate:Totals');
        TotalOfPayments = MonthlyPayment * LeaseTerm;
        TotalOfPayments = TotalOfPayments.setScale(2);

        System.debug('calculate:Tax on cost reduction');
        if (TaxOnCostReduction!=null) {
            TaxOnCostReduction = SalesTaxPct/100 * (Deposit + DownPayment + OutsideFunding + Discounts);
            TaxOnCostReduction = TaxOnCostReduction.setScale(2);
        }
        
        System.debug('calculate:total up front cash');
        // If sales tax is capitalized, if not, then it's just additional required money down
        AdjustedCapCost = AdjustedCapCostBeforeTax;
        if (SalesTaxHandling=='Capitalized') ADjustedCapCost += UpfrontSalesTax;
        // Need to add in up front sales tax if NOT capitalized
        TotalUpfrontCash = DownPayment + Deposit + MonthlyPayment + nullZero(TaxOnCostReduction);
        if (SalesTaxHandling!='Capitalized') TotalUpfrontCash += SalesTax;
        TotalUpfrontCash = TotalUpfrontCash.setScale(2);
    }

    // returns monthly pmt amt 
    public void setTotalUpFrontCash(Decimal desiredupfront) {
        System.debug('Set total up front cash to ' + String.valueOf(desiredupfront));
        calculate();
        
        if (desiredupfront<MonthlyPayment) {
            throw new LeaseException('The upfront amount must meet or exceed 1 payment');
        }
        Decimal diff = desiredupfront - TotalUpfrontCash;
        Decimal direction = Math.signum(diff);
        System.debug('diff=' + String.valueOf(diff));
        System.debug('direction=' + String.valueOf(direction));
        Integer iterations = 0;
        Decimal mindiff = Math.abs(diff);
        Decimal bestDown = DownPayment;
        while(Math.abs(diff)>0.005 && iterations++<10) {
            DownPayment += diff;
            DownPayment = DownPayment.setScale(2);
            calculate();
            diff = desiredupfront - TotalUpFrontCash;
            System.debug('diff=' + String.valueOf(diff));
            if (Math.abs(diff)<mindiff) {
                bestDown = DownPayment;
                mindiff = Math.abs(diff);
            }
        }
        System.debug('iterations=' + String.valueOf(iterations));
        System.debug('Set total upfront cash = ' + String.valueOf(TotalUpFrontCash));
        if (TotalUpFrontCash!=desiredupfront) {
            System.debug('Unable to achieve desired up-front cash amount');
            System.debug('Min difference=' + String.valueOf(mindiff));
            System.debug('Down pmt='+String.valueOf(bestDown));
            throw new LeaseException('Unable to achieve desired up-front cash amount');
        }
    }
    
    public List<String> getDebugData() {
        System.debug('getDebugData');
        List<String> lines = new List<String>();
        lines.add('AcquisitionFee: ' + String.valueOf(AcquisitionFee));
        lines.add('Additions: ' + String.valueOf(Additions));
        lines.add('AdjustedCapCostBeforeTax: ' + String.valueOf(AdjustedCapCostBeforeTax));
        lines.add('AdjustedCapCost: ' + String.valueOf(AdjustedCapCost));

        lines.add('CapCostReduction: ' + String.valueOf(CapCostReduction));

        lines.add('Depreciation: ' + String.valueOf(Depreciation));
        lines.add('Deposit: ' + String.valueOf(Deposit)); 
        lines.add('DispositionFee: ' + String.valueOf(DispositionFee));
        lines.add('DownPayment: ' + String.valueOf(DownPayment)); 

        lines.add('LeaseTerm: ' + String.valueOf(LeaseTerm));

        lines.add('MoneyFactor: ' + String.valueOf(MoneyFactor));
        lines.add('MonthlyPmtBeforeTax: ' + String.valueOf(MonthlyPmtBeforeTax));
        lines.add('MonthlyPayment: ' + String.valueOf(MonthlyPayment));
        lines.add('MonthlyRentBeforeTax: ' + String.valueOf(MonthlyRentBeforeTax));
        lines.add('MonthlyRentCharge: ' + String.valueOf(MonthlyRentCharge));
        lines.add('MonthlySalesTax: ' + String.valueOf(MonthlySalesTax));
        lines.add('MonthlyUnitCharge: ' + String.valueOf(MonthlyUnitCharge));

        lines.add('OutsideFunding: ' + String.valueOf(OutsideFunding));
        lines.add('RentBase: ' + String.valueOf(RentBase));
        lines.add('Residual: ' + String.valueOf(Residual));

        lines.add('SalesPrice: ' + String.valueOf(SalesPrice));
        lines.add('SalesTaxPct: ' + String.valueOf(SalesTaxPct));
        lines.add('SalesTax: ' + String.valueOf(SalesTax));
        lines.add('SalesTaxMethod: ' + String.valueOf(SalesTaxMethod));
        lines.add('SalesTaxHandling: ' + String.valueOf(SalesTaxHandling));

        lines.add('TaxExemptFunding: ' + String.valueOf(TaxExemptFunding)); 
        lines.add('TaxOnCostReduction: ' + String.valueOf(TaxOnCostReduction));
        lines.add('Discounts: ' + String.valueOf(Discounts));
        lines.add('TaxExemptDiscunts: ' + String.valueOf(TaxExemptDiscounts));
        lines.add('TotalUpFrontCash: ' + String.valueOf(TotalUpFrontCash));
        lines.add('TotalOfPaymentsBeforeTax: ' + String.valueOf(TotalOfPaymentsBeforeTax));
        lines.add('TradeAllowance: ' + String.valueOf(TradeAllowance)); 
        lines.add('TradePayoff: ' + String.valueOf(TradePayoff)); 
        lines.add('TotalOfPayments: ' + String.valueOf(TotalOfPayments));
        lines.add('UpFrontSalesTax: ' + String.valueOf(UpFrontSalesTax));

        return lines;
    }
    
    public void debugLog() {
        System.debug('debugLog');
        List<String> lines = getDebugData();
        for(String l : lines) System.debug(l);
    }

    public class LeaseException extends Exception {}

}