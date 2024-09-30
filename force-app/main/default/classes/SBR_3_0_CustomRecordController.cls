public with sharing class SBR_3_0_CustomRecordController {
    @AuraEnabled(Cacheable=true)
  public static Object getFilteredRecords(
    String fields,
    String objectName,
    String whereClause,
    String orderClause,
    String limitClause,
    Boolean fetchCount
  ) {
      
    return getFilteredRecordsWithoutCacheable(fields, objectName, whereClause, orderClause, limitClause, fetchCount);
  }

  //START: FRONT-9256
  @AuraEnabled
  public static Object getFilteredRecordsWithoutCacheable(
    String fields,
    String objectName,
    String whereClause,
    String orderClause,
    String limitClause,
    Boolean fetchCount
  ) {
      try {
        SBR_3_0_CustomRecordResponse response = new SBR_3_0_CustomRecordResponse();
        SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder = new SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder();
        builder.setFieldsJoined(fields);
        builder.setObjectName(objectName);
        builder.setWhereClause(whereClause);
        builder.setOrderClause(orderClause);
        builder.setSecurityClause();
        builder.setLimitClause(limitClause);
        SBR_3_0_CustomRecordService service = new SBR_3_0_CustomRecordService();
        response.data = service.getRecords(builder);
        if (fetchCount) {
          response.count = service.getCount(builder);
        }
         
        return response;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
  }
  //END: FRONT-9256

  public class SBR_3_0_CustomRecordResponse {
    @AuraEnabled
    public Object data;
    @AuraEnabled
    public Integer count;
  }
    
}