public with sharing class SBR_3_0_CustomAccountListViewController {
  @AuraEnabled(Cacheable=true)
  public static Object getFilteredAccounts(
    String searchKey,
    String fields,
    String objectName,
    String whereClause,
    String orderClause,
    String limitClause,
    Boolean fetchCount
  ) {
    return getFilteredAccountsWithoutCacheable(searchKey, fields, objectName, whereClause, orderClause, limitClause, fetchCount);
  }

  //START: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125, FRONT-10250
  @AuraEnabled
  public static Object getFilteredAccountsWithoutCacheable(
    String searchKey,
    String fields,
    String objectName,
    String whereClause,
    String orderClause,
    String limitClause,
    Boolean fetchCount
  ) {
      try {
        SBR_3_0_CustomAccountListViewResponse response = new SBR_3_0_CustomAccountListViewResponse();
        SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder builder = new SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder();
        builder.setSearchKey(searchKey);
        builder.setFieldsJoined(fields);
        builder.setObjectName(objectName);
        builder.setWhereClause(whereClause);
        builder.setOrderClause(orderClause);
        //builder.setSecurityClause();
        builder.setLimitClause(limitClause);
        SBR_3_0_CustomAccountListViewService service = new SBR_3_0_CustomAccountListViewService();
        response.data = service.getAccounts(builder);
        if (fetchCount) {
          response.count = service.getCount(builder);
        }
        return response;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
  }
  //END: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125

  public class SBR_3_0_CustomAccountListViewResponse {
    @AuraEnabled
    public Object data;
    @AuraEnabled
    public Integer count;
  }
}