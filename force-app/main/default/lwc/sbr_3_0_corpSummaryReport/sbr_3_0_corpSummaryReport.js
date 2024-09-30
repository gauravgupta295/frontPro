import { LightningElement, api, wire, track } from 'lwc';
/*import getEmbeddingDataForReport from '@salesforce/apex/SBR_3_0_PowerBIReport.getEmbeddingDataForReport';
import powerbijs from '@salesforce/resourceUrl/powerbijs';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from "lightning/uiRecordApi";*/
import RM_ACCOUNT_NUMBER_FIELD from "@salesforce/schema/Account.RM_Account_Number__c";
import RECORDTYPE_ID_FIELD from "@salesforce/schema/Account.RecordTypeId";

const fields = [RM_ACCOUNT_NUMBER_FIELD, RECORDTYPE_ID_FIELD];

export default class Sbr_3_0_corpSummaryReport extends LightningElement {
  @api WorkspaceId ='';
  @api ReportId ='';
  @api calledFrom;
  @api recordId;
  @api recordType;

  //@wire(getRecord, { recordId: '$recordId', fields})account;

  /*@wire(getEmbeddingDataForReport,{
    WorkspaceId: "$WorkspaceId",
    ReportId: "$ReportId"
  }) report;*/

    /*renderedCallback() {
       console.log('renderedCallback exectuting');

        Promise.all([ loadScript(this, powerbijs ) ]).then(() => { 

          console.log('renderedCallback 2');
         // console.log("this.report", this.report);
          var reportContainer = this.template.querySelector('[data-id="embed-container"');
          var config = {
            type: 'report',
            //embedUrl: embedUrl,
            //embedUrl: 'https://api.powerbi.com/v1.0/myorg/groups/25ace407-a7ea-4b57-a554-c0eb86fee2bb/reports/21c06d4b-97ab-4f48-9970-9c1b345a4040',
            embedUrl: 'https://app.powerbi.com/groups/25ace407-a7ea-4b57-a554-c0eb86fee2bb/reports/21c06d4b-97ab-4f48-9970-9c1b345a4040/ReportSection&amp;autoAuth=true&amp;ctid=83554dd6-5e5b-4f18-bfeb-28ac380c6519&amp;config=eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly93YWJpLXVzLWVhc3QyLXJlZGlyZWN0LmFuYWx5c2lzLndpbmRvd3MubmV0LyJ9&amp;filter=%20dw_x0020_vw_DimCorp%20Link%3A%27190191%27',
            tokenType: 1,
            settings: {
              panes: {
                filters: { expanded: false, visible: true },
                pageNavigation: { visible: false }
              }
            }
        }; 
        console.log('renderedCallback 3');
          var report = powerbi.embed(reportContainer, config);*/
         /*   if(this.report.data){

              if(this.report.data.embedUrl && this.report.data.embedToken){
                var reportContainer = this.template.querySelector('[data-id="embed-container"');

                var reportId = this.report.data.reportId;
                var embedUrl = this.report.data.embedUrl;
                var token = this.report.data.embedToken;
              
                var config = {
                  type: 'report',
                  id: reportId,
                  embedUrl: embedUrl,
                  accessToken: token,
                  tokenType: 1,
                  settings: {
                    panes: {
                      filters: { expanded: false, visible: true },
                      pageNavigation: { visible: false }
                    }
                  }
                };
              
                // Embed the report and display it within the div container.
                var report = powerbi.embed(reportContainer, config);

                console.log(powerbi);

              }
              else {
                console.log('no embedUrl or embedToken');
              }
                
              }
              else{
                  console.log('no report.data yet');
              }
       */

      /*  });

    }*/

    get inputVariables() {
        console.log('@@@Record id'+JSON.stringify(this.recordId));
        console.log('@@@Record id'+JSON.stringify(this.calledFrom));
        return [
            {
                name: 'accountId',
                type: 'String',
                value: this.recordId
            },
            {
                name: 'recordType',
                type: 'String',
                value: this.calledFrom
            }
        ];
    }
}