/**
 * WMK, LLC (c) - 2018 
 *
 * ProjectBudgetCostTriggerHandler
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/22/2018 
 * Tested By:    ProjectBudgetCostTriggerHandlerTest
 * Work Item:    W-000498
 *
 * Modified By         Alias       Work Item       Date         Reason
 * -------------------------------------------------------------------
 * Alexander Miller    AMM1        W-000589      2/18/2019     Update to capture NIC Issue transactions
 */
public class ProjectBudgetCostTriggerHandler {

    public Map<Id, rstk__pjprojcst__c> mapOfProjectBudgetToUpdate {get;set;}

    public List<rstk__soinvline__c> ListOfAllSalesOrderInvoiceLines {get;set;}

    public List<rstk__soinvline__c> ListOfAllSalesOrderInvoiceLinesFrieght {get;set;}

    public List<rstk__soinvline__c> ListOfAllSalesOrderInvoiceLinesTax {get;set;}

    public List<rstk__soinvline__c> ListOfAllSalesOrderInvoiceLinesInterCompany {get;set;}

    // AMM1 
    public List<rstk__soinvline__c> ListOfAllSaleSorderInvoiceLinesNicIssue {get;set;}
    // AMM1

    public Map<Id, Opportunity__c> mapOfOpportunities {get;set;}

    private static boolean run = true;

    public ProjectBudgetCostTriggerHandler()
    {
        mapOfProjectBudgetToUpdate = new Map<Id, rstk__pjprojcst__c>();

        ListOfAllSalesOrderInvoiceLines = new List<rstk__soinvline__c>();

        ListOfAllSalesOrderInvoiceLinesFrieght = new List<rstk__soinvline__c>();

        ListOfAllSalesOrderInvoiceLinesTax = new List<rstk__soinvline__c>();

        ListOfAllSalesOrderInvoiceLinesInterCompany = new List<rstk__soinvline__c>();

        mapOfOpportunities = new Map<Id, Opportunity__c>();

        // AMM1 
        ListOfAllSaleSorderInvoiceLinesNicIssue = new List<rstk__soinvline__c>();
        // AMM1
    }

    /**
    *
    * runOnce
    *
    * Function which helps prevent duplicate calls during updates
    */
    public static boolean runOnce(){
        if(run)
        {
            run=false;
            return true;
        }
        else
        {
            return run;
        }
    }


    public void updateMaps()
    {
        System.debug(mapOfProjectBudgetToUpdate.values());
        update mapOfProjectBudgetToUpdate.values();
        update mapOfOpportunities.values();
    }

    /**
    * updateRelatedOpporutnities
    *
    * Function which searches the system for all Opportunities 
    * somehow tied to these Project Masters. This can be on the 
    * Chassis Master or Sales Order Header.
    *
    * This process is meant to kick off the Opportunity logic which 
    * does custom rollup summaries.
    */
    public void updateRelatedOpporutnities(List<rstk__pjprojcst__c> newList)
    {
        newList = getCleanedNonOverrideList(newList);

        Map<Id, Set<rstk__pjprojcst__c>> mapOfOpportunityToProjectBudget = new Map<Id, Set<rstk__pjprojcst__c>>();
        Map<Id, rstk__pjprojcst__c> mapOfProjectToBudgets = new Map<Id, rstk__pjprojcst__c>();

        List<Id> listOfProjectIds = new List<Id>();

        List<Opportunity__c> listOfOpportunitiesBuilder = new List<Opportunity__c>();

        for(rstk__pjprojcst__c tempProjeect : newList)
        {
            listOfProjectIds.add(tempProjeect.rstk__pjprojcst_proj__c);

            if(mapOfProjectToBudgets.get(tempProjeect.rstk__pjprojcst_proj__c) == null)
            {
                mapOfProjectToBudgets.put(tempProjeect.rstk__pjprojcst_proj__c, tempProjeect);
            }
        }

        List<rstk__sohdr__c> listOfSalesOrderHeaders = ([SELECT Id,
                                                            Opportunity_custom__c,
                                                            rstk__sohdr_proj__c
                                                        FROM rstk__sohdr__c
                                                        WHERE Opportunity_custom__c != null AND
                                                                rstk__sohdr_proj__c IN :listOfProjectIds]);

        List<Chassis_Master__c> listOfChassisMasters = ([SELECT Id,
                                                            Opportunity_custom__c,
                                                            Opportunity_Allocation__c,
                                                            Project_Master__c
                                                        FROM Chassis_Master__c
                                                        WHERE (Opportunity_custom__c != null OR Opportunity_Allocation__c != null) AND
                                                            Project_Master__c IN :listOfProjectIds]);

        List<rstk__wocst__c> listOfWorkOrders = ([SELECT Id,
                                                    Opportunity_custom__c,
                                                    rstk__wocst_proj__c 
                                                FROM rstk__wocst__c
                                                WHERE Opportunity_custom__c != null AND
                                                    rstk__wocst_proj__c IN :listOfProjectIds]);

        Set<Id> setOfOpportunityIds = new Set<Id>();

        for(rstk__sohdr__c tempSale : listOfSalesOrderHeaders)
        {
            setOfOpportunityIds.add(tempSale.Opportunity_custom__c);

            if(mapOfOpportunityToProjectBudget.get(tempSale.Opportunity_custom__c) == null)
            {
                if(mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c) != null && mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = new Set<rstk__pjprojcst__c>();

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c));

                    mapOfOpportunityToProjectBudget.put(tempSale.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
            else 
            {
                if(mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c) != null && mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = mapOfOpportunityToProjectBudget.get(tempSale.Opportunity_custom__c);

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempSale.rstk__sohdr_proj__c));

                    mapOfOpportunityToProjectBudget.put(tempSale.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
        }

        for(Chassis_Master__c tempChassis : listOfChassisMasters)
        {
            setOfOpportunityIds.add(tempChassis.Opportunity_custom__c);
            setOfOpportunityIds.add(tempChassis.Opportunity_Allocation__c);

            if(mapOfOpportunityToProjectBudget.get(tempChassis.Opportunity_custom__c) == null)
            {
                if(mapOfProjectToBudgets.get(tempChassis.Project_Master__c) != null && mapOfProjectToBudgets.get(tempChassis.Project_Master__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = new Set<rstk__pjprojcst__c>();

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempChassis.Project_Master__c));

                    mapOfOpportunityToProjectBudget.put(tempChassis.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
            else 
            {
                if(mapOfProjectToBudgets.get(tempChassis.Project_Master__c) != null && mapOfProjectToBudgets.get(tempChassis.Project_Master__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = mapOfOpportunityToProjectBudget.get(tempChassis.Opportunity_custom__c);

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempChassis.Project_Master__c));

                    mapOfOpportunityToProjectBudget.put(tempChassis.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
        }

        for(rstk__wocst__c tempWorkOrder : listOfWorkOrders)
        {
            setOfOpportunityIds.add(tempWorkOrder.Opportunity_custom__c);

            if(mapOfOpportunityToProjectBudget.get(tempWorkOrder.Opportunity_custom__c) == null)
            {
                if(mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c) != null && mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = new Set<rstk__pjprojcst__c>();

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c));

                    mapOfOpportunityToProjectBudget.put(tempWorkOrder.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
            else 
            {
                if(mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c) != null && mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c).Project_Complete__c)
                {
                    Set<rstk__pjprojcst__c> listOfProjectBudgets = mapOfOpportunityToProjectBudget.get(tempWorkOrder.Opportunity_custom__c);

                    listOfProjectBudgets.add(mapOfProjectToBudgets.get(tempWorkOrder.rstk__wocst_proj__c));

                    mapOfOpportunityToProjectBudget.put(tempWorkOrder.Opportunity_custom__c, listOfProjectBudgets);
                }
            }
        }

        for(Id tempId : setOfOpportunityIds)
        {
            listOfOpportunitiesBuilder.add(new Opportunity__c(Id = tempId));
        }

        List<Opportunity__c> listOfOpportunitiesQuery = ([SELECT Id,
                                                        Landed_GP__c,
                                                        Sales_Order_Total_Price__c,
                                                        Project_Cost_Total__c
                                                    FROM Opportunity__c 
                                                    WHERE Id IN :listOfOpportunitiesBuilder]);

        // cycle through the Opportunity's Project Budget record to see if there is a difference. If so, then stage the Opp for update
        for(Opportunity__c tempOpp : listOfOpportunitiesQuery)
        {
            if(mapOfOpportunityToProjectBudget.get(tempOpp.Id) != null)
            {
                Set<rstk__pjprojcst__c> tempBudgetList = mapOfOpportunityToProjectBudget.get(tempOpp.Id);

                System.debug(tempBudgetList);

                Decimal tempSale = 0.0;
                Decimal tempCost = 0.0;
                Decimal tempGP = 0.0;

                for(rstk__pjprojcst__c tempBudget : tempBudgetList)
                {
                    if(tempBudget.Project_Complete__c == false)
                    {
                        continue;
                    }

                    tempSale += tempBudget.Project_Total_Sale__c;

                    tempCost += tempBudget.Project_Total_Cost__c;

                    tempGP += tempBudget.Project_Gross_Profit__c;
                }

                System.debug(tempSale);
                System.debug(tempCost);
                System.debug(tempGP);

                // GP
                if(tempOpp != null && tempOpp.Landed_GP__c != tempGP)
                {
                    if(mapOfOpportunities.get(tempOpp.Id) == null)
                    {
                        mapOfOpportunities.put(tempOpp.Id, new Opportunity__c(Id = tempOpp.Id, Landed_GP__c = tempGP));
                    }
                    else 
                    {
                        mapOfOpportunities.get(tempOpp.Id).Landed_GP__c = tempGP;
                    }
                }

                // Sale
                if(tempOpp != null && tempOpp.Sales_Order_Total_Price__c != tempSale)
                {
                    if(mapOfOpportunities.get(tempOpp.Id) == null)
                    {
                        mapOfOpportunities.put(tempOpp.Id, new Opportunity__c(Id = tempOpp.Id, Sales_Order_Total_Price__c = tempSale));
                    }
                    else 
                    {
                        mapOfOpportunities.get(tempOpp.Id).Sales_Order_Total_Price__c = tempSale;
                    }
                }

                // Cost
                if(tempOpp != null && tempOpp.Project_Cost_Total__c != tempCost)
                {
                    if(mapOfOpportunities.get(tempOpp.Id) == null)
                    {
                        mapOfOpportunities.put(tempOpp.Id, new Opportunity__c(Id = tempOpp.Id, Project_Cost_Total__c = tempCost));
                    }
                    else 
                    {
                        mapOfOpportunities.get(tempOpp.Id).Project_Cost_Total__c = tempCost;
                    }
                }
            }
        }
    }

    /**
    * updateProjectPartSaleCost
    *
    * Function which looks at the system for cost transactions
    * with Transaction Type SOISS or SOISSR of Sales Order Lines
    * which have Product Types Kit or Stock.
    *
    * The net amount of the issues and reversals is calculated into
    * project budget total
    */
    public void updateProjectPartSaleCost(List<rstk__pjprojcst__c> newList)
    {
        newList = getCleanedNonOverrideList(newList);
        
        // 1. Get list of Project Ids
        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            listOfProjectIds.add(tempProject.rstk__pjprojcst_proj__c);
        }

        // 2. Get list of Cost Transactions tied to the projects which are SOISS/SOISSR for order type Sales Orders
        List<rstk__sytxncst__c> listOfCostTransaction = ([SELECT Id,
                                                            rstk__sytxncst_txnid__c,                            // Transaction ID (SOISS/SOISSR/INVLOCADJ)
                                                            rstk__sytxncst_ordproj__c,                          // Order Project
                                                            rstk__sytxncst_proj__c,                             // Project Master (for INVLOCADJ)
                                                            rstk__sytxncst_ucsttotext__c                        // Unit Cost, Extended
                                                        FROM rstk__sytxncst__c 
                                                        WHERE   (   
                                                              rstk__sytxncst_txnid__c IN ('SOISS', 'SOISSR') AND
                                                              rstk__sytxncst_ordtype__c = '1' AND
                                                              rstk__sytxncst_proj__r.Name IN ('AK Home Project', 'KC Home Project', 'SC Home Project') AND 
                                                              rstk__sytxncst_ordproj__c IN :listOfProjectIds
                                                          ) 
                                                          OR
                                                          (
                                                              rstk__sytxncst_txnid__c = 'INVLOCADJ' AND 
                                                              rstk__sytxncst_proj__c IN :listOfProjectIds
                                                          )]);

        // 3. Group the Transactions by Project for simpler processing
        Map<Id, List<rstk__sytxncst__c>> mapOfCostTransactionsToProject = new Map<Id, List<rstk__sytxncst__c>>();

        for(rstk__sytxncst__c tempCost : listOfCostTransaction)
        {
            if( ( tempCost.rstk__sytxncst_txnid__c == 'SOISS' || tempCost.rstk__sytxncst_txnid__c == 'SOISSR' ) && 
                mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_ordproj__c) == null)
            {
                List<rstk__sytxncst__c> tempList = new List<rstk__sytxncst__c>();

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_ordproj__c, tempList);
            }
            else if( tempCost.rstk__sytxncst_txnid__c == 'INVLOCADJ' && 
                mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_proj__c) == null)
            {
                List<rstk__sytxncst__c> tempList = new List<rstk__sytxncst__c>();

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_proj__c, tempList);
            }
            else if(( tempCost.rstk__sytxncst_txnid__c == 'SOISS' || tempCost.rstk__sytxncst_txnid__c == 'SOISSR' )) 
            {
                List<rstk__sytxncst__c> tempList = mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_ordproj__c);

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_ordproj__c, tempList);
            }
            else
            {
                List<rstk__sytxncst__c> tempList = mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_proj__c);

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_proj__c, tempList);       
            }
        }

        // 4. Calculate the totals
        for(rstk__pjprojcst__c tempProject : newList)
        {   
            Decimal totalCost = 0.0;

            if(mapOfCostTransactionsToProject.get(tempProject.rstk__pjprojcst_proj__c) != null)
            {
                for(rstk__sytxncst__c tempCost : mapOfCostTransactionsToProject.get(tempProject.rstk__pjprojcst_proj__c))
                {
                    if(tempCost.rstk__sytxncst_txnid__c == 'SOISS' || tempCost.rstk__sytxncst_txnid__c == 'INVLOCADJ')
                    {
                        totalCost = totalCost + tempCost.rstk__sytxncst_ucsttotext__c;
                    }
                    else if(tempCost.rstk__sytxncst_txnid__c == 'SOISSR')
                    {
                    totalCost = totalCost - tempCost.rstk__sytxncst_ucsttotext__c;
                    }
                }
            }

            if(mapOfProjectBudgetToUpdate.get(tempProject.Id) == null)
            {
                rstk__pjprojcst__c tempProject2 = new rstk__pjprojcst__c(Id = tempProject.Id , Project_Part_Sale_Cost__c = totalCost);

                mapOfProjectBudgetToUpdate.put(tempProject.Id, tempProject2);
            }
            else 
            {
                mapOfProjectBudgetToUpdate.get(tempProject.Id).Project_Part_Sale_Cost__c = totalCost;
            }
        }
    }

    /**
    * updateProjectFreightCost
    *
    * Function which looks at the system for any PO line 
    * receipted for Freight. It calculates the total 
    * amount (unit price * quantity received) and 
    * will update the Project Budget/Cost record
    * if the value is different
    */
    public void updateProjectFreightCost(List<rstk__pjprojcst__c> newList)
    {
        System.debug('ProjectBudgetCostTriggerHandler.updateProjectFreightCost');

        newList = getCleanedNonOverrideList(newList);

        // 1. Gather the Project Ids
        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__pjprojcst__c tempProjeect : newList)
        {
            listOfProjectIds.add(tempProjeect.rstk__pjprojcst_proj__c);
        }

        System.debug(listOfProjectIds);

        // 2. Bucket Project Budget/Cost by Project Master for later
        Map<Id, rstk__pjprojcst__c> mapOfProjectBudgetsByProject = new Map<Id, rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            mapOfProjectBudgetsByProject.put(tempProject.rstk__pjprojcst_proj__c, tempProject);
        }

        System.debug(mapOfProjectBudgetsByProject);

        // 3. Query the system for PO lines containing Vehicle Ship Charge in the name
        List<rstk__poline__c> listOfTransactions = ([SELECT Id,
                                                        rstk__poline_proj__c,           // Project Master
                                                        rstk__poline_unitprice__c,      // Unit Price
                                                        rstk__formula_qtyrcvd__c        // Quantity Received
                                                    FROM rstk__poline__c
                                                    WHERE rstk__poline_proj__c IN :listOfProjectIds AND
                                                        rstk__poline_item__r.rstk__poitem_desc__c LIKE '%Vehicle Ship Charge%' AND
                                                        rstk__poline_ordsts__c IN ('7-Line Item Received', '8-All Line Items Received', '9-Closed')]);

        System.debug(listOfTransactions);

        // 4. Query all the Sales Orders for Part Sales to get their Frieght cost
        List<rstk__sohdr__c> listOfSalesOrders = ([SELECT Id,
                                                    rstk__sohdr_proj__c,
                                                    Freight_Cost__c
                                                FROM rstk__sohdr__c 
                                                WHERE rstk__sohdr_otype__r.Name LIKE '%Part Sale%' AND
                                                    rstk__sohdr_proj__c IN :listOfProjectIds]);

        // 5. Group the Transactions into their respective projects
        Map<Id, List<rstk__poline__c>> mapOfProjectPOLines = new Map<Id, List<rstk__poline__c>>();

        for(rstk__poline__c tempPoLine : listOfTransactions)
        {
            if(mapOfProjectPOLines.get(tempPoLine.rstk__poline_proj__c) == null)
            {
                List<rstk__poline__c> tempList = new List<rstk__poline__c>();

                tempList.add(tempPoLine);

                mapOfProjectPOLines.put(tempPoLine.rstk__poline_proj__c, tempList);
            }
            else 
            {
                List<rstk__poline__c> tempList = mapOfProjectPOLines.get(tempPoLine.rstk__poline_proj__c);

                tempList.add(tempPoLine);

                mapOfProjectPOLines.put(tempPoLine.rstk__poline_proj__c, tempList);
            }
        }

        Map<Id, List<rstk__sohdr__c>> mapOfProjectSalesOrders = new Map<Id, List<rstk__sohdr__c>>();

        for(rstk__sohdr__c tempPoLine : listOfSalesOrders)
        {
            if(mapOfProjectSalesOrders.get(tempPoLine.rstk__sohdr_proj__c) == null)
            {
                List<rstk__sohdr__c> tempList = new List<rstk__sohdr__c>();

                tempList.add(tempPoLine);

                mapOfProjectSalesOrders.put(tempPoLine.rstk__sohdr_proj__c, tempList);
            }
            else 
            {
                List<rstk__sohdr__c> tempList = mapOfProjectSalesOrders.get(tempPoLine.rstk__sohdr_proj__c);

                tempList.add(tempPoLine);

                mapOfProjectSalesOrders.put(tempPoLine.rstk__sohdr_proj__c, tempList);
            }
        }

        System.debug(mapOfProjectPOLines);

        // 6. Calculate the totals and if they're different than the current, put them in for an update
        for(Id tempProject : mapOfProjectPOLines.keySet())
        {
            Double projectTotal = 0.0;

            for(rstk__poline__c tempPoLine : mapOfProjectPOLines.get(tempProject))
            {
                projectTotal += tempPoLine.rstk__poline_unitprice__c * tempPoLine.rstk__formula_qtyrcvd__c;
            }

            if(mapOfProjectSalesOrders.get(tempProject) != null)
            {
                for(rstk__sohdr__c tempPoLine : mapOfProjectSalesOrders.get(tempProject))
                {
                    if(tempPoLine.Freight_Cost__c != null)
                    {
                        projectTotal += tempPoLine.Freight_Cost__c;
                    }
                }
            }

            if(mapOfProjectBudgetsByProject.get(tempProject).Project_Freight_Cost__c != projectTotal)
            {
                if(mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id) == null)
                {
                    rstk__pjprojcst__c tempProjectItem = new rstk__pjprojcst__c();

                    tempProjectItem.Id = mapOfProjectBudgetsByProject.get(tempProject).Id;
                    tempProjectItem.Project_Freight_Cost__c = projectTotal;

                    mapOfProjectBudgetToUpdate.put(tempProjectItem.Id, tempProjectItem);
                }
                else 
                {
                    mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id).Project_Freight_Cost__c = projectTotal;
                }
            }
        }

        System.debug(mapOfProjectBudgetToUpdate);
    }

    /**
    * updateProjectFreightSale
    *
    * Function which looks at the system for any Sales Order Line 
    * for Freight. It calculates the total 
    * amount (unit price * quantity) and 
    * will update the Project Budget/Cost record
    * if the value is different
    */
    public void updateProjectFreightSale(List<rstk__pjprojcst__c> newList)
    {
        System.debug('ProjectBudgetCostTriggerHandler.updateProjectFreightSale');

        newList = getCleanedNonOverrideList(newList);

        // 1. Bucket Project Budget/Cost by Project Master for later
        Map<Id, rstk__pjprojcst__c> mapOfProjectBudgetsByProject = new Map<Id, rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            mapOfProjectBudgetsByProject.put(tempProject.rstk__pjprojcst_proj__c, tempProject);
        }

        System.debug(mapOfProjectBudgetsByProject);

        // 2. Query the system for SO lines containing Vehicle Ship Charge in the name
        if(ListOfAllSalesOrderInvoiceLines.size() == 0)
        {
            ListOfAllSalesOrderInvoiceLines = getListOfInvoiceLines(newList);
        }
        
        ListOfAllSalesOrderInvoiceLinesFrieght = getListOfFrieghtInvoiceLines(ListOfAllSalesOrderInvoiceLines);

        List<rstk__soinvline__c> listOfTransactions = ListOfAllSalesOrderInvoiceLinesFrieght;

        System.debug(listOfTransactions);

        // 3. Group the Transactions into their respective projects
        Map<Id, List<rstk__soinvline__c>> mapOfProjectSoInvoiceLines = new Map<Id, List<rstk__soinvline__c>>();

        for(rstk__soinvline__c tempSoInvLine : listOfTransactions)
        {
            if(mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c) == null)
            {
                List<rstk__soinvline__c> tempList = new List<rstk__soinvline__c>();

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
            else 
            {
                List<rstk__soinvline__c> tempList = mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c);

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
        }

        System.debug(mapOfProjectSoInvoiceLines);

        // 4. Calculate the totals and if they're different than the current, put them in for an update
        for(Id tempProject : mapOfProjectSoInvoiceLines.keySet())
        {
            Double projectTotal = 0.0;

            for(rstk__soinvline__c tempPoLine : mapOfProjectSoInvoiceLines.get(tempProject))
            {
                if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Invoice')
                {
                    projectTotal += tempPoLine.rstk__soinvline_price__c;
                    projectTotal += tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_freightamt__c;
                }
                else if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Credit Memo')
                {
                    projectTotal -= tempPoLine.rstk__soinvline_price__c;
                    projectTotal -= tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_freightamt__c;
                }   
            }

            if(mapOfProjectBudgetsByProject.get(tempProject).Project_Freight_Sale__c != projectTotal)
            {
                if(mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id) == null)
                {
                    rstk__pjprojcst__c tempProjectItem = new rstk__pjprojcst__c();

                    tempProjectItem.Id = mapOfProjectBudgetsByProject.get(tempProject).Id;
                    tempProjectItem.Project_Freight_Sale__c = projectTotal;

                    mapOfProjectBudgetToUpdate.put(tempProjectItem.Id, tempProjectItem);
                }
                else 
                {
                    mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id).Project_Freight_Sale__c = projectTotal;
                }
            }
        }

        System.debug(mapOfProjectBudgetToUpdate);
    }

    /**
    * updateProjectSalesTax
    *
    * Function which looks at the system for any Sales Order Line 
    * for Tax. It calculates the total 
    * amount (unit price * quantity) and 
    * will update the Project Budget/Cost record
    * if the value is different
    */
    public void updateProjectSalesTax(List<rstk__pjprojcst__c> newList)
    {
        System.debug('ProjectBudgetCostTriggerHandler.updateProjectSalesTax');

        newList = getCleanedNonOverrideList(newList);

        // 1. Bucket Project Budget/Cost by Project Master for later
        Map<Id, rstk__pjprojcst__c> mapOfProjectBudgetsByProject = new Map<Id, rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            mapOfProjectBudgetsByProject.put(tempProject.rstk__pjprojcst_proj__c, tempProject);
        }

        System.debug(mapOfProjectBudgetsByProject);

        // 2. Query the system for SO lines containing Vehicle Ship Charge in the name
        if(ListOfAllSalesOrderInvoiceLines.size() == 0)
        {
            ListOfAllSalesOrderInvoiceLines = getListOfInvoiceLines(newList);

        }
        
        ListOfAllSalesOrderInvoiceLinesTax = getListOfTaxInvoiceLines(ListOfAllSalesOrderInvoiceLines);

        List<rstk__soinvline__c> listOfTransactions = ListOfAllSalesOrderInvoiceLinesTax;

        // 3. Group the Transactions into their respective projects
        Map<Id, List<rstk__soinvline__c>> mapOfProjectSoInvoiceLines = new Map<Id, List<rstk__soinvline__c>>();

        for(rstk__soinvline__c tempSoInvLine : listOfTransactions)
        {
            if(mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c) == null)
            {
                List<rstk__soinvline__c> tempList = new List<rstk__soinvline__c>();

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
            else 
            {
                List<rstk__soinvline__c> tempList = mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c);

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
        }

        System.debug(mapOfProjectSoInvoiceLines);

        // 4. Calculate the totals and if they're different than the current, put them in for an update
        for(Id tempProject : mapOfProjectSoInvoiceLines.keySet())
        {
            Double projectTotal = 0.0;

            for(rstk__soinvline__c tempPoLine : mapOfProjectSoInvoiceLines.get(tempProject))
            {
                if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Invoice')
                {
                    projectTotal += tempPoLine.rstk__soinvline_price__c;
                }
                else if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Credit Memo')
                {
                   projectTotal -= tempPoLine.rstk__soinvline_price__c;
                } 
            } 

            if(mapOfProjectBudgetsByProject.get(tempProject).Project_Sales_Tax__c != projectTotal)
            {
                if(mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id) == null)
                {
                    rstk__pjprojcst__c tempProjectItem = new rstk__pjprojcst__c();

                    tempProjectItem.Id = mapOfProjectBudgetsByProject.get(tempProject).Id;
                    tempProjectItem.Project_Sales_Tax__c = projectTotal;

                    mapOfProjectBudgetToUpdate.put(tempProjectItem.Id, tempProjectItem);
                }
                else 
                {
                    mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id).Project_Sales_Tax__c = projectTotal;
                }
            }
        }

        System.debug(mapOfProjectBudgetToUpdate);
    }

    /**
    * updateProjectIntercompany
    *
    * Function which looks at the system for any Sales Order Line 
    * for Tax. It calculates the total 
    * amount (unit price * quantity) and 
    * will update the Project Budget/Cost record
    * if the value is different
    */
    public void updateProjectIntercompany(List<rstk__pjprojcst__c> newList)
    {
        System.debug('ProjectBudgetCostTriggerHandler.updateProjectIntercompany');

        newList = getCleanedNonOverrideList(newList);

        // 1. Bucket Project Budget/Cost by Project Master for later
        Map<Id, rstk__pjprojcst__c> mapOfProjectBudgetsByProject = new Map<Id, rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            mapOfProjectBudgetsByProject.put(tempProject.rstk__pjprojcst_proj__c, tempProject);
        }

        System.debug(mapOfProjectBudgetsByProject);

        // 2. Query the system for SO lines containing Vehicle Ship Charge in the name
        if(ListOfAllSalesOrderInvoiceLines.size() == 0)
        {
            ListOfAllSalesOrderInvoiceLines = getListOfInvoiceLines(newList);
        }
        
        ListOfAllSalesOrderInvoiceLinesInterCompany = getListOfIntercompanyInvoiceLines(ListOfAllSalesOrderInvoiceLines);

        List<rstk__soinvline__c> listOfTransactions = ListOfAllSalesOrderInvoiceLinesInterCompany;

        // 3. Group the Transactions into their respective projects
        Map<Id, List<rstk__soinvline__c>> mapOfProjectSoInvoiceLines = new Map<Id, List<rstk__soinvline__c>>();

        for(rstk__soinvline__c tempSoInvLine : listOfTransactions)
        {
            if(mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c) == null)
            {
                List<rstk__soinvline__c> tempList = new List<rstk__soinvline__c>();

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
            else 
            {
                List<rstk__soinvline__c> tempList = mapOfProjectSoInvoiceLines.get(tempSoInvLine.rstk__soinvline_project__c);

                tempList.add(tempSoInvLine);

                mapOfProjectSoInvoiceLines.put(tempSoInvLine.rstk__soinvline_project__c, tempList);
            }
        }

        System.debug(mapOfProjectSoInvoiceLines);

        // 4. Calculate the totals and if they're different than the current, put them in for an update
        for(Id tempProject : mapOfProjectSoInvoiceLines.keySet())
        {
            Double projectTotal = 0.0;

            for(rstk__soinvline__c tempPoLine : mapOfProjectSoInvoiceLines.get(tempProject))
            {
                if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Invoice')
                {
                    projectTotal += tempPoLine.rstk__soinvline_price__c;
                }
                else if(tempPoLine.rstk__soinvline_invoice__r.rstk__soinv_txntype__c == 'Credit Memo')
                {
                   projectTotal -= tempPoLine.rstk__soinvline_price__c;
                } 
            }

            if(mapOfProjectBudgetsByProject.get(tempProject).Project_Intercompany_Offset__c != projectTotal)
            {
                if(mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id) == null)
                {
                    rstk__pjprojcst__c tempProjectItem = new rstk__pjprojcst__c();

                    tempProjectItem.Id = mapOfProjectBudgetsByProject.get(tempProject).Id;
                    tempProjectItem.Project_Intercompany_Offset__c = projectTotal;

                    mapOfProjectBudgetToUpdate.put(tempProjectItem.Id, tempProjectItem);
                }
                else 
                {
                    mapOfProjectBudgetToUpdate.get(mapOfProjectBudgetsByProject.get(tempProject).Id).Project_Intercompany_Offset__c = projectTotal;
                }
            }
        }

        System.debug(mapOfProjectBudgetToUpdate);
    }

    // AMM1
    /**
    * updateProjectNicIssue
    *
    * Function which looks at the system for any NIC Issue transactions 
    * which would contribute to additional allocated costs on shipment
    */
    public void updateProjectNicIssue(List<rstk__pjprojcst__c> newList)
    {
        System.debug('ProjectBudgetCostTriggerHandler.updateProjectNicIssue');

        newList = getCleanedNonOverrideList(newList);
        
        // 1. Get list of Project Ids
        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__pjprojcst__c tempProject : newList)
        {
            listOfProjectIds.add(tempProject.rstk__pjprojcst_proj__c);
        }

        // 2. Get list of Cost Transactions tied to the projects which are SOISS/SOISSR for order type Sales Orders
        List<rstk__sytxncst__c> listOfCostTransaction = ([SELECT Id,
                                                            rstk__sytxncst_ordproj__c,                          // Order Project
                                                            rstk__sytxncst_ucsttotext__c                        // Unit Cost, Extended
                                                        FROM rstk__sytxncst__c 
                                                        WHERE
                                                              rstk__sytxncst_txnid__c = 'NIC ISSUE' AND
                                                              rstk__sytxncst_proj__c IN :listOfProjectIds
                                                          ]);

        // 3. Group the Transactions by Project for simpler processing
        Map<Id, List<rstk__sytxncst__c>> mapOfCostTransactionsToProject = new Map<Id, List<rstk__sytxncst__c>>();

        for(rstk__sytxncst__c tempCost : listOfCostTransaction)
        {
            if(mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_ordproj__c) == null)
            {
                List<rstk__sytxncst__c> tempList = new List<rstk__sytxncst__c>();

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_ordproj__c, tempList);
            }
            else
            {
                List<rstk__sytxncst__c> tempList = mapOfCostTransactionsToProject.get(tempCost.rstk__sytxncst_ordproj__c);

                tempList.add(tempCost);

                mapOfCostTransactionsToProject.put(tempCost.rstk__sytxncst_ordproj__c, tempList);       
            }
        }

        // 4. Calculate the totals
        for(rstk__pjprojcst__c tempProject : newList)
        {   
            Decimal totalCost = 0.0;

            if(mapOfCostTransactionsToProject.get(tempProject.rstk__pjprojcst_proj__c) != null)
            {
                for(rstk__sytxncst__c tempCost : mapOfCostTransactionsToProject.get(tempProject.rstk__pjprojcst_proj__c))
                {
                    totalCost = totalCost + tempCost.rstk__sytxncst_ucsttotext__c;
                }
            }

            if(mapOfProjectBudgetToUpdate.get(tempProject.Id) == null)
            {
                rstk__pjprojcst__c tempProject2 = new rstk__pjprojcst__c(Id = tempProject.Id , Project_NIC_Issue_Cost__c = totalCost);

                mapOfProjectBudgetToUpdate.put(tempProject.Id, tempProject2);
            }
            else 
            {
                mapOfProjectBudgetToUpdate.get(tempProject.Id).Project_NIC_Issue_Cost__c = totalCost;
            }
        }
    }
    // AMM1

    public List<rstk__soinvline__c> getListOfFrieghtInvoiceLines(List<rstk__soinvline__c> invoiceLines)
    {
        List<rstk__soinvline__c> listToReturn = new List<rstk__soinvline__c>();

        for(rstk__soinvline__c tempInvLine : invoiceLines)
        {
            if(tempInvLine.Product_Name__c.contains('VEHICLE SHIP CHARGE') || tempInvLine.Product_Name__c.contains('Part Ship Charge'))
            {
                listToReturn.add(tempInvLine);
            }
        }

        System.debug('ProjectBudgetCostTriggerHandler.getListOfFrieghtInvoiceLines');
        System.debug(listToReturn);

        return listToReturn;
    }

    public List<rstk__soinvline__c> getListOfTaxInvoiceLines(List<rstk__soinvline__c> invoiceLines)
    {
        List<rstk__soinvline__c> listToReturn = new List<rstk__soinvline__c>();

        for(rstk__soinvline__c tempInvLine : invoiceLines)
        {
            if(tempInvLine.Product_Name__c.contains('Sales Tax'))
            {
                listToReturn.add(tempInvLine);
            }
        }

        System.debug('ProjectBudgetCostTriggerHandler.getListOfTaxInvoiceLines');
        System.debug(listToReturn);

        return listToReturn;
    }

    public List<rstk__soinvline__c> getListOfIntercompanyInvoiceLines(List<rstk__soinvline__c> invoiceLines)
    {
        List<rstk__soinvline__c> listToReturn = new List<rstk__soinvline__c>();

        for(rstk__soinvline__c tempInvLine : invoiceLines)
        {
            if(tempInvLine.Product_Name__c.contains('Inter-company'))
            {
                listToReturn.add(tempInvLine);
            }
        }

        System.debug('ProjectBudgetCostTriggerHandler.getListOfIntercompanyInvoiceLines');
        System.debug(listToReturn);

        return listToReturn;
    }

    public List<rstk__soinvline__c> getListOfInvoiceLines(List<rstk__pjprojcst__c> newList)
    {
        List<Id> listOfProjectIds = new List<Id>();

        for(rstk__pjprojcst__c tempProjeect : newList)
        {
            listOfProjectIds.add(tempProjeect.rstk__pjprojcst_proj__c);
        }
        
        return ([SELECT Id,
                    rstk__soinvline_project__c,                             // Project Master
                    rstk__soinvline_price__c,                               // Total Line Price
                    rstk__soinvline_invoice__r.rstk__soinv_txntype__c,      // Transaction Type (Invoice or Credit Memo)
                    rstk__soinvline_invoice__r.rstk__soinv_freightamt__c,   // Freight Charge
                    Product_Name__c
                FROM rstk__soinvline__c
                WHERE rstk__soinvline_project__c IN :listOfProjectIds AND
                    (Product_Name__c LIKE '%VEHICLE SHIP CHARGE%' OR
                     Product_Name__c LIKE '%Part Ship Charge%' OR
                     Product_Name__c LIKE '%Sales Tax%' OR 
                     Product_Name__c LIKE '%Inter-company%') AND
                    rstk__soinvline_invoice__r.rstk__soinv_transferred__c = true]);
    }

    /**
    * getCleanedNonOverrideList
    *
    * Function which takes out the Project Budget/Cost records which have 
    * the checkbox "Project Override Calculation" enabled since they shouldn't
    * be considered in any calculations.
    */
    public List<rstk__pjprojcst__c> getCleanedNonOverrideList(List<rstk__pjprojcst__c> newList)
    {
        List<rstk__pjprojcst__c> tempList = new List<rstk__pjprojcst__c>();

        for(rstk__pjprojcst__c tempItem : newList)
        {
             // AMM1
            // if(tempItem.Project_Override_Calculation__c == false)
            if(tempItem.Project_Override_Calculation__c == false && tempItem.Name != 'AK Home Project' && tempItem.Name != 'KC Home Project' && tempItem.Name != 'SC Home Project')
            // AMM1
            {
                tempList.add(tempItem);
            }
        }

        return tempList;
    }
}