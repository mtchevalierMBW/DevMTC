/**
 * WMK, LLC (c) - 2018 
 *
 * DataFTPUtility
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/19/2018 
 * Tested By:    DataFTPUtilityTest
 * Work Item:    W-000502
 *
 * Batch Class which cycles through all open Proposals
 * to find open deals which need to be sent off to a particular 
 * client. Microsoft Flow handles the inbound email and 
 * CSV file attachment to then kick off and send
 * to the end customer via FTP.
 *  
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
global class DataFTPUtility implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	global final Map<Id, Account> mapOfUsedParentAccounts;

    public DataFTPUtility()
	{
		mapOfUsedParentAccounts = new Map<Id, Account>();
	}

    // Schedulable context
	global void execute(SchedulableContext ctx) 
    {
        DataFTPUtility tempHandler = new DataFTPUtility();
        Database.executeBatch(tempHandler, 1);
	}

    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        // Production Query
        // String query = 'SELECT Id, ' +
		//					'Data_FTP_Email__c ' +
        //    			'FROM Account ' +
		//				'WHERE Id IN (SELECT dealer__Buyer__c ' + 
		//							'FROM dealer__Deal__c ' +
		//							'WHERE dealer__Status__c LIKE \'%Won%\' AND ' +
		//							'dealer__Status__c != \'Won - Deposit\' AND ' + 
		//							'dealer__Status__c != \'Won - Posted\' AND ' + 
		//							'Posted_DT__c >= TODAY) AND ' + 
		//					'Send_Data_FTP__c = True AND ' +
		//					'Data_FTP_Email__c != null'; 

		// Dev Query
		String query = 'SELECT Id, ' +
							'Data_FTP_Email__c ' +
            			'FROM Account ' +
						'WHERE Id IN (SELECT dealer__Buyer__c ' + 
									'FROM dealer__Deal__c ' +
									'WHERE dealer__Status__c LIKE \'%Won%\' AND ' +
									'dealer__Status__c != \'Won - Deposit\' AND ' + 
									'dealer__Status__c != \'Won - Posted\') AND ' + 
							'Send_Data_FTP__c = True AND ' +
							'Data_FTP_Email__c != null'; 

        if(Test.isRunningTest())
        {
            query = 'SELECT Id, ' +
							'Data_FTP_Email__c ' +
            			'FROM Account ' +
						'WHERE Id IN (SELECT dealer__Buyer__c ' + 
									'FROM dealer__Deal__c ' +
									'WHERE dealer__Status__c LIKE \'%Won%\' AND ' +
									'dealer__Status__c != \'Won - Deposit\' AND ' + 
									'dealer__Status__c != \'Won - Posted\') AND ' + 
							'Send_Data_FTP__c = True AND ' +
							'Data_FTP_Email__c != null' + 
							'LIMIT 1'; 
		}

		return Database.getQueryLocator(query);
	}

    global void execute(Database.BatchableContext bc, List<Account> scope) 
    {
		// 1. Get the Root Account in the tree
		Id rootAccountId = getAccountRootParent(scope.get(0).Id);

		// Prevent accidental duplicates by starting every email compilation based on the parent Account
		if(mapOfUsedParentAccounts.get(rootAccountId) == null)
		{
			Account rootAccount = [SELECT Id, 
								Data_FTP_Email__c 
							FROM Account 
							WHERE Id = :scope LIMIT 1];

			mapOfUsedParentAccounts.put(rootAccountId, rootAccount);

			// 2. Get the child Accounts of the given root
			List<Account> listOfAccounts = getAccountChildren(rootAccountId);
			listOfAccounts.add(rootAccount);

			// 3. Get destination email for the single Account passed into batch class
			String destEmail = rootAccount.Data_FTP_Email__c;

			// 4. Get all open deals for a given Customer
			List<dealer__Deal__c> listOfProposals = getListOfDealsRelatedToAccount(listOfAccounts);

			// 5. Package the Proposals in CSV
			String csvData = getCSVData(listOfProposals);

			// 6. Define CSV Headers
			String csvHeaders = 'Enterprise PO#,Enterprise Unit#,Vehicle Manufacturer,Vehicle Make,VIN,Order Created Date,Estimated Completion Date,Actual Start Date,Actual Completion Date,Release for Transport Date,Delivery Destination Street, Delivery Destination City, Delivery Destination State, Delivery Destination Postal,Sold To Customer Name';

			csvHeaders += '\n' + csvData;
			
			// 7. Send the emails
			sendEmail(csvHeaders, destEmail);
		}
	}
	
	global void finish(Database.BatchableContext bc) {}

	/**
	* getAccountRootParent
	*
	* Function which cycles through a given Account Id
	* for the absolute root node
	*/
	public Id getAccountRootParent(Id accountId)
	{
		Boolean topLevelParent = false;

        while ( !topLevelParent ) 
		{
            Account a = [ SELECT Id, 
							ParentId 
						FROM Account 
						WHERE Id =: accountId 
						LIMIT 1 ];

            if ( a.ParentID != null ) 
			{
                accountId = a.ParentID;
            }
            else 
			{
                topLevelParent = true;
            }
        }
        return accountId;
	}

	/**
	* getAccountChildren 
	*
	* Function which looks at the system for all child nodes 
	* to a given parent id
	*/
	public List<Account> getAccountChildren(Id parentAccountId)
	{
		List<Account> tempList = ([SELECT Id, 
										(SELECT Id,
											ParentId,
											Data_FTP_Email__c,
											Send_Data_FTP__c
										FROM ChildAccounts
										WHERE Send_Data_FTP__c = True AND 
												Data_FTP_Email__c != null) 
									FROM Account
									WHERE Id = :parentAccountId]);

		List<Account> childAccounts = new List<Account>();

		for(Account tempParent : tempList)
		{
			for(Account tempChild : tempParent.ChildAccounts)
			{
				childAccounts.add(tempChild);
			}
		}

		return childAccounts;
	}

	/**
	* getListOfDealsRelatedToAccount
	*
	* Function which gathers all the Won proposals 
	* related to Accounts on the Buyer Account field
	*/
	public List<dealer__Deal__c> getListOfDealsRelatedToAccount(List<Account> tempList)
	{
		List<Id> listOfAccountIds = new List<Id>();

		for(Account tempAccount : tempList)
		{
			listOfAccountIds.add(tempAccount.Id);
		}

		return ([SELECT Id,
					Customer_Purchase_Order__c,									// Enterprise PO #
					Job_Reference__c, 											// Enterprise Unit #
					dealer__Make__c,  											// Vehicle Manufacturer
					dealer__Model__c,											// Vehicle Make
					dealer__VIN__c,  											// VIN
					CreatedDate, 												// Order Created Date
					Proposed_Delivery_Date__c,									// Estimated Completion Date
					dealer__Vehicle__r.Mfg_Build_Date__c,						// Actual Start Date
					dealer__Vehicle__r.dealer__Purchase_Date__c,				// Actual Start Date (if mfg date is null)
                 	dealer__Vehicle__r.dealer__Inventory_Date__c, 				// Actual Completion Date - Releast for Transport Date (Actual complete + 2 days)
					dealer__Delivery_Street__c,									// Delivery Destination
					dealer__Delivery_City__c,									// Delivery Destination
					dealer__Delivery_State__c,									// Delivery Destination
					dealer__Delivery_Postal_Code__c,							// Delivery Destination
					dealer__Sales_Lead__r.Sold_To_Customer__c,					// Sold To Customer Name
					dealer__Buyer__c,  				
					dealer__Buyer__r.Data_FTP_Email__c  						// Individual Microsoft Flow Inbox email
				FROM dealer__Deal__c             			
				WHERE dealer__Status__c LIKE 'Won%' AND
					dealer__Status__c != 'Won - Deposit' AND
					dealer__Status__c != 'Won - Posted' AND   
					dealer__Buyer__c IN :listOfAccountIds]);
	}

	/**
	* getCSVData
	*
	* Function which converts the Proposal
	* records into a CSV-acceptable format
	*/
	public String getCSVData(List<dealer__Deal__c> tempList)
	{
		String newLine = '\n';
		String comma = ',';
		String mainData = '';

		BusinessHours bh = [SELECT ID, Name, IsDefault, IsActive From BusinessHours WHERE IsDefault = TRUE];

		for(dealer__Deal__c tempDeal : tempList)
		{
			Date actualStartDate = tempDeal.dealer__Vehicle__r.dealer__Purchase_Date__c != null ? tempDeal.dealer__Vehicle__r.dealer__Purchase_Date__c : tempDeal.dealer__Vehicle__r.dealer__Purchase_Date__c;

			Date releaseForTransport = tempDeal.dealer__Vehicle__r.dealer__Inventory_Date__c;
			if(releaseForTransport != null)
			{
				// add 3 business days. Excluding weekends and holidays
				Datetime createdDate = system.now();

				Long dt1Long = DateTime.now().addDays(3).getTime();
				Long dt2Long = DateTime.now().getTime();
				Long milliseconds = dt1Long - dt2Long;
				System.debug(milliseconds);
				
				Datetime dueDate = BusinessHours.add(bh.Id, createdDate, milliseconds);
				
				releaseForTransport = dueDate.Date();
			}

			mainData += getCleanedString(tempDeal.Customer_Purchase_Order__c) + comma + 
						getCleanedString(tempDeal.Job_Reference__c) + comma +
						tempDeal.dealer__Make__c + comma +
						tempDeal.dealer__Model__c + comma +
						tempDeal.dealer__VIN__c + comma +
						tempDeal.CreatedDate + comma + 
                		tempDeal.Proposed_Delivery_Date__c + comma + 
						actualStartDate + comma +
						tempDeal.dealer__Vehicle__r.dealer__Inventory_Date__c + comma +
						releaseForTransport + comma +
						tempDeal.dealer__Delivery_Street__c + comma +
						tempDeal.dealer__Delivery_City__c + comma +
						tempDeal.dealer__Delivery_State__c + comma +
						tempDeal.dealer__Delivery_Postal_Code__c + comma +
						tempDeal.dealer__Sales_Lead__r.Sold_To_Customer__c +
						newLine;
		}

		return mainData;
	}

	/**
	* getCleanedString
	*
	* Function which cleans the string 
	* so that it will properly fit into a CSV
	*
	* Single/Double quotes, commas, etc
	*/
	public String getCleanedString(String tempString)
	{
		if(tempString != null)
		{
			return tempString.escapeCSV().remove(',');
		}
		else 
		{
			return '';
		}
	}

	/**
	* sendEmail
	*
	* Function which fires off the data to the integration
	*/
	public void sendEmail(String csvData, String destinationEmail)
	{
		Organization org = [select Id, Name, InstanceName, isSandbox from Organization limit 1];

		List<String> recipients = new List<String>();

		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		if(!org.isSandbox)
		{
			recipients.add(destinationEmail);
		} 
		else
		{
			recipients.add(UserInfo.getUserEmail());
		}

		System.debug(recipients);

		mail.setToAddresses(recipients); 

		String subject = 'Production Work Export for Client FTP';
		
		if (org.isSandbox)
		{
			subject += ' (' + org.InstanceName + ')';
		}

		mail.setSubject(subject);

		String body = 'FTP Export job part has completed.\n\n';

		if (String.isBlank(csvData))
		{
			body += 'No data generated for csv.\n\n';
		}

		mail.setPlainTextBody(body);

		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		resultcsv.setFileName('in.' + DateTime.now().format('yyyyMMddHHmmss') + '.csv');
		
		if (!String.isBlank(csvData))
		{
			resultcsv.Body = Blob.valueOf(csvData);
			listOfAttachments.add(resultcsv);
		}
		
		mail.setFileAttachments(listOfAttachments);

		emailMsgs.add(mail);

		Messaging.sendEmail(emailMsgs);
	}
}