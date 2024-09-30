import { LightningElement, api } from 'lwc';
import getSObjects from "@salesforce/apex/Sbr_3_0_FetchLookupDataController.getSObjects";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

export default class Sbr_3_0_sfsGenericFetchLookupData extends LightningElement {
    @api queryString;
    @api searchResults = [];
    @api retrievedRecords=[];
    @api firstRetrievedRecord;
    @api error;
    handleOnChange(event)
    {

    }
    renderedCallback() {
        console.log(this.queryString);
        if (this.queryString && this.queryString != this.oldQuery) {
        this.getRecords();
      }
      console.log("Records are: " + JSON.stringify(this.retrievedRecords))
    }
    getRecords() {
    
        console.log("Query String is " + this.queryString)
        
          getSObjects({ queryString: this.queryString })
            .then(({ results, firstResult }) => {
              this.error = undefined;
              this.retrievedRecords = results;
              this.firstRetrievedRecord = firstResult;
              this.fireFlowEvent("firstRetrievedRecord", this.firstRetrievedRecord);
              this.fireFlowEvent("retrievedRecords", this.retrievedRecords);
            })
            .catch(error => 
              {this.error = error?.body?.message ?? JSON.stringify(error);
              console.error(error.body.message);
              this.fireFlowEvent("error", this.error);});
    
            this.oldQuery = this.queryString;
        
      }
      fireFlowEvent(eventName, data) {
        this.dispatchEvent(new FlowAttributeChangeEvent(eventName, data));
      }
      


}