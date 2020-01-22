/**
 * LightningFileUtility
 * 
 * Created By: Alexander Miller
 * Created Date: 10/3/2018 
 * Tested By: LightningFileUtilityTest
 * Work Item: W-000413
 * 
 * Description: 
 * 
 * Class which centralizes the Notes and Attachments process in Lightning files
 *
 * - Only 100,000 documents can be made/modified in a 24 hour period. The class won't let a single  batch go over that 
 *     amount but nothing prevents a collection of them hitting that limit. 
 * - SOQL will prevent you from querying more than 50,000 rows in a single calls anyways. 
 * - NOTE: SANDBOX ONLY ALLOWS 2,500 IN A 24 HOUR PERIOD
 *
 * Usage:
 * 
 * LightningFileUtility tempUtility = new LightningFileUtility();
 * tempUtility.addFile('Title', 'Body', parentId, true);  // Note
 * tempUtility.addFile('Title', EncodingUtil.base64Encode('Body'), parentId, false); // Attachment
 * tempUtility.commitFiles();
 * temputility.getErrors();
 * temputility.getErrorsHTML();
 * 
 * Modified By         Alias       Work Item       Date         Reason
 * -------------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050040      3/04/2019    To allow null note bodies 
 */
public class LightningFileUtility {

    /** list to hold all the data before, during, and post transactions */
    public List<fileObject> listOfFiles {get;set;}

    public List<ContentVersion> listofContentVersions {get;set;}

    public List<ContentNote> listOfContentNotes {get;set;}

    public List<ContentDocumentLink> listOfContentDocumentLinks {get;set;}

    /** list to hold all of the errors for given insertion, note or attachment */
    public String listOfErrors {get;set;}

    /** list to hold all of the errors for given insertion HTML format, note or attachment */
    public String listOfErrorsHTML {get;set;}

    public LightningFileUtility()
    {
        listOfFiles = new list<fileObject>();
        listofContentVersions = new List<ContentVersion>();
        listOfContentNotes = new List<ContentNote>();
        listOfContentDocumentLinks = new List<ContentDocumentLink>();
    }

    /**
    * addFile
    *
    * Function which takes the chosen data points and 
    * either builds a File or Note in Lightning
    *
    * @param Title     - String value for the title of the attachment
    * @param Body      - String value for the body of the attachment. Base64 for files, flat string for notes
    * @param ParentId  - Id of the parent
    * @param isNote    - Boolean to show if this is note or file data
    */
    public void addFile(String title, String body, Id parentId, Boolean isNote, Id ownerId)
    {
        listOfFiles.add(new fileObject(title, body, parentId, isNote, ownerId));
    }

    /**
    * getErrorsHTML
    *
    * Function which returns all the errors, if any
    * in their HTML format
    */
    public String getErrorsHTML()
    {
        return this.listOfErrorsHTML;
    }

    /**
    * getErrors
    *
    * Function which returns all the errors, if any
    */
    public String getErrors()
    {
        return this.listOfErrorsHTML;
    }

    /**
    * getListofContentVersions
    *
    * Function which returns all the Content Versions inserted
    */
    public List<ContentVersion> getListofContentVersions()
    {
        return this.listofContentVersions;
    }

    /**
    * getListofContentNotes
    *
    * Function which returns all the Content Note inserted
    */
    public List<ContentNote> getListofContentNotes()
    {
        return this.listOfContentNotes;
    }

    /**
    * getListofContentDocumentLinks
    *
    * Function which returns all the Content Document Links inserted
    */
    public List<ContentDocumentLink> getListofContentDocumentLinks()
    {
        return this.listOfContentDocumentLinks;
    }

    /**
    * getContentNotesByParentId
    * 
    * Function which gets all the field for 
    * Content Notes by Id of the parent record
    */
    public List<ContentNote> getContentNotesByParentId(Id parentId)
    {
        List<ContentDocumentLink> listOfDocumentLinks = getContentDocumentLinksByParentId(parentId);

        List<Id> listOfNoteIds = new List<Id>();

        for(ContentDocumentLink tempLink : listOfDocumentLinks)
        {
            listOfNoteIds.add(tempLink.ContentDocumentId);
        }

        List<ContentNote> listOfContentNotes = getContentNotesById(listOfNoteIds);

        return listOfContentNotes;
    }

    /**
    * getContentAttachmentsByParentId
    * 
    * Function which gets all the field for 
    * Content Documents by Id of the parent record
    */
    public List<ContentDocument> getContentDocumentsByParentId(Id parentId)
    {
        List<ContentDocumentLink> listOfDocumentLinks = getContentDocumentLinksByParentId(parentId);

        List<Id> listOfDocumentIds = new List<Id>();

        for(ContentDocumentLink tempLink : listOfDocumentLinks)
        {
            listOfDocumentIds.add(tempLink.ContentDocumentId);
        }

        List<ContentDocument> listOfContentDocuments = getContentDocumentsById(listOfDocumentIds);

        return listOfContentDocuments;
    }

    /**
    * getContentDocumentsById
    * 
    * Function which gets all the field for 
    * Content Documents by Id
    */
    public List<ContentDocument> getContentDocumentsById(List<Id> contentDocIds)
    {
        return ([SELECT Id,
                    ArchivedById,
                    ArchivedDate,
                    Title,
                    CreatedById,
                    CreatedDate,
                    Description,
                    FileExtension,
                    FileType,
                    LastModifiedById,
                    LastModifiedDate,
                    LastViewedDate,
                    OwnerId 
                FROM ContentDocument
                WHERE Id IN :contentDocIds
                ORDER BY CreatedDate DESC]);
    }

    /**
    * getContentNotesById
    * 
    * Function which gets all the field for 
    * Content Notes by Id
    */
    public List<ContentNote> getContentNotesById(List<Id> contentNoteIds)
    {
        return ([SELECT Id,
                    Content,
                    Title,
                    ContentSize,
                    CreatedById,
                    CreatedDate,
                    FileExtension,
                    FileType,
                    LastModifiedById,
                    LastModifiedDate,
                    LastViewedDate,
                    OwnerId,
                    SharingPrivacy
                FROM ContentNote
                WHERE Id IN :contentNoteIds]);
    }

    /**
    * getContentDocumentLinksByParentId
    *
    * Function which grabs all of the Links between Content and the parent records
    */
    public List<ContentDocumentLink> getContentDocumentLinksByParentId(Id parentId)
    {
        return ([SELECT Id,
                    ContentDocumentId,
                    LinkedEntityId,
                    ShareType,
                    Visibility
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :parentId]);
    }

    /**
    * commitFiles
    * 
    * Function which performs the needed operations to get the notes and/or attachments 
    * inserted into the database
    */
    public void commitFiles()
    {
        List<Database.SaveResult> saveresultsContentVersions = new List<Database.SaveResult>(); 
        List<Database.SaveResult> saveresultsContentDocumentLinks = new List<Database.SaveResult>(); 
        List<Database.SaveResult> saveresultsContentNotes = new List<Database.SaveResult>();
        List<Database.SaveResult> saveresultsContentDocumentLinks2 = new List<Database.SaveResult>();
        Map<String, ContentVersion> mapOfContentVersions = new Map<String, ContentVersion>();
        List<ContentDocumentLink> mapOfAttachmentLinks = new List<ContentDocumentLink>();
        Map<String, ContentNote> mapOfContentNotes = new Map<String, ContentNote>();
        List<ContentDocumentLink> listOfAttachmentLinks = new List<ContentDocumentLink>();
        
        // 0. separate the data sets

        List<fileObject> listOfAttachments = new List<fileObject>();
        Map<String, fileObject> mapOfAttachments = new Map<String, fileObject>();

        for(fileObject tempRecord : listOfFiles)
        {   
            if(tempRecord.isNote == false)
            {
                listOfAttachments.add(tempRecord);
                mapOfAttachments.put(tempRecord.CustomId, tempRecord);
            }
        }

        List<fileObject> listOfNotes = new List<fileObject>();
        Map<String, fileObject> mapOfNotes = new Map<String, fileObject>();

        for(fileObject tempRecord : listOfFiles)
        {   
            if(tempRecord.isNote)
            {
                listOfNotes.add(tempRecord);
                mapOfNotes.put(tempRecord.CustomId, tempRecord);
            }
        }

        System.debug(listOfAttachments);
        System.debug(listOfNotes);

        // 1. process Files
        if(listOfAttachments.size() > 0)
        {
            mapOfContentVersions = getContentVersions(listOfAttachments);

            System.debug(mapOfContentVersions);

            saveresultsContentVersions = Database.insert(mapOfContentVersions.values());

            mapOfContentVersions = getContentVersionsRefreshed(mapOfContentVersions);

            System.debug(mapOfContentVersions);

            mapOfAttachmentLinks = getContentDocumentLinks(mapOfContentVersions, mapOfAttachments);

            System.debug(mapOfAttachmentLinks);

            saveresultsContentDocumentLinks = Database.insert(mapOfAttachmentLinks);

            listofContentVersions.addAll(mapOfContentVersions.values());
            System.debug(listOfContentNotes);
            listOfContentDocumentLinks.addAll(mapOfAttachmentLinks);
        }

        // 2. process Notes
        if(listOfNotes.size() > 0)
        {
            mapOfContentNotes = getContentNotes(listOfNotes);

            System.debug(mapOfContentNotes);

            saveresultsContentNotes = Database.insert(mapOfContentNotes.values());

            listOfAttachmentLinks = getContentDocumentLinks(mapOfNotes, mapOfContentNotes);

            System.debug(listOfAttachmentLinks);
            
            saveresultsContentDocumentLinks2 = Database.insert(listOfAttachmentLinks);
            
            listOfContentNotes.addAll(mapOfContentNotes.values());
            System.debug(listOfContentNotes);
            listOfContentDocumentLinks.addAll(listOfAttachmentLinks);
        }

        // Generate all the errors, if any
        for(Integer i=0; i<saveresultsContentVersions.size(); i++) 
        {
            Database.SaveResult sr = saveresultsContentVersions[i];
            
            ContentVersion a = mapOfContentVersions.values()[i];
            
            System.debug(sr);

            addToDatabaseErrors(sr, a);
        }

        for(Integer i=0; i<saveresultsContentDocumentLinks.size(); i++) 
        {
            Database.SaveResult sr = saveresultsContentDocumentLinks[i];
            
            ContentDocumentLink a = mapOfAttachmentLinks[i];
            
            System.debug(sr);

            addToDatabaseErrors(sr, a);
        }

        for(Integer i=0; i<saveresultsContentNotes.size(); i++) 
        {
            Database.SaveResult sr = saveresultsContentNotes[i];
            
            ContentNote a = mapOfContentNotes.values()[i];
            
            System.debug(sr);

            addToDatabaseErrors(sr, a);
        }

        for(Integer i=0; i<saveresultsContentDocumentLinks2.size(); i++) 
        {
            Database.SaveResult sr = saveresultsContentDocumentLinks2[i];
            
            ContentDocumentLink a = listOfAttachmentLinks[i];
            
            System.debug(sr);

            addToDatabaseErrors(sr, a);
        }
    }

    /**
    * addToDatabaseErrors
    *
    * Centralized function to handle updating the global list
    * of database DML errors
    * 
    * overloaded to handle ContentVersion
    */
    public void addToDatabaseErrors(Database.SaveResult sr, ContentVersion a)
    {
        if (!sr.isSuccess()) {
            listOfErrorsHTML += sr.getId() + ': ';
            listOfErrors += sr.getId() + ': ';
            for(Database.Error de : sr.getErrors())
            {
                listOfErrorsHTML += a.Title + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '<br/>';
                listOfErrors += a.Title + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ';
            } 
        }
    }

    /**
    * addToDatabaseErrors
    *
    * Centralized function to handle updating the global list
    * of database DML errors
    * 
    * overloaded to handle ContentNote
    */
    public void addToDatabaseErrors(Database.SaveResult sr, ContentNote a)
    {
        if (!sr.isSuccess()) {
            listOfErrorsHTML += sr.getId() + ': ';
            listOfErrors += sr.getId() + ': ';
            for(Database.Error de : sr.getErrors())
            {
                listOfErrorsHTML += a.Title + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '<br/>';
                listOfErrors += a.Title + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ';
            } 
        }
    }

    /**
    * addToDatabaseErrors
    *
    * Centralized function to handle updating the global list
    * of database DML errors
    * 
    * overloaded to handle ContentDocumentLink
    */
    public void addToDatabaseErrors(Database.SaveResult sr, ContentDocumentLink a)
    {
        if (!sr.isSuccess()) {
            listOfErrorsHTML += sr.getId() + ': ';
            listOfErrors += sr.getId() + ': ';
            for(Database.Error de : sr.getErrors())
            {
                listOfErrorsHTML += a.ContentDocumentId  + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '<br/>';
                listOfErrors += a.ContentDocumentId  + ' Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ';
            } 
        }
    }

    /**
    * getConversionContents
    *
    * Function which takes the attachments and creates Content Versions
    *
    * The ContentDocument link is null initially but Salesforce will create that on 
    * their own for us.
    *
    * ContentVersion.ContentLocation: 
    * S — Document is located within Salesforce. Label is Salesforce.
    * E — Document is located outside of Salesforce. Label is External.
    * L — Document is located on a social network and accessed via Social Customer Service. Label is Social Customer Service.
    *
    * @param attachmentList - List of fileObject found in this class
    * @return List<ContentVersion> - List of ContentVersions
    */
    public Map<String, ContentVersion> getContentVersions(List<fileObject> attachmentList)
    {
        Map<String, ContentVersion> mapOfContentVersionToFileObject = new Map<String, ContentVersion>();

        for(fileObject tempAttachment : attachmentList)
        {
            String tempBody = tempAttachment.Body;

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.ContentDocumentId = null;
            cv.VersionData = EncodingUtil.base64Decode(tempBody);
            cv.Title = tempAttachment.Title;
            cv.PathOnClient = tempAttachment.Title;
            // if(tempAttachment.OwnerId != null)
            // {
            //    cv.CreatedById = tempAttachment.OwnerId;
            // }
        
            mapOfContentVersionToFileObject.put(tempAttachment.CustomId, cv);
        }

        return mapOfContentVersionToFileObject;
    }

    /**
    * getContentVersionsRefreshed
    *
    * Function which takes the attachments and gets the Content Document Ids updated
    *
    * @param mapOfContentVersions      - Map containing all content versions with their classic attachment id as key
    * @return Map<Id, ContentVersion>  - Map of Content Versions pointing to their parent Content Documents
    */
    public Map<String, ContentVersion> getContentVersionsRefreshed(Map<String, ContentVersion> mapOfContentVersions)
    {
        // 1. Query the database to get all the Content Document Ids
        Map<Id, ContentVersion> versionList = new Map<Id, ContentVersion>([SELECT Id, 
                                                                                ContentDocumentId,
                                                                           		Title,
                                                                           		OwnerId,
                                                                           		ContentLocation,
                                                                           		PathOnClient
                                                                            FROM ContentVersion 
                                                                            WHERE Id IN :mapOfContentVersions.values()]);

        System.debug(versionList);

        for(String tempAttachmentId : mapOfContentVersions.keySet())
        {
            for(Id tempContentVersionRefresh : versionList.keySet())
            {
                if(tempContentVersionRefresh == mapOfContentVersions.get(tempAttachmentId).Id)
                {
                    mapOfContentVersions.put(tempAttachmentId, versionList.get(tempContentVersionRefresh));
                }
            }            
        }

        return mapOfContentVersions;
    }

    /**
    * getContentDocumentLinks
    *
    * Function which takes the attachments and creates Content Documents
    *
    * ContentDocumentLink.ShareType:
    * V - Viewer permission. The user can explicitly view but not edit the shared file.
    * C - Collaborator permission. The user can explicitly view and edit the shared file.
    * I - Inferred permission. The user’s permission is determined by the related record. For shares with a library, this is defined by the permissions the user has in that library.
    *
    * ContentDocumentLink.Visibility:
    * AllUsers      — The file is available to all users who have permission to see the file.
    * InternalUsers — The file is available only to internal users who have permission to see the file.
    * SharedUsers   — The file is available to all users who can see the feed to which the file is posted. 
    *                  SharedUsers is used only for files shared with users, and is available only when an 
    *                  org has private org-wide sharing on by default. The SharedUsers value is available in 
    *                  API version 32.0 and later.
    * 
    * @param attachmentList                 - List of Attachments found in this batch
    * @param mapOfContentVersions           - map containing all content versions with their classic attachment id as key
    * @return Map<Id, ContentDocumentLink>  - Map of ContentDocumentLink by Attachment Id to keep them married
    */
    public List<ContentDocumentLink> getContentDocumentLinks(Map<String, ContentVersion> mapOfContentVersions, Map<String, fileObject> listOfFileObjects)
    {
        List<ContentDocumentLink> mapOfContentDocumentLinks = new List<ContentDocumentLink>();

        for(String tempAttachmentId : mapOfContentVersions.keySet())
        {
            ContentDocumentLink tempLink = new ContentDocumentLink();
            tempLink.ContentDocumentId = mapOfContentVersions.get(tempAttachmentId).ContentDocumentId;
            tempLink.LinkedEntityId = listOfFileObjects.get(tempAttachmentId).ParentId;
            tempLink.ShareType = 'V';
            tempLink.Visibility = 'AllUsers';

            mapOfContentDocumentLinks.add(tempLink);
        }

        return mapOfContentDocumentLinks;
    }

    /**
    * getContentNotes
    *
    * Function which takes the attachments and creates Content Notes
    *
    * The ContentDocument link is null initially but Salesforce will create that on 
    * their own for us.
    *
    * @param attachmentList - List of Attachments found in this batch
    * @return Map<Id, ContentVersion> - Map of ContentVersion by Attachment Id to keep them married
    */
    public Map<String, ContentNote> getContentNotes(List<fileObject> attachmentList)
    {
       Map<String, ContentNote> mapOfContents = new Map<String, ContentNote>();

        for(fileObject tempAttachment : attachmentList)
        {
            ContentNote cv = new ContentNote();
            cv.Title = tempAttachment.Title;
            // AMM1
            // cv.Content = Blob.valueOf(tempAttachment.Body.escapeHTML4());
            if(tempAttachment.Body != null)
            {
                cv.Content = Blob.valueOf(tempAttachment.Body.escapeHTML4());
            }
            // AMM1

            
            // if(tempAttachment.OwnerId != null)
            // {
            //     cv.CreatedById = tempAttachment.OwnerId;
            // }
        
            mapOfContents.put(tempAttachment.CustomId, cv);
        }

        return mapOfContents;
    }

    /**
    * getContentDocumentLinks
    *
    * Function which takes the notes and creates Content Documents
    *
    * ContentDocumentLink.ShareType:
    * V - Viewer permission. The user can explicitly view but not edit the shared file.
    * C - Collaborator permission. The user can explicitly view and edit the shared file.
    * I - Inferred permission. The user’s permission is determined by the related record. For shares with a library, this is defined by the permissions the user has in that library.
    *
    * ContentDocumentLink.Visibility:
    * AllUsers      — The file is available to all users who have permission to see the file.
    * InternalUsers — The file is available only to internal users who have permission to see the file.
    * SharedUsers   — The file is available to all users who can see the feed to which the file is posted. 
    *                  SharedUsers is used only for files shared with users, and is available only when an 
    *                  org has private org-wide sharing on by default. The SharedUsers value is available in 
    *                  API version 32.0 and later.
    * 
    * @param attachmentList                 - Map of notes by fileObject Id
    * @param mapOfContentNotes              - map containing all content notes with their classic attachment id as key
    * @return List<ContentDocumentLink>     - List of ContentDocumentLink 
    */
    public List<ContentDocumentLink> getContentDocumentLinks(Map<String, fileObject> attachmentList, Map<String, ContentNote> mapOfContentNotes)
    {
       List<ContentDocumentLink> listOfContentDocumentLinks = new List<ContentDocumentLink>();

        for(String tempAttachmentId : mapOfContentNotes.keySet())
        {
            ContentDocumentLink tempLink = new ContentDocumentLink();
            tempLink.ContentDocumentId = mapOfContentNotes.get(tempAttachmentId).Id;
            tempLink.LinkedEntityId = attachmentList.get(tempAttachmentId).ParentId;
            tempLink.ShareType = 'V';
            tempLink.Visibility = 'AllUsers';

            System.debug(tempLink);

            listOfContentDocumentLinks.add(tempLink);
        }

        return listOfContentDocumentLinks;
    }

    public class fileObject 
    {
        /** */
        public String CustomId {get;set;}

        /** String title of the note or file */
        public String Title {get;set;}
        
        /** String base64 representation of file or simple text of the note */
        public String Body {get;set;}

        /** Id of the record parenting this attachment */
        public Id ParentId {get;set;}

        /** Boolean to determine if the attachment is a note (true) or attachment (false) */
        public Boolean isNote {get;set;}

        /** ContentVersion Id */
        public Id CvId {get;set;}

        /** ContentNote Id */
        public Id CnId {get;set;}

        /** ContentDocumentLink Id */
        public Id LinkId {get;set;}

        /** Owner Id */
        public Id OwnerId {get;set;}

        public fileObject(String title, String body, Id parentId, Boolean isNote, Id ownerId)
        {
            this.Title = title;
            this.Body = body;
            this.ParentId = parentId;
            this.isNote = isNote;
            this.OwnerId = ownerId;
            this.CustomId = generateRandomString(30);
        }

        public String generateRandomString(Integer len) 
        {
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
}