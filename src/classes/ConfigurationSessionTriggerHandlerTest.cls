/**
* MobilityWorks (c) - 2017
*
* ConfigurationSessionTriggerHandlerTest
* 
* Programmer: Alexander Miller
* Date: 2018-1-8
*/
@isTest(SeeAllData = true)
public class ConfigurationSessionTriggerHandlerTest {

   public static testMethod void testLatestSoMarking()
   {
       Test.StartTest();

        rstk__soline__c saleLine = ([SELECT Id, 
                                            rstk__soline_sohdr__c,
                                            CreatedDate,
                                            rstk__soline_confsess__c 
                                    FROM rstk__soline__c 
                                    WHERE rstk__soline_confsess__c != null 
                                    LIMIT 1]);

        rstk__confsess__c tempConfig = ([SELECT Id
                                        FROM rstk__confsess__c 
                                        WHERE Id = :saleLine.rstk__soline_confsess__c 
                                        LIMIT 1]);
        update tempConfig;

       Test.StopTest();
   }

   public static testMethod void testClone()
   {
       Test.StartTest();

        // get configuration session
        rstk__confsess__c tempConfig = ([SELECT Id FROM rstk__confsess__c LIMIT 1]);
        tempConfig.clone(true,true,true,true);

       Test.StopTest();
   }
}