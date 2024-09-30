public inherited sharing class SBR_3_0_CustomAccountListViewService {
  public Object getAccounts(
    SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder builder
  ) {
    SBR_3_0_CustomAccountListViewSelector accountSelector = new SBR_3_0_CustomAccountListViewSelector(
      builder
    );
    return accountSelector.getAccounts();
  }

  public Integer getCount(SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder builder) {
    SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder countBuilder = new SBR_3_0_CustomAccountListViewSelector.SBR_3_0_CustomAccountListViewQueryBuilder();
    countBuilder.setCountClause();
    countBuilder.setObjectName(builder.getObjectName());
    countBuilder.setWhereClause(builder.getWhereClause());
    SBR_3_0_CustomAccountListViewSelector accountCountSelector = new SBR_3_0_CustomAccountListViewSelector(
      countBuilder
    );
    return accountCountSelector.getCount();
  }
}