public interface SBR_3_0_drfDMLOpsInterface {
      Database.SaveResult updateRecord(SObject fields, String actionType);
      Object submitRecord(Id recordId);
}