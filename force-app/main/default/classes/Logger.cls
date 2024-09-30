public without sharing class Logger {
    
    private static final String ORG_NAMESPACE = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
    private static Map<String,String> keyToPayloadmap=new Map<String,String>();
    private static Map<String,String> keyToRequestPayloadmap=new Map<String,String>();
    @TestVisible private static List<Attachment> lstAttachmentObject = new List<Attachment>();
    private static final String CLASSNAME = Logger.class.getName();
    private static final String NEW_LINE = '\n';
    private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');
    private static final List<String> IGNORED_CLASSES = getIgnoredClasses();
    public enum LogType {
        DEBUG,
        ERROR,
        API_LOG,
        FLOW,
        FUNCTIONAL_ERROR
    }
    private static final Map<Schema.SObjectType, String> sObjectTypeToNameMap = new Map<Schema.SObjectType, String>();
    private static Map<Id,SObject> recordIdToRecord = new Map<Id,SObject>();

    private static List<String> getIgnoredClasses() {
        return new List<String>{
            SBR_3_0_Log.class.getName(),
            Logger.class.getName()
        };
    }
    
    // Note: Required to allow testing
    @TestVisible
    private static LoggerSettings__c userSettings;
    private static final List<LogEntryEvent__e> LOG_ENTRIES_BUFFER = new List<LogEntryEvent__e>();
    // PUBLIC
    
    /**
    * Method to debug the passed message along with async job Id
    */
    public static LogEntryEvent__e debug(String message, Id recordId) {
        return debug(message, null,null,recordId);
    }
    

    public static LogEntryEvent__e debug(String message,String stackTrace,Id asyncJobId,String recordId) {
        return emit(message, stackTrace, asyncJobId, LogType.DEBUG,recordId,null,null,null,null,null);
    }
    
    /**
    * Method to add Log record with exception error message & stack trace with list of records
    */
    public static LogEntryEvent__e error(Exception ex,Id recordId) {
        return error(ex.getMessage(), ex.getStackTraceString(), recordId);
    }
    
    public static LogEntryEvent__e error(String message, String stackTrace,Id recordId) {
        return emit(message, stackTrace,null, LogType.ERROR,recordId,null,null,null,null,null);
    }
    
    public static LogEntryEvent__e calloutLog(String message,String pathName,String recordId,String className,
                                            String requestJson,String responseJSON,String statuscode){
        
        return emit(message,pathname,null,LogType.API_LOG,recordId,className,requestJson,responseJSON,statuscode,pathName);
    }
    /**
    * Method to publish Log Event record based on publishEvent parameters
    */
    private static LogEntryEvent__e emit(
        String message,
        String stackTrace,
        Id asyncJobId,
        LogType logType,
        String recordId,
        String className,
        String requestJson,
        String responseJson,
        string statusCode,
        String pathName
    ) {
        LogEntryEvent__e currentEvent = new LogEntryEvent__e();
        stackTrace = String.isNotBlank(stackTrace) ? stackTrace : getStackTrace();
        currentEvent = new LogEntryEvent__e();
        currentEvent.User__c = UserInfo.getUserId();
        currentEvent.Type__c = logType.name();
        currentEvent.Message__c = message;
        currentEvent.StackTrace__c = stackTrace;
        currentEvent.AsycJobId__c = asyncJobId;
        currentEvent.RecordID__c = recordId;
        currentEvent.Class__c = className;
        currentEvent.RequestJSON__c = requestJson;
        currentEvent.ResponseJSON__c = responseJson;
        currentEvent.StatusCode__c = statusCode;
        currentEvent.Path__c = pathName;
        populateLocation(currentEvent,stackTrace);

        LOG_ENTRIES_BUFFER.add(currentEvent);

        return currentEvent;
    }
    
    
    /**
    * Method to populate platform event object with Class and Method name
    */
    private static void populateLocation(LogEntryEvent__e logEvent,String stackTrace) {
        List<String> stacktraces;
        if(stackTrace!=null){
            stacktraces = stackTrace.split(NEW_LINE);
        }else{
            stackTrace = new DmlException().getStackTraceString();
            stacktraces = stackTrace.split(NEW_LINE);
        }
        List<String> callingClassStackTrace = new List<String>();
        Boolean isTopLevelClassFound = false;
        
        for(String line : stacktraces) {
            Matcher matcher = STACK_LINE.matcher(line);
            
            if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.')) {
                
                Boolean hasNamespace = String.isNotBlank(matcher.group(3));
                
                if(hasNamespace) {
                    logEvent.Class__c = (matcher.group(1).equals(ORG_NAMESPACE)) ? matcher.group(2) : matcher.group(1) + '.' + matcher.group(2);
                    logEvent.Method__c = prettyMethod(matcher.group(3));
                }
                else {
                    logEvent.Class__c = matcher.group(1);
                    logEvent.Method__c = prettyMethod(matcher.group(2));
                }
                
                logEvent.LineNumber__c = Integer.valueOf(matcher.group(4));
            }
        }
        
    }
    
    /**
    * Method to ignore the null 
    */
    private static String prettyMethod(String method) {
        String result = (method == null) ? 'anonymous' : method;
        return (result.contains('init')) ? 'ctor' : result;
    }
    /*   
    * This method is going to be called from Logutility Class to insert attachment
    * @param     SObject                Instance of sObject 
    @param     logPayloadFile         JSON for which attachment has to be created
    * @return    Void                   Method doesn't return anything            
    */
    public static void createAttachmentFromPayload(Exception_Log__c objectInstance,String logPayloadFile){
        if (objectInstance.Id != null){
            if(String.isNotBlank(logPayloadFile)){
                Attachment attachmentInstance = new Attachment();
                attachmentInstance.ParentId = objectInstance.Id;
                attachmentInstance.Body = Blob.valueOf(logPayloadFile);
                attachmentInstance.Description = 'Attachment created for ' + objectInstance.get('Class_Name__c') ;
                attachmentInstance.Name = objectInstance.get('Class_Name__c') + '-integration details.txt';
                attachmentInstance.ContentType = 'text/plain';
                lstAttachmentObject.add(attachmentInstance);
            }
        }
    }

    /*   
    * <p> This method commits log details to Log object
    * @param     List<lstLogs>                  List of Logs records which needs to be committed
    * @return    void                           Method doesn't return any value.               
    */
    public static void commitLogsInDatabase(List<SObject> lstLogs){
        // Set to store Sucess and failure Ids
        Set<Id> successIDs = new Set<Id>();
        Set<Id> failureIDs = new Set<Id>();

       
        Id recordId;
        Schema.SObjectType sobjectType;
        // 1. Figure out which SObjects & record IDs to query
        Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords = new Map<Schema.SObjectType, List<Id>>();

        // If there are logs to be inserted then insert to log object and capture the result set
        if (!lstLogs.isEmpty()){
            for(Exception_Log__c log: (List<Exception_Log__c >)lstLogs){
                
                getAllSobjecTypes(log,sobjectTypeToRecords);

                if(log.RequestJSON__c!=null && log.RequestJSON__c.length() > 2000){
                    //store as attachment
                    if(log.RecordID__c!=null){
                        keyToRequestPayloadmap.put(String.valueOf(log.PlatformEventRaisedTime__c) + log.RecordID__c +log.StatusCode__c +log.Class_Name__c,log.RequestJSON__c);
                    }
                    else{
                        keyToRequestPayloadmap.put(String.valueOf(log.PlatformEventRaisedTime__c) + log.ownerId +log.StatusCode__c +log.Class_Name__c,log.RequestJSON__c);
                    }
                    log.RequestJSON__c='';
                }
                if(log.ResponseJSON__c!=null && log.ResponseJSON__c.length() > 1000){
                    if(log.RecordID__c!=null){
                        keyToPayloadmap.put(String.valueOf(log.PlatformEventRaisedTime__c) + log.RecordID__c + log.StatusCode__c +log.Class_Name__c,log.ResponseJSON__c);
                    }else{
                        keyToPayloadmap.put(String.valueOf(log.PlatformEventRaisedTime__c) + log.ownerId +log.StatusCode__c +log.Class_Name__c,log.ResponseJSON__c);
                    }
                    log.ResponseJSON__c='';
                }
            }
            
            getRecords(sobjectTypeToRecords);
            
            if (!lstLogs.isEmpty()){
                for(Exception_Log__c log: (List<Exception_Log__c>)lstLogs){
                    // Skip the log entry if there's no related record ID
                    if (log.RecordID__c == null) {
                        continue;
                    }
                    sobjectType = getSObjectType(log.RecordID__c);
                    if(sobjectType != null ){
                        String sobjectDisplayFieldName = getDisplayFieldApiName(sobjectType);
                        log.SObjectType__c = String.valueOf(sobjectType);
                        log.ObjectClassification__c = log.SObjectType__c.endsWithIgnoreCase('__c') ? 'Custom Object' : 'Standard Object';
                        if (recordIdToRecord.containsKey(log.RecordID__c)) {
                            log.RelatedRecordName__c = (String) recordIdToRecord.get(log.RecordID__c).get(sobjectDisplayFieldName);
                        }
                    }
                }
            }

            Database.SaveResult[] lstSaveResults = Database.insert(lstLogs, false);
            String strErrorDetails;
            for (Integer intSaveResultCount = 0; intSaveResultCount < lstSaveResults.size(); intSaveResultCount++){
                Database.SaveResult objSaveResult = lstSaveResults[intSaveResultCount];
                if (objSaveResult.isSuccess()) {
                    successIDs.add(objSaveResult.getId());
                }
                else {
                    for (Database.Error objInsertError : objSaveResult.getErrors()){
                        strErrorDetails += objInsertError.getMessage() + '\n >';
                    }
                    //Add an enter at the end of each LOG record end.
                    strErrorDetails += '\n----------------------------------\n';
                }
            }
            if (String.isNotBlank(strErrorDetails)) {                   
                error(strErrorDetails,null,null);
            }
            if(successIDs!=null && !successIDs.isEmpty()){
                List<Exception_Log__c> insertedRecords=[select id,PlatformEventRaisedTime__c,Ownerid,RecordID__c,Type__c,
                Path__c,StatusCode__c,Class_Name__c,Stack_Trace__c,Exception_Message__c,RequestJSON__c,ResponseJSON__c from Exception_Log__c where id In:successIDs WITH SECURITY_ENFORCED];
                
                for(Exception_Log__c log:insertedRecords){
                    String responsePayload;
                    String reqPayload;
                    String key = log.RecordID__c != null ? String.valueOf(log.PlatformEventRaisedTime__c) + log.RecordID__c : String.valueOf(log.PlatformEventRaisedTime__c) + log.Ownerid;
                    if(keyToPayloadmap.containsKey(key + log.StatusCode__c + log.Class_Name__c)){
                        responsePayload = keyToPayloadmap.get(key + log.StatusCode__c + log.Class_Name__c);
                    }
                    if(responsePayload!=null && responsePayload.length() > 1000){
                        createAttachmentFromPayload(log,responsePayload);
                    }
                    if(keyToRequestPayloadmap.containsKey(key + log.StatusCode__c + log.Class_Name__c)){
                        reqPayload = keyToRequestPayloadmap.get(key + log.StatusCode__c + log.Class_Name__c);
                    }
                    if(reqPayload!=null){
                        createAttachmentFromPayload(log,reqPayload);
                    }
                }
                if(lstAttachmentObject!=null && !lstAttachmentObject.isEmpty()){
                    Database.insert(lstAttachmentObject,false);
                }
            }
        }
    }
    private static Schema.SObjectType getSObjectType(Id recordId) {
        Schema.SObjectType sobjectType;
        try {
            sobjectType = recordId?.getSObjectType();
        } catch (System.SObjectException sobjectException) {
            // Some SObject Types are considered template objects, such as CaseComment, AccountHistory,
            // ContactHistory, etc, so calling Id.getSObjectType() does not work for some types of record IDs
            if (sobjectException.getMessage().contains('Cannot locate Apex Type') == false) {
                throw sobjectException;
            }
        }
        return sobjectType;
    }
    private static String getDisplayFieldApiName(Schema.SObjectType sobjectType) {
        if (sObjectTypeToNameMap.containsKey(sobjectType) == true) {
            return sObjectTypeToNameMap.get(sobjectType);
        }

        // Use username instead of name for user
        if (sobjectType == Schema.User.SObjectType) {
            String userFieldName = Schema.User.Username.getDescribe().getName();
            sObjectTypeToNameMap.put(Schema.User.SObjectType, userFieldName);
            return userFieldName;
        }

        // There are several commonly used names for the display field name - typically, Name
        List<String> otherNames = new List<String>{
            'Name',
            'DeveloperName',
            'ApiName',
            'Title',
            'Subject',
            'AssetRelationshipNumber',
            'CaseNumber',
            'ContractNumber',
            'Domain',
            'FriendlyName',
            'FunctionName',
            'Label',
            'LocalPart',
            'OrderItemNumber',
            'OrderNumber',
            'SolutionName',
            'TestSuiteName'
        };

        String displayFieldApiName;
        List<String> fallbackFieldApiNames = new List<String>();
        for (String fieldName : otherNames) {
            Schema.SObjectField field = sobjectType.getDescribe().fields.getMap().get(fieldName);
            if (field == null) {
                continue;
            }
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isNameField() == true) {
                displayFieldApiName = fieldDescribe.getName();
                break;
            } else {
                fallbackFieldApiNames.add(fieldDescribe.getName());
            }
        }
        if (String.isBlank(displayFieldApiName) == true && fallbackFieldApiNames.size() == 1) {
            displayFieldApiName = fallbackFieldApiNames.get(0);
        }

        sObjectTypeToNameMap.put(sobjectType, displayFieldApiName);
        return displayFieldApiName;
    }
    private static void getAllSobjecTypes(Exception_Log__c log,Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords){
        String recordId;
        Schema.SObjectType sobjectType;
        // get Sobject type for each record
        if(log.RecordID__c!=null){
            recordId = (Id) log.RecordID__c;
            sobjectType = getSObjectType(recordId);
        }
        List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
        if (sobjectTypeRecordIds == null) {
            sobjectTypeRecordIds = new List<Id>();
        }
        sobjectTypeRecordIds.add(recordId);
        if(sobjectType!=null){
            sobjectTypeToRecords.put(sobjectType,sobjectTypeRecordIds);
        }
        
    }
    
    private static void getRecords(Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords){
        String query;
        // 2. Run the queries and store the results in the map
        for (Schema.SObjectType sobjectType : sobjectTypeToRecords.keySet()) {
            // Stop if we've used up all the queries
            if (System.Limits.getQueries() == System.Limits.getLimitQueries()) {
                break;
            }

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            String sobjectDisplayFieldName = getDisplayFieldApiName(sobjectType);

            if (sobjectDisplayFieldName == null) {
                continue;
            }
            
            query = String.format('SELECT {0} FROM {1} WHERE Id IN :sobjectTypeRecordIds', new List<Object>{ sobjectDisplayFieldName,sobjectType });
            
            List<SObject> results= Database.query(String.escapeSingleQuotes(query));
            recordIdToRecord.putAll(results);
            
        }
    }
        
     /**
     * @description Returns the current user's instance of `LoggerSettings__c`
     * @return LoggerSettings__c - The current user's instance of the custom settings
     */
    public static LoggerSettings__c getUserSettings() {
        // Only load the current user's settings once - this allows the instance to be modified in memory (as well as upserted if any changes should be persisted)
        if (userSettings == null) {
            User currentUser = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
            userSettings = getUserSettings(currentUser);
        }
        return userSettings;
    }
    
     /**
     * @description Returns the specified user's instance of `LoggerSettings__c`
     * @param loggingUser The user record - at a minimum, this record should have the user Id and Profile fields populated
     * @return LoggerSettings__c - The specified user's instance of the custom settings
     */
    public static LoggerSettings__c getUserSettings(User loggingUser) {
        // Typically, using LoggerSettings__c.getInstance() would be easier
        // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
        // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)

        LoggerSettings__c loggingUserSettings;
        if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
            // Check for User-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.Id);
        } else if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
            // Next, check for Profile-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
        } else if (LoggerSettings__c.getOrgDefaults().Id != null) {
            // Next, use the org defaults (if configured)
            loggingUserSettings = LoggerSettings__c.getOrgDefaults();
        }else{
            loggingUserSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        }

        return loggingUserSettings;
    }
    
    public static Integer getBufferSize() {
        return LOG_ENTRIES_BUFFER.size();
    }
    
    public static void flushBuffer() {
        LOG_ENTRIES_BUFFER.clear();
    }
    
    public static void saveLog() {
        LoggerSettings__c userSettings = getUserSettings();

        if(!userSettings.IsEnabled__c){
            return;
        }

        if (LOG_ENTRIES_BUFFER.isEmpty()) {
            return;
        }

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (LogEntryEvent__e logEntryEvent : LOG_ENTRIES_BUFFER) {
                logEntryEvents.add(logEntryEvent);
        }

        List<Database.SaveResult> saveResults = EventBus.publish(logEntryEvents);

        flushBuffer();
    }

    public static String getStackTrace(){
        DmlException stackTraceException = new DmlException();
        String stackTraceString = stackTraceException.getStackTraceString();

        List<String> stackTraceLines = new List<String>();
        for (String currentStackTraceLine : stackTraceString.split('\n')) {
        // Don't include the logging system's classes in the stack trace
            Boolean ignoreLine = false;
            for (String ignoredClass : IGNORED_CLASSES) {
                if (currentStackTraceLine.contains('.' + ignoredClass + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }

            if (ignoreLine) {
                continue;
            }
            stackTraceLines.add(currentStackTraceLine);
        }

        stackTraceString = String.join(stackTraceLines, '\n');
        

        return stackTraceString;
    }
        
}