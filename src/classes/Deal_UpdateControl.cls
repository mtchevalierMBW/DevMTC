/**
 * Deal_UpdateControl
 * Tested by: Deal_UpdateControl_TEST
 * Date: Nov 1, 2016
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2019-01-10	88% (146/165)
 *
 *  2017-01-03  B. Leaman   BLL1 - Add Funding_option__c picklist ('Cash', 'Financed')
 *  2017-06-09  B. Leaman   BLL2 - New F&I fields ( LeaseAcquisitionFee__c, LeaseMilesIncluded__c, LeaseMonthlySalesTax__c
 *                              LeaseMilesOverageRate__c, LoanAcquisitionCost__c )
 *  2017-08-14  B. Leaman   BLL3 - Additional lease fields
 *  2018-11-07  B. Leaman   W-000466 BLL4 - new FICO Score field with visibility only to F&I.
 *	2019-01-09	B. Leaman	W-000482 BLL5 - new routines to save VA paperwork approval info; 
 *
 *  WITHOUT SHARING and FUTURE method -- allow updates to certain fields even though the record is locked in an approval process.

 These are the fields that can be updated in the F&I section: 
    'dealer__F_I_Manager__c', 'dealer__Finance_Institution_Account__c ', 'Funding_option__c', 
    'Contract_Type__c', 'Contract_ResidualValue__c', 'Contract_LeaseEndDate__c',
    'Contract_Amount_Financed__c', 'Contract_APR__c', 'Contract_Final_Payment__c', 'Contract_Finance_Charge__c',
    'Contract_Monthly_Payment__c', 'Contract_Number_of_Payments__c', 'Contract_Total_of_Payments__c',
    'LeaseAcquisitionFee__c', 'LeaseMilesIncluded__c', 'LeaseMonthlySalesTax__c', 'LeaseMilesOverageRate__c', 'LoanAcquisitionCost__c', 'LeasePmtDueDOM__c',
    'LeaseTotalFeesAndTaxes__c', 'LeaseLatePmtFee__c', 'LeaseDispositionFee__c', 'LeaseEarlyTerminationFee__c', 
    'dealer__First_Payment_Date__c', 'TaxOnCostReduction__c', 'DesiredUpfrontCash__c', 
    'LeaseMoneyFactor__c', 'LeasePmtBeforeTax__c', 'LeaseUpfrontSalesTax__c', 'TotalUpfrontCash__c',
    'ChassisMSRP__c', 'ChassisResidualPct__c', 'ChassisResidualAmt__c',
    'ConversionMSRP__c', 'ConversionResidualPct__c', 'ConversionResidualAmt__c',
	'FinanceCompanyReimbursement__c', 'FICO_Score__c'
 */
public without sharing class Deal_UpdateControl {

    User u;
    
    public Deal_UpdateControl() {
        u = CurrentUserSingleton.getInstance(); 
    }

    public static void updateFandIData(dealer__Deal__c d) {
        Map<String,String> fieldmap = new Map<String,String>();
        fieldmap.put('Id',String.valueOf(d.Id));
        if (d.dealer__F_I_Manager__c!=null) fieldmap.put('dealer__F_I_Manager__c',String.valueOf(d.dealer__F_I_Manager__c));
        if (d.dealer__Finance_Institution_Account__c!=null) fieldmap.put('dealer__Finance_Institution_Account__c',String.valueOf(d.dealer__Finance_Institution_Account__c));
        if (d.Contract_Status__c!=null) fieldmap.put('Contract_Status__c',String.valueOf(d.Contract_Status__c));
        if (d.Contract_CustomerArranged__c!=null) fieldmap.put('Contract_CustomerArranged__c',(d.Contract_CustomerArranged__c?'1':'0'));
        if (d.Funding_option__c!=null) fieldmap.put('Funding_option__c',String.valueOf(d.Funding_option__c));   // BLL1a
        if (d.Customer_Financing_Source__c!=null) fieldmap.put('Customer_Financing_Source__c',String.valueOf(d.Customer_Financing_Source__c));
        if (d.Contract_CounterOffer__c!=null) fieldmap.put('Contract_CounterOffer__c',(d.Contract_CounterOffer__c?'1':'0'));
        if (d.Contract_Type__c!=null) fieldmap.put('Contract_Type__c',String.valueOf(d.Contract_Type__c));
        if (d.Contract_ResidualValue__c!=null) fieldmap.put('Contract_ResidualValue__c',String.valueOf(d.Contract_ResidualValue__c));
        if (d.Contract_LeaseEndDate__c!=null) fieldmap.put('Contract_LeaseEndDate__c',DateTime.newInstance(d.Contract_LeaseEndDate__c,Time.newInstance(0,0,0,0)).format('yyyy-MM-dd'));
        if (d.Contract_Amount_Financed__c!=null) fieldmap.put('Contract_Amount_Financed__c',String.valueOf(d.Contract_Amount_Financed__c));
        if (d.Contract_APR__c!=null) fieldmap.put('Contract_APR__c',String.valueOf(d.Contract_APR__c));
        if (d.Contract_Final_Payment__c!=null) fieldmap.put('Contract_Final_Payment__c',String.valueOf(d.Contract_Final_Payment__c));
        if (d.Contract_Finance_Charge__c!=null) fieldmap.put('Contract_Finance_Charge__c',String.valueOf(d.Contract_Finance_Charge__c));
        if (d.Contract_Monthly_Payment__c!=null) fieldmap.put('Contract_Monthly_Payment__c',String.valueOf(d.Contract_Monthly_Payment__c));
        if (d.Contract_Number_of_Payments__c!=null) fieldmap.put('Contract_Number_of_Payments__c',String.valueOf(d.Contract_Number_of_Payments__c));
        if (d.Contract_Total_of_Payments__c!=null) fieldmap.put('Contract_Total_of_Payments__c',String.valueOf(d.Contract_Total_of_Payments__c));
        if (d.Finance_Reserve__c!=null) fieldmap.put('Finance_Reserve__c',String.valueOf(d.Finance_Reserve__c));

        // BLL2a
        if (d.LeaseAcquisitionFee__c!=null) fieldmap.put('LeaseAcquisitionFee__c',String.valueOf(d.LeaseAcquisitionFee__c));
        if (d.LeaseMilesIncluded__c!=null) fieldmap.put('LeaseMilesIncluded__c',String.valueOf(d.LeaseMilesIncluded__c));
        if (d.LeaseMonthlySalesTax__c!=null) fieldmap.put('LeaseMonthlySalesTax__c',String.valueOf(d.LeaseMonthlySalesTax__c));
        if (d.LeaseMilesOverageRate__c!=null) fieldmap.put('LeaseMilesOverageRate__c',String.valueOf(d.LeaseMilesOverageRate__c));
        if (d.LeasePmtDueDOM__c!=null) fieldmap.put('LeasePmtDueDOM__c',String.valueOf(d.LeasePmtDueDOM__c));
        if (d.LoanAcquisitionCost__c!=null) fieldmap.put('LoanAcquisitionCost__c',String.valueOf(d.LoanAcquisitionCost__c));
        if (d.dealer__First_Payment_Date__c!=null) fieldmap.put('dealer__First_Payment_Date__c',DateTime.newInstance(d.dealer__First_Payment_Date__c,Time.newInstance(0,0,0,0)).format('yyyy-MM-dd'));
        if (d.TaxOnCostReduction__c!=null) fieldmap.put('TaxOnCostReduction__c',String.valueOf(d.TaxOnCostReduction__c));

        if (d.LeaseTotalFeesAndTaxes__c!=null) fieldmap.put('LeaseTotalFeesAndTaxes__c',String.valueOf(d.LeaseTotalFeesAndTaxes__c));
        if (d.LeaseLatePmtFee__c!=null) fieldmap.put('LeaseLatePmtFee__c',String.valueOf(d.LeaseLatePmtFee__c));
        if (d.LeaseDispositionFee__c!=null) fieldmap.put('LeaseDispositionFee__c',String.valueOf(d.LeaseDispositionFee__c));
        if (d.LeaseEarlyTerminationFee__c!=null) fieldmap.put('LeaseEarlyTerminationFee__c',String.valueOf(d.LeaseEarlyTerminationFee__c));
        // BLL2a end

        if (d.Credit_Application_Received__c!=null) fieldmap.put('Credit_Application_Received__c',d.Credit_Application_Received__c.format('yyyy-MM-dd hh:mm:ss'));
        if (d.Credit_BackToStore__c!=null) fieldmap.put('Credit_BackToStore__c',d.Credit_BackToStore__c.format('yyyy-MM-dd hh:mm:ss'));
        if (d.Credit_Decision_Received__c!=null) fieldmap.put('Credit_Decision_Received__c',d.Credit_Decision_Received__c.format('yyyy-MM-dd hh:mm:ss'));

        // BLL3a
        if (d.LeaseMoneyFactor__c!=null) fieldmap.put('LeaseMoneyFactor__c',String.valueOf(d.LeaseMoneyFactor__c)); 
        if (d.LeasePmtBeforeTax__c!=null) fieldmap.put('LeasePmtBeforeTax__c',String.valueOf(d.LeasePmtBeforeTax__c)); 
        if (d.ChassisMSRP__c!=null) fieldmap.put('ChassisMSRP__c',String.valueOf(d.ChassisMSRP__c)); 
        if (d.ChassisResidualPct__c!=null) fieldmap.put('ChassisResidualPct__c',String.valueOf(d.ChassisResidualPct__c)); 
        if (d.ChassisResidualAmt__c!=null) fieldmap.put('ChassisResidualAmt__c',String.valueOf(d.ChassisResidualAmt__c));
        if (d.ConversionMSRP__c!=null) fieldmap.put('ConversionMSRP__c',String.valueOf(d.ConversionMSRP__c)); 
        if (d.ConversionResidualPct__c!=null) fieldmap.put('ConversionResidualPct__c',String.valueOf(d.ConversionResidualPct__c)); 
        if (d.ConversionResidualAmt__c!=null) fieldmap.put('ConversionResidualAmt__c',String.valueOf(d.ConversionResidualAmt__c));
        if (d.LeaseUpfrontSalesTax__c!=null) fieldmap.put('LeaseUpfrontSalesTax__c',String.valueOf(d.LeaseUpfrontSalesTax__c));
        if (d.TotalUpfrontCash__c!=null) fieldmap.put('TotalUpfrontCash__c',String.valueOf(d.TotalUpfrontCash__c));
        if (d.DesiredUpfrontCash__c!=null) fieldmap.put('DesiredUpfrontCash__c',String.valueOf(d.DesiredUpfrontCash__c));
        if (d.FinanceCompanyReimbursement__c!=null) fieldmap.put('FinanceCompanyReimbursement__c',String.valueOf(d.FinanceCompanyReimbursement__c));
        // BLL3a end

        // BLL4a
        if (d.FICO_Score__c!=null) fieldmap.put('FICO_Score__c', String.valueOf(d.FICO_Score__c));
        // BLL4a end

        Deal_UpdateControl.updateFandIData(fieldmap);
    }

    // Update just certain specific fields
    //---------------------------------------
    @future public static void updateFandIData(Map<String,String> d) {
        String str;
        dealer__Deal__c updDeal = new dealer__Deal__c(Id=(Id)d.get('Id'));
        str = d.get('dealer__F_I_Manager__c');
        updDeal.dealer__F_I_Manager__c= String.isBlank(str) ? null : (Id)str;
        str = d.get('dealer__Finance_Institution_Account__c');
        updDeal.dealer__Finance_Institution_Account__c=String.isBlank(str) ? null : (Id)str;
        str = (String) d.get('Contract_Status__c'); 
        updDeal.Contract_Status__c=String.isBlank(str) ? null : str;
        str = (String) d.get('Contract_CustomerArranged__c');
        updDeal.Contract_CustomerArranged__c=String.isBlank(str) ? null : ((boolean) (str=='1'));
        str = (String) d.get('Funding_option__c');  // BLL1a
        updDeal.Funding_option__c=String.isBlank(str) ? null : str; // BLL1a
        str = (String) d.get('Customer_Financing_Source__c');
        updDeal.Customer_Financing_Source__c=String.isBlank(str) ? null : str;
        str = (String) d.get('Contract_CounterOffer__c');
        updDeal.Contract_CounterOffer__c=String.isBlank(str) ? null : ((boolean) (str=='1'));
        str = (String) d.get('Contract_Type__c');
        updDeal.Contract_Type__c=String.isBlank(str) ? null : str;
        str = (String) d.get('Contract_ResidualValue__c');
        updDeal.Contract_ResidualValue__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_LeaseEndDate__c');
        updDeal.Contract_LeaseEndDate__c=String.isBlank(str) ? null : Date.valueOf(str);
        str = (String) d.get('Contract_Amount_Financed__c');
        updDeal.Contract_Amount_Financed__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_APR__c');
        updDeal.Contract_APR__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_Final_Payment__c');
        updDeal.Contract_Final_Payment__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_Finance_Charge__c');
        updDeal.Contract_Finance_Charge__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_Monthly_Payment__c');
        updDeal.Contract_Monthly_Payment__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_Number_of_Payments__c');
        updDeal.Contract_Number_of_Payments__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Contract_Total_of_Payments__c');
        updDeal.Contract_Total_of_Payments__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('Finance_Reserve__c');
        updDeal.Finance_Reserve__c=String.isBlank(str) ? null : Decimal.valueOf(str);

        // BLL2a
        str = (String) d.get('LeaseAcquisitionFee__c');
        updDeal.LeaseAcquisitionFee__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseMilesIncluded__c');
        updDeal.LeaseMilesIncluded__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseMonthlySalesTax__c');
        updDeal.LeaseMonthlySalesTax__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseMilesOverageRate__c');
        updDeal.LeaseMilesOverageRate__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeasePmtDueDOM__c');
        updDeal.LeasePmtDueDOM__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LoanAcquisitionCost__c');
        updDeal.LoanAcquisitionCost__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('dealer__First_Payment_Date__c');
        updDeal.dealer__First_Payment_Date__c=String.isBlank(str) ? null : Date.valueOf(str);
        str = (String) d.get('TaxOnCostReduction__c');
        updDeal.TaxOnCostReduction__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseTotalFeesAndTaxes__c');
        updDeal.LeaseTotalFeesAndTaxes__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseLatePmtFee__c');
        updDeal.LeaseLatePmtFee__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseDispositionFee__c');
        updDeal.LeaseDispositionFee__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseEarlyTerminationFee__c');
        updDeal.LeaseEarlyTerminationFee__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        // BLL2a end

        str = (String) d.get('Credit_Application_Received__c');
        updDeal.Credit_Application_Received__c=String.isBlank(str) ? null : DateTime.valueOf(str);
        str = (String) d.get('Credit_BackToStore__c');
        updDeal.Credit_BackToStore__c=String.isBlank(str) ? null : DateTime.valueOf(str);
        str = (String) d.get('Credit_Decision_Received__c');
        updDeal.Credit_Decision_Received__c=String.isBlank(str) ? null : DateTime.valueOf(str);
        
        // BLL3a  
        str = (String) d.get('LeaseMoneyFactor__c'); 
        updDeal.LeaseMoneyFactor__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('LeasePmtBeforeTax__c'); 
        updDeal.LeasePmtBeforeTax__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('ChassisMSRP__c'); 
        updDeal.ChassisMSRP__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('ChassisResidualPct__c'); 
        updDeal.ChassisResidualPct__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('ChassisResidualAmt__c');
        updDeal.ChassisResidualAmt__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('ConversionMSRP__c'); 
        updDeal.ConversionMSRP__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('ConversionResidualPct__c'); 
        updDeal.ConversionResidualPct__c=String.isBlank(str) ? null : Decimal.valueOf(str); 
        str = (String) d.get('ConversionResidualAmt__c');
        updDeal.ConversionResidualAmt__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('LeaseUpfrontSalesTax__c');
        updDeal.LeaseUpfrontSalesTax__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('TotalUpfrontCash__c');
        updDeal.TotalUpfrontCash__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('DesiredUpfrontCash__c');
        updDeal.TotalUpfrontCash__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        str = (String) d.get('FinanceCompanyReimbursement__c');
        updDeal.FinanceCompanyReimbursement__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        // BLL3a end
        
        // BLL4a
        str = (String) d.get('FICO_Score__c');
        updDeal.FICO_Score__c=String.isBlank(str) ? null : Decimal.valueOf(str);
        // BLL4a end

        update(updDeal);
    }

	// BLL5
    public static void updateVAApproval(dealer__Deal__c d) {
        Map<String,String> fieldmap = new Map<String,String>();
        fieldmap.put('Id',String.valueOf(d.Id));
        if (d.VA_Paperwork_Approved__c!=null) fieldmap.put('VA_Paperwork_Approved__c',(d.VA_Paperwork_Approved__c?'1':'0'));
        if (d.VA_Paperwork_Approver__c!=null) fieldmap.put('VA_Paperwork_Approver__c',String.valueOf(d.VA_Paperwork_Approver__c));
        if (d.VA_Paperwork_ApprovalDT__c!=null) fieldmap.put('VA_Paperwork_ApprovalDT__c',d.VA_Paperwork_ApprovalDT__c.format('yyyy-MM-dd hh:mm:ss'));

        Deal_UpdateControl.updateVAApproval(fieldmap);
	}
    @future public static void updateVAApproval(Map<String,String> d) {
        String str;
        dealer__Deal__c updDeal = new dealer__Deal__c(Id=(Id)d.get('Id'));
        str = (String) d.get('VA_Paperwork_Approved__c');
        updDeal.VA_Paperwork_Approved__c=String.isBlank(str) ? null : ((boolean) (str=='1'));
        str = d.get('VA_Paperwork_Approver__c');
        updDeal.VA_Paperwork_Approver__c= String.isBlank(str) ? null : (Id)str;
        str = (String) d.get('VA_Paperwork_ApprovalDT__c');
        updDeal.VA_Paperwork_ApprovalDT__c=String.isBlank(str) ? null : DateTime.valueOf(str);

        update(updDeal);

		// new approval step not implemented if (updDeal.VA_Paperwork_Approved__c) ApprovalProcessUtil.ApproveDocument(updDeal.Id, 'Approved', new Set<String>{'VA_Paperwork_Approval'});

	}
	// BLL5

}