/**
 * VehicleInventoryEmailHandler_TEST
 * Tested by: VehicleInventoryEmailHandler
 * Date: August 23rd, 2017
 * Programmer: Alexander Miller
 * Work: W-000139
 */
@isTest
public class VehicleInventoryEmailHandler_TEST {

    @testSetup
    public static void testSetup(){

        User tempUser = [SELECT Id FROM User WHERE isActive = true LIMIT 1];

        List<dealer__Vehicle_Inventory__c> listOfVehicles = new List<dealer__Vehicle_Inventory__c>();
 
        dealer__Vehicle_Inventory__c vehicle = new dealer__Vehicle_Inventory__c();
        vehicle.Name = 'Batmobile';
        vehicle.dealer__Make__c = 'Honda';
        vehicle.dealer__Model__c = 'Accord';
        vehicle.dealer__VIN__c = '5FNRL5H91HB000178';
        vehicle.dealer__Year__c = '2004';
        vehicle.dealer__Stock_Number__c = 'HB000178';
        listOfVehicles.add(vehicle);

        dealer__Vehicle_Inventory__c vehicle2 = new dealer__Vehicle_Inventory__c();
        vehicle2.Name = 'Millennium Falcon';
        vehicle2.dealer__Make__c = 'Porsche';
        vehicle2.dealer__Model__c = 'Boxster';
        vehicle2.dealer__VIN__c = '5FNRL5H91HS770923';
        vehicle2.dealer__Year__c = '2017';
        vehicle2.dealer__Stock_Number__c = 'HS770923';
        listOfVehicles.add(vehicle2);

        insert listOfVehicles;
    }

    public static testMethod void testAttachmentsVMI(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();
   
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Testing PO auto-attachment.\n';
        email.subject = 'VMI Pricing Confirmation: VMI #T1703390 - VIN #HB000178 MobilityWorks';
        email.fromAddress = 'fakeAddress@VantageMobility.com';
  
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = '12345.pdf';

        Messaging.InboundEmail.BinaryAttachment attachment2 = new Messaging.InboundEmail.BinaryAttachment();
        attachment2.body = blob.valueOf('my attachment text');
        attachment2.fileName = '12345.txt';

        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment, attachment2 };

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();

        // assert the record was updated and the attachment found
        List<Attachment> listOfAttachments = ([SELECT Id FROM Attachment]);
        System.assertEquals(1, listOfAttachments.size());

        dealer__Vehicle_Inventory__c testVehicle = [SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = 'HB000178' LIMIT 1];
        System.assertNotEquals(null, testVehicle.Order_Confirmation_Date_Time__c);
    }

    public static testMethod void testAttachmentsBraun(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: HS770923-SO-HS770923\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@braunability.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = '12345.pdf';
        
        Messaging.InboundEmail.BinaryAttachment attachment2 = new Messaging.InboundEmail.BinaryAttachment();
        attachment2.body = blob.valueOf('my attachment text');
        attachment2.fileName = '12345.txt';

        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment, attachment2 };

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();

        // assert the record was updated and the attachment found
        List<Attachment> listOfAttachments = ([SELECT Id FROM Attachment]);
        System.assertEquals(1, listOfAttachments.size());

        dealer__Vehicle_Inventory__c testVehicle = [SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = 'HS770923' LIMIT 1];
        System.assertNotEquals(null, testVehicle.Order_Confirmation_Date_Time__c);
    }

    public static testMethod void testDuplicateFailure(){
        Test.startTest();

        // update the confirmation date to throw the error for duplicate data
        dealer__Vehicle_Inventory__c testVehicle = [SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = 'HB000178' LIMIT 1];
        testVehicle.Order_Confirmation_Date_Time__c = Datetime.valueOf('2017-08-28 17:42:00');
        update testVehicle;

        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: HS770923-so-HS770923\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@braunability.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = '12345.txt';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();

        // assert the record was updated and the attachment found
        dealer__Vehicle_Inventory__c testVehicle2 = [SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = 'HB000178' LIMIT 1];
        System.assertEquals('2017-08-28 17:42:00', String.valueOf(testVehicle2.Order_Confirmation_Date_Time__c));
    }

    public static testMethod void testEmailFailure(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Hello,';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@gmail.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = '12345.txt';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();
    }

    public static testMethod void testSTQ(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Hello,';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@gmail.com';
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: STQ-48457 - HS877252\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();
    }

    public static testMethod void testST(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Hello,';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@gmail.com';
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: ST-HS882319\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();
    }

    public static testMethod void testSTBothSides(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Hello,';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@gmail.com';
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: HR797108-ST-HR797108\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();
    }

    public static testMethod void testSO(){
        Test.startTest();
        VehicleInventoryEmailHandler handler = new VehicleInventoryEmailHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Organization org = [select Id, Name from Organization limit 1];
        email.plainTextBody = 'Hello,';
        email.subject = 'BraunAbility Sales Order Acknowledgement 197953';
        email.fromAddress = 'fakeAddress@gmail.com';
        email.plainTextBody = 'Thank you,\n' +
                                'Vehicle Inventory Manager; Quantity Unit Price Freq\n' +
                                'Sales Order Number: 197953\n' +
                                'Customer PO: SO-HS876157\n' +
                                'Please do not reply to this message. Replies to this message are routed to an unmonitored mailbox';

        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);

        Test.stopTest();
    }
}