/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTechnicalAttributesBatch
----------------------------------------------------------------------------------------------------------------------
* @description Daily batch job to update technical attributes from SM_PS_Days_Since_Date_Commissioned__c formula
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME        DATE            MOD LOG
    1.0       Evan Kuminski         2024-Apr-17      Initial version
**********************************************************************************************************************/

public with sharing class SBR_3_0_UpdateTechnicalAttributesBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    private static final String REQUEST_BODY_START = '{"source":"External System","objectName":"Asset","assetIdentifierFieldAPIName":"Name","attributeList":[';
    private static final String REQUEST_BODY_END = ']}';
    private static final Integer DEFAULT_TECHNICAL_ATTRIBUTE_UPDATES_PER_CALLOUT = 667;
    private static final Integer MAX_BATCH_JOB_SIZE = 2000;
    private final Integer batchJobSize;
    private final Integer technicalAttributeUpdatesPerCallout;

    /**
     * @description Default constructor - Uses max batch job size when used by System.schedule()
     */
    public SBR_3_0_UpdateTechnicalAttributesBatch() {
        this(MAX_BATCH_JOB_SIZE, DEFAULT_TECHNICAL_ATTRIBUTE_UPDATES_PER_CALLOUT);
    }

    /**
     * @description Alternate constructor - Sets batch job size to passed value when used by System.schedule()
     * @param batchJobSize Sets batch job size when SBR_3_0_UpdateTechnicalAttributesBatch instance is used by System.schedule()
     * @param technicalAttributeUpdatesPerCallout Maximum number of Assets to update Technical Attributes for per callout
     */
    public SBR_3_0_UpdateTechnicalAttributesBatch(Integer batchJobSize, Integer technicalAttributeUpdatesPerCallout) {
        this.batchJobSize = Math.min(batchJobSize, MAX_BATCH_JOB_SIZE);
        this.technicalAttributeUpdatesPerCallout = technicalAttributeUpdatesPerCallout;
        if((Decimal)this.batchJobSize/this.technicalAttributeUpdatesPerCallout > Limits.getLimitCallouts()) {
            throw new IllegalArgumentException(
                    String.format(
                            'batchJobSize divided by technicalAttributeUpdatesPerCallout must be less than or equal to {0} but is currently {1}',
                            new List<Object>{
                                    Limits.getLimitCallouts(),
                                    (Decimal)this.batchJobSize/this.technicalAttributeUpdatesPerCallout
                            }
                    )
            );
        }
    }

    /**
     * @description Gets Assets to process in batch job
     * @param context Standard Database.BatchableContext input for batch job methods
     * @return Asset records to process
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, SM_PS_Days_Since_Date_Commissioned__c FROM Asset WHERE SM_PS_Date_Commissioned__c <> NULL');
    }


    /**
     * @description Schedulable execute() method to start batch job on a schedule
     * @param context Standard SchedulableContext input for schedulable execute method
     */
    public void execute(SchedulableContext context) {
        if(this.batchJobSize > MAX_BATCH_JOB_SIZE) {
            Database.executeBatch(this, MAX_BATCH_JOB_SIZE);
        } else {
            Database.executeBatch(this, this.batchJobSize);
        }
    }

    /**
     * @description Update technical attributes from SM_PS_Days_Since_Date_Commissioned__c formula
     * @param context Standard Database.BatchableContext input for batch job methods
     * @param records Asset records to process
     */
    public void execute(Database.BatchableContext context, List<SObject> records) {
        // The request payload is not generated with a JSONGenerator to minimize CPU time as much as possible.
        List<Asset> assets = (List<Asset>)records;
        for(Integer i = 0; i < assets.size(); i += this.technicalAttributeUpdatesPerCallout) {
            makeCallout(generateSingleCalloutPayload(assets, i));
        }
    }

    private String generateSingleCalloutPayload(List<Asset> assets, Integer startingIndex) {
        // JSON payload is not generated using JSONGenerator to minimize execution time.
        List<String> singleAssetPayloads = new List<String>();
        for (Integer i = startingIndex; i < startingIndex + this.technicalAttributeUpdatesPerCallout && i < assets.size(); i++) {
            singleAssetPayloads.add(
                    '{"value":"' + String.valueOf(assets[i].SM_PS_Days_Since_Date_Commissioned__c) + '","attributeKey":"Calendar_Days_Number","dataType":"Number","recordId":"' + assets[i].Id +'"}'
            );
        }
        // Building a List of Strings and combining them all at once with String.join() is slightly faster than
        // appending all of the data to a single request body String as single Asset payloads are generated.
        return REQUEST_BODY_START + String.join(singleAssetPayloads, ',') + REQUEST_BODY_END;
    }

    /**
     * @description Standard finish() method for batch jobs. Needs to exist, but doesn't do anything
     * @param context Standard Database.BatchableContext input for batch job methods
     */
    public void finish(Database.BatchableContext context) {}

    @TestVisible
    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    private static void makeCallout(String requestBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Url.getOrgDomainUrl().toExternalForm()+'/services/apexrest/SVMXA360/technicalAttribute/v1/saveTechnicalAttributes/');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(requestBody);

        try {
            HttpResponse res = new Http().send(req);
            if(res.getStatusCode() != 200) {
                SBR_3_0_Log.logAPIDetails(req.getBody(), res.getBody(), 'Unexpected status code when updating Technical Attributes (' + res.getStatusCode() + ')');
                SBR_3_0_Log.saveLog();
            }
        }
        catch(Exception ex) {
            SBR_3_0_Log.logException(ex);
            SBR_3_0_Log.saveLog();
        }
    }
}