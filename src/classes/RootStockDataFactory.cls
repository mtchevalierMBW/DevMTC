/**
* TransitWorks (c) - 2018
*
* Created By: Alexander Miller
* Created Date: 5/9/2018
* Description: Collection of all test data functions for all of TransitWorks
* and by extension, RootStock
*
* Modified By         Alias       Work Item       Date         Reason
* ---------------------------------------------------------------------
* Alexander Miller    AMM1        W-000464        10/29/2018   Update to handle Custom TransitWorks Opporutnity Testing
* Alexander Miller    AMM2        IR-0050229      3.6.2019     Test class failure due to related updates
*/
@isTest(SeeAllData = true)
public class RootStockDataFactory {

    /**
    * getWorkOrderByStatusAndDivision()
    *
    * Function which looks out into the 
    * system for a Work Order in a chosen 
    * status and division
    *
    * @param statusLevel - String value representing the Work Order stage. Current values: 2 (Firm), 5 (Picklist Generated), 8 (Receipt), 9 (Closed)
    * @param division - Id of the division desired
    *
    * @return rstk__wocst__c - Work Order matching the parameter constrains for status and division
    */
    public static rstk__wocst__c getWorkOrderByStatusAndDivision(String statusLevel, Id division)
    {
        return [SELECT Id,
                    rstk__wocst_div__c,
                    rstk__wocst_ordsts__c
                FROM rstk__wocst__c 
                WHERE rstk__wocst_ordsts__c = :statusLevel AND 
                    rstk__wocst_div__c = :division 
                ORDER BY CreatedDate DESC
                LIMIT 1];
    }

    /**
    * getWorkOrderWithNoHoursIssued()
    */
    public static rstk__wocst__c getWorkOrderWithNoHoursIssued(Id division)
    {
        return [SELECT Id,
                    rstk__wocst_div__c,
                    rstk__wocst_ordsts__c
                FROM rstk__wocst__c 
                WHERE rstk__wocst_totlabhrs__c = 0 AND 
                    rstk__wocst_div__c = :division 
                LIMIT 1];
    }

    /**
    * issueHoursToWorkOrder()
    */
    public static void issueHoursToWorkOrder(Id division, Id orderNumber, Id operation, Id manufacturingUser, Integer hours)
    {
        rstk__sydata__c tempSyData = new rstk__sydata__c();

        tempSyData.rstk__sydata_sourcepgm__c= 'RootStockDataFactory';
        tempSyData.rstk__sydata_txntype__c = 'Labor Booking';
        tempSyData.rstk__sydata_wocst__c = orderNumber;
        tempSyData.rstk__sydata_woordopn__c = operation;
        tempSyData.rstk__sydata_bksyusr__c = manufacturingUser;
        tempSyData.rstk__sydata_hours__c = hours;

        insert tempSyData;
    }

    /**
    * getManufacturingUser()
    */
    public static rstk__syusr__c getManufacturingUser(Id division)
    {
        return [SELECT Id
                FROM rstk__syusr__c 
                WHERE rstk__syusr_dfltdiv__c = :division AND
                (rstk__syusr_licreq__c = true OR rstk__syusr_laboronly__c = true) AND
                rstk__syusr_obsolete__c = false
                LIMIT 1];
    }

    /**
    * getWorkOrderOperation()
    */
    public static rstk__woordop__c getWorkOrderOperation(Id orderNumber)
    {
        return [SELECT Id
                FROM rstk__woordop__c 
                WHERE rstk__woordop_ordno__c = :orderNumber
                LIMIT 1];
    }

    /**
    * createWorkOrder()
    */
    public static rstk__wocst__c createWorkOrder(String orderNumber, Id division, Id inventoryItem, Id project)
    {
        rstk__wocst__c tempWorkOrder = new rstk__wocst__c();   

        tempWorkOrder.rstk__wocst_div__c = division;
        tempWorkOrder.rstk__wocst_ordno__c = orderNumber;
        tempWorkOrder.rstk__wocst_item__c = inventoryItem;
        tempWorkOrder.rstk__wocst_qtyreq__c = 1;
        tempWorkOrder.rstk__wocst_duedte__c = System.today();
        tempWorkOrder.rstk__wocst_proj__c = project;

        return tempWorkOrder;
    }

    /**
    * getProjectMaster()
    */
    public static rstk__pjproj__c getProjectMaster(Id division)
    {
        return [SELECT Id
                FROM rstk__pjproj__c
                WHERE rstk__pjproj_div__c = :division
                LIMIT 1];
    }

    /**
    * getDivisionMaster()
    */
    public static rstk__sydiv__c getDivisionMaster(String name)
    {
        String divName = '%' + name + '%';

        return [SELECT Id
                FROM rstk__sydiv__c
                WHERE Name LIKE :divName
                LIMIT 1];
    }

    /**
    * getFinishedGoodInventoryItem()
    */
    public static rstk__icitem__c getFinishedGoodInventoryItem(Id division)
    {
        return [SELECT Id
                FROM rstk__icitem__c
                WHERE rstk__icitem_div__c = :division AND
                    rstk__icitem_iccomcod__r.Name LIKE '%Finished%'
                LIMIT 1];
    }

    public static Chassis_Master__c createChassisMaster(String year, String make, String vin, String keytag, Id division)
    {
        Chassis_Master__c tempChassis = new Chassis_Master__c();

        tempChassis.Created_From_PO__c = true;
        tempChassis.VIN__c = vin;
        tempChassis.Key_Tag__c = keytag;
        tempChassis.Year__c = year;
        tempChassis.Make__c = make;
        tempChassis.Division__c = division;

        return tempChassis;
    }

    // AMM1
    public static Opportunity__c createGenericCustomOpportunity(String name, String salesChannel, Date closeDate, Id owner)
    {
        Opportunity__c tempOpp = new Opportunity__c(
            OwnerId = owner,
            Customer_Master__c = getCustomerMaster().Id,
            Close_Date__c=closeDate, 
            Name=name, 
            // AMM2
            //Status__c='Pending', 
            Status__c='Initial Contact',
            // AMM2
            Sales_Channel__c = salesChannel,
            Number_Of_Orders__c = 1
        );

        return tempOpp;
    }

    public static rstk__socust__c getCustomerMaster()
    {
        return [SELECT Id FROM rstk__socust__c LIMIT 1];
    }
    // AMM1

    public static Opportunity createOpportunity(String name, String stage, String salesChannel, Date closeDate, Id owner)
    {
        Opportunity tempOpp = new Opportunity(
                OwnerId = owner,
                CloseDate=closeDate, 
                Name=name, 
                StageName=stage, 
                Sales_Channel__c = salesChannel,
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('TransitWorksOpps').getRecordTypeId());

        return tempOpp;
    }

    public static User createSalesUser()
    {
        // AMM2
        // Profile profileId = [SELECT Id FROM Profile WHERE Name = 'RS TW Sales' LIMIT 1];
        //
        // User usr = new User(
        //     LastName = generateRandomString(6),
        //     FirstName= generateRandomString(6),
        //     Alias = generateRandomString(4),
        //     Email = generateRandomString(6) + '@' + generateRandomString(3) + '.com',
        //     Username = generateRandomString(6) + '@' + generateRandomString(3) + '.com',
        //     ProfileId = profileId.id,
        //     TimeZoneSidKey = 'GMT',
        //     LanguageLocaleKey = 'en_US',
        //     EmailEncodingKey = 'UTF-8',
        //     LocaleSidKey = 'en_US',
        //     Division = 'TWK'
        // );
        //
        // return usr;
        // AMM2

        return [SELECT Id, FirstName, LastName, Alias, Email, Username, ProfileId FROM User WHERE Profile.Name = 'RS TW Sales' LIMIT 1];
    }
    
    public static rstk__soapi__c createSOAPISalesOrderHeader(Id manufacturingUser, Id divisionId, Id customerId, Id productId)
    {
        rstk__soapi__c testSO = new rstk__soapi__c(); 
        testSO.rstk__soapi_syusr__c = manufacturingUser;    // manufacturing user 
        testSO.rstk__soapi_ssysdiv__c = divisionId;    		// sales division 
        testSO.rstk__soapi_isysdiv__c = divisionId;    		// inventory division 
        testSO.rstk__soapi_socust__c = customerId;     		// Customer 
        testSO.rstk__soapi_soprod__c = productId;      		// Product 
        testSO.rstk__soapi_qtyorder__c = 1;                 // qty ordered 
        testSO.rstk__soapi_throwerrors__c = true;           // show errors, if any 
        testSO.rstk__soapi_async__c = false;                // Not Async
        testSO.rstk__soapi_mode__c = 'Add Header';          // see attached documentation to see picklist options at the top 
        return  testSO;
	}

    public static String generateRandomString(Integer len) {
        
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        
        while (randStr.length() < len) 
        {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }

        return randStr; 
    }
}