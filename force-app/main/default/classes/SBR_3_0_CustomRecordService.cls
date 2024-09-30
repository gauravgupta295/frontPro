public with sharing class SBR_3_0_CustomRecordService {
    
        public Object getRecords(
          SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder
        ) {
          SBR_3_0_CustomRecordSelector recordSelector = new SBR_3_0_CustomRecordSelector(
            builder
          );
          return recordSelector.getRecords();
        }
      
        public Integer getCount(SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder) {
          SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder countBuilder = new SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder();
          countBuilder.setCountClause();
          countBuilder.setObjectName(builder.getObjectName());
          countBuilder.setWhereClause(builder.getWhereClause());
          SBR_3_0_CustomRecordSelector accountCountSelector = new SBR_3_0_CustomRecordSelector(
            countBuilder
          );
          return accountCountSelector.getCount();
        }
      }