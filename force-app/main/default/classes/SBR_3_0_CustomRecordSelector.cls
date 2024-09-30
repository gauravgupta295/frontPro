public virtual  class SBR_3_0_CustomRecordSelector {
  private static  final String SOQL_TEMPLATE = 'SELECT {0} FROM {1} {2} {3} {4} {5} {6}';
  public Object records { public get; set; }
  protected SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder;
  protected Map<String, Object> inputs;
  protected String query;
  public SBR_3_0_CustomRecordSelector(
    SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder
  ) {
    this.builder = builder;
  }
  public SBR_3_0_CustomRecordSelector(
    SBR_3_0_CustomRecordSelector.SBR_3_0_CustomRecordQueryBuilder builder,
    Map<String, Object> inputs
  ) {
    this.builder = builder;
    this.inputs = inputs;
  }

  public virtual Object getRecords() {
    this.buildQuery();
      system.debug('query::'+this.query);
    this.records = Database.query(this.query);
    return this.records;
  }

  public virtual void buildQuery() {
    this.query = this.builder.build();
  }
  public virtual String getQuery() {
    System.debug('Final Query ' + this.query);
    return this.query;
  }

  public virtual Integer getCount() {
    this.buildQuery();
    System.debug('Final Query ' + this.query);
    Integer count = Database.countQuery(this.query);
    return count;
  }

  public class SBR_3_0_CustomRecordQueryBuilder {
    Set<String> fields;
    String fieldsJoined = '';
    String objectName = '';
    String whereClause = '';
    String orderClause = '';
    String securityClause = '';
    String limitClause = '';
    String additionalClause = '';

    public SBR_3_0_CustomRecordQueryBuilder() {
      this.fieldsJoined = '';
      this.objectName = '';
      this.whereClause = '';
      this.orderClause = '';
      this.securityClause = '';
      this.limitClause = '';
      this.additionalClause = '';
    }
    public Set<String> getFields() {
      return this.fields;
    }

    public void setFields(Set<String> fields) {
      this.fields = fields;
      this.setFieldsJoined(String.join(new List<String>(fields), ', '));
    }

    public String getFieldsJoined() {
      if (this.fieldsJoined == '') {
        this.fieldsJoined = 'Id';
      }
      return this.fieldsJoined;
    }

    public void setFieldsJoined(String fieldsJoined) {
      this.fieldsJoined = fieldsJoined;
    }

    public String getObjectName() {
      return this.objectName;
    }

    public void setObjectName(String objectName) {
      this.objectName = objectName;
    }

    public String getWhereClause() {
      return this.whereClause;
    }

    public void setWhereClause(String whereClause) {
      this.whereClause = whereClause;
    }

    public String getOrderClause() {
      return this.orderClause;
    }

    public void setOrderClause(String orderClause) {
      this.orderClause = orderClause;
    }

    public String getSecurityClause() {
      return this.securityClause;
    }

    public void setSecurityClause() {
      this.securityClause = 'WITH SECURITY_ENFORCED ';
    }

    public String getLimitClause() {
      return this.limitClause;
    }

    public void setLimitClause(String limitClause) {
      this.limitClause = limitClause;
    }

    public String getAdditionalClause() {
      return this.additionalClause;
    }

    public void setAdditionalClause(String additionalClause) {
      this.additionalClause = additionalClause;
    }

    public void setCountClause() {
      this.fieldsJoined = ' COUNT() ';
    }

    public void setCountClause(String groupByField) {
      this.fieldsJoined = ' COUNT(' + groupByField + ')';
    }
    public String build() {
      String query = String.format(
        SOQL_TEMPLATE,
        new List<String>{
          fieldsJoined,
          objectName,
          whereClause,
          securityClause,
          orderClause,
          limitClause,
          additionalClause
        }
      );
      return query;
    }
  }
    
}