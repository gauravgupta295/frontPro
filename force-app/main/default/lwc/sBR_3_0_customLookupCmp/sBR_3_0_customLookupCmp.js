import { LightningElement, api, wire, track } from "lwc";
// import apex method from salesforce module
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupDataUsingParent";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecordMultiple";
import Sbr_3_0_address_Css from "@salesforce/resourceUrl/Sbr_3_0_AddressCss"; //1644
import { loadStyle } from "lightning/platformResourceLoader"; //1644
//SF-5340
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

const DELAY = 300; // dealy apex callout timing in miliseconds

export default class CustomLookupLwc extends LightningElement {
  @api
  get selectedRepId() {
    return this._selectedRecordd;
  }
  @track _selectedRecordd = "";

  // public properties with initial default values
  @api label = "Custom Lookup Label";
  @api placeholder = "search...";
  @api iconName = "standard:opportunity";
  @api sObjectApiName;
  @api isRequired = false;
  @api defaultRecordId = "";
  @api fieldsToInclude = "";
  @api hasCustomNameField = false;
  @api customNameField = "";
  @api fieldsToSet = "";
  @api isDisabled = false;

  @api multiSelect = false;
  @track selectedRecords = [];
  @api selectedRecordsIds = [];
  hasRendered = true;

  @api recordId = "";
  @api parentName = "";
  @api whereClause = "";
  @api heightCss = "";
  @track selectedRecords = [];
  @api minHeight;
  // private properties
  lstResult = []; // to store list of returned records
  hasRecords = true;
  @track searchKey = ""; // to store input field value
  spinnerShow = false; // to control loading spinner
  delayTimeout;
  selectedRecordd = {}; // to store selected lookup record in object formate
  isMobile = false;
  spinnerCss = "spinner-height";
  hasRendered = true;
  isSearchLoading = false; // to control loading spinner
  isAccount = false;
  isUserLocation = false;
  showSalesRep = false;
  
  // initial function to populate default selected lookup record if defaultRecordId provided
  connectedCallback() {
    //Front-1664 start, Front-1628
    if (this.label == "Sales Rep") {
      this.showSalesRep = true;
    } else {
      this.showSalesRep = false;
    }
    //Front-1664 end
    this.spinnerCss = this.lstResult.length == 0 ? "spinner-height" : "";
    this.spinnerShow = true;
    if (
      this.defaultRecordId != "" &&
      this.defaultRecordId != "undefined" &&
      this.defaultRecordId != undefined
    ) {
      console.log("this.defaultRecordId>>>>>>>>" + this.defaultRecordId);
      this.setDefaultSelection();
    } else if (this.recordId != "" && this.recordId != null) {
      console.log("this.recordId 45>>>>>>>" + this.recordId);
      this.defaultRecordId = this.recordId;
      console.log("this.defaultRecordId 52>>>>>>>" + this.defaultRecordId);
      this.setDefaultSelection();
      
    }
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
  }

  get compStyle() {
    if(this.minHeight && Number(this.minHeight) > 0) {
        return `min-height: ` + Number(this.minHeight) + `px !important`; 
    }
}

  // 1644 start
  renderedCallback() {
    if (!this.isMobile && this.heightCss != "") {
      this.template.querySelector(
        '[data-source="lookupContainer"]'
      ).style.height = this.heightCss;
    }
    Promise.all([loadStyle(this, Sbr_3_0_address_Css)])
      .then(() => {})
      .catch((error) => {});


  }
  //1644 end
  setDefaultSelection() {
    fetchDefaultRecord({
      recordId: this.defaultRecordId,
      sObjectApiName: this.sObjectApiName,
      hasCustomNameField: this.hasCustomNameField
    })
      .then((result) => {
        if (result != null) {
          console.log(result);
          if (this.multiSelect) {
            this.selectedRecords = result;
            this.selectedRecordsIds = [];
            result.forEach((each) => {
              this.selectedRecordsIds.push(each.Id);
            });
            //this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
          } else {
            this.selectedRecordd = result[0];
            this.recordId = result[0].Id;
            this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
			//fetch lookup data imperitively
			this.callFetchLookupData();
            
          }
        }
      })
      .catch((error) => {
        console.log("fetch default error", error);
        this.error = error;
        this.selectedRecordd = {};
        this.recordId = "";
      });
    this.spinnerShow = false;
  }

	//As the wire property fetchLookupData not getting called from connectedCallback, we need to call it extencively.c/bikeCard
	async callFetchLookupData()
	{
		await fetchLookupData({
			searchKey: this.searchKey,
			sObjectApiName: this.sObjectApiName,
			whereClause: this.whereClause,
			fieldsToInclude: this.fieldsToInclude,
			hasCustomNameField: this.hasCustomNameField,
			parentName: this.parentName
		}).then(async (result) => {
			if(result)
			{
				//Sort result and throw event of selected record to identified the selected record from component
				if(Array.isArray(result))
				{
					for(let i =0; i < result.length; i++)
					{
						//Check If Id of the record matches
						if(this.selectedRecordd.Id === result[i].Id)
						{
							//Throw an event for newLookupset so parent component will get the latest values of fields.c/bikeCard
							//Send an event to parent once in the start fo identify that the record has been set very first time.
							this.sendInitialRecordSetEvent(result[i]);
							return;
						}
					}
				}
			}
		}).catch(async (err)=>{
			console.error("(error---> " + JSON.stringify(err));
		})
	}

  // wire function property to fetch search record based on user input
  @wire(fetchLookupData, {
    searchKey: "$searchKey",
    sObjectApiName: "$sObjectApiName",
    whereClause: "$whereClause",
    fieldsToInclude: "$fieldsToInclude",
    hasCustomNameField: "$hasCustomNameField",
    parentName: "$parentName"
  })
  searchResult(value) {
    const { data, error } = value; // destructure the provisioned value
    console.log("value : ", data, error);
    this.spinnerShow = true;
    if (data) {
      this.hasRecords = data.length == 0 ? false : true;
      this.lstResult = JSON.parse(JSON.stringify(data));
      for (var i = 0; i < this.lstResult.length; i++) {
        let o = this.lstResult[i];

        if (this.hasCustomNameField) {
          o.DisplayName = o[this.customNameField];
        } else {
          o.DisplayName = o["Name"];
        }

        // SF-5340
        if (this.sObjectApiName == "User_Location__c") {
          this.isUserLocation = true;
          o.DisplayName = o["Sales_Rep_Name__c"];
          o.additionalInfo = "";
          console.log("slma : ", o["RepId__c"], o["Rep_Type__c"]);
          if (o["RepId__c"]) {
            o.additionalInfo += o["RepId__c"];
          }
          if (o["Rep_Type__c"]) {
            o.additionalInfo += ", " + o["Rep_Type__c"];
          }
        }

        if (this.sObjectApiName == "User") {
          o.additionalInfo = "";
          if (o["RepID__c"]) {
            o.additionalInfo += o["RepID__c"];
          }
          if (o["RepID__c"] && o["Department"]) {
            o.additionalInfo += " - ";
          }
          if (o["Department"]) {
            o.additionalInfo += "PC" + o["Department"];
          }
          o.additionalInfo2 = "";
          if (o["Rep_Type__c"]) {
            o.additionalInfo2 += o["Rep_Type__c"];
          }
        }
        if (this.sObjectApiName == "Account") {
          this.isAccount = true;
          o.additionalInfo = "";
          o.additionalInfo +=
            (o["RM_Account_Number_Display__c"]
              ? o["RM_Account_Number_Display__c"]
              : "") +
            (o["Status__c"] && o["RM_Account_Number_Display__c"]
              ? " (" + o["Status__c"] + ")"
              : o["Status__c"]
                ? o["Status__c"]
                : "");
          o.additionalInfo2 = "";
          o.additionalInfo2 += `${o.ShippingCity ? `${o.ShippingCity}` : ""}${
            o.ShippingState ? `, ${o.ShippingState}` : ""
          } ${o.ShippingPostalCode ? `  ${o.ShippingPostalCode}` : ""}`;
          o.recordTypeName = "";
          o.recordTypeName = o["RecordType"]
            ? o.RecordType["Name"]
              ? o.RecordType.Name
              : ""
            : "";
        }
        //SERV-14265
        if (this.sObjectApiName == "SM_PS_Equipment_Contract_History__c") {
          o.additionalInfo2 = o.SM_PS_Contract_Order__r?.Customer_Name__r?.Name;
          console.log("checkpoint 1 : ", o);
        }
      }
    } else if (error) {
      console.log("(error---> " + JSON.stringify(error));
    }
    this.spinnerShow = false;
  }

  // update searchKey property on input field change
  handleKeyChange(event) {
    // Debouncing this method: Do not update the reactive property as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    //console.log('event caught in 128',JSON.stringify(event)); // This was throwing an unhandled fault when stringifying event
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );
    lookupInputContainer.classList.add("slds-is-open");

    this.spinnerCss = this.lstResult.length == 0 ? "spinner-height" : "";
    this.hasRecords = true;
    this.spinnerShow = true;
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    console.log("searchKeysearchKey in 132", searchKey);
    this.delayTimeout = setTimeout(() => {
      this.searchKey = searchKey;
    }, DELAY);
    console.log("  this.searchKey in 136", this.searchKeyearchKey);
  }

  // method to toggle lookup result section on UI
  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );
    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute("data-source");
    switch (whichEvent) {
      case "searchInputField":
        clsList.add("slds-is-open");
        break;
      case "lookupContainer":
        clsList.remove("slds-is-open");
        break;
    }
  }

  // method to clear selected lookup record
  @api
  handleRemove() {
    this.searchKey = "";
    this.selectedRecordd = {};
    this.recordId = "";

    this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function

    // remove selected pill and display input field again
    const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
    searchBoxWrapper.classList.remove("slds-hide");
    searchBoxWrapper.classList.add("slds-show");

    const pillDiv = this.template.querySelector(".pillDiv");
    pillDiv.classList.remove("slds-show");
    pillDiv.classList.add("slds-hide");
    console.log("pill removed");
  }

  // method to update selected record from search result
  handleSelectedRecord(event) {
    let objId = event.target.getAttribute("data-recid"); // get selected record Id
    this.recordId = objId;
    this.selectedRecordd = this.lstResult.find(
      (data) => data.Id === this.recordId
    ); // find selected record from list

    this.handleSelectRecordHelper();
    if (this.multiSelect) {
      this.lookupUpdatehandler(this.selectedRecords);
    } else {
      this.lookupUpdatehandler(this.selectedRecordd);
      //SF-5340

      this._selectedRecordd = this.selectedRecordd["Id"];
      console.log("*** this.selectedRecordd : ", this._selectedRecordd);
      //this.dispatchEvent(new FlowAttributeChangeEvent('selectedRepId', this._selectedRecordd));
    } // helper function to show/hide lookup result container on UI
  }

  /*COMMON HELPER METHOD STARTED*/

  handleSelectRecordHelper() {
    if (this.multiSelect) {
      let addToList = true;
      for (let i = 0; i < this.selectedRecords.length; i++) {
        if (this.selectedRecordd.Id == this.selectedRecords[i].Id) {
          addToList = false;
        }
      }

      if (addToList) {
        this.selectedRecords.push(this.selectedRecordd);
        this.selectedRecordsIds.push(this.selectedRecordd.Id);
        this.template.querySelectorAll("lightning-input").forEach((each) => {
          each.value = "";
        });
      }
    } else {
      const lookupInputContainer = this.template.querySelector(
        ".lookupInputContainer"
      );
      if (lookupInputContainer) {
        if (lookupInputContainer.classList && this.selectedRecordd) {
          lookupInputContainer.classList.remove("slds-is-open");
        } else if (lookupInputContainer.classList) {
          lookupInputContainer.classList.add("slds-is-open");
        }
      }

      const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
      if (searchBoxWrapper?.classList) {
        searchBoxWrapper.classList.remove("slds-show");
        searchBoxWrapper.classList.add("slds-hide");
      }


      const pillDiv = this.template.querySelector(".pillDiv");
      if (pillDiv?.classList) {
        pillDiv.classList.remove("slds-hide");
        pillDiv.classList.add("slds-show");
      }
    }
  }

  // send selected lookup record to parent component using custom event
  lookupUpdatehandler(selectedRec) {
    if (this.multiSelect) {
      const oEvent = new CustomEvent("lookupupdate", {
        detail: this.selectedRecordsIds.join(", ")
      });
      this.dispatchEvent(oEvent);
    } else {
      const selectedRecordObj = {
        detail: {
          selectedRecord: { ...this.selectedRecordd }
        },
        bubbles: true,
        composed: true
      };
      const oEvent = new CustomEvent("lookupupdate", selectedRecordObj);
      this.dispatchEvent(oEvent);
    }
  }

	sendInitialRecordSetEvent(selectedRec)
	{
		const selectedRecordObj = {
			detail: {
				selectedRecord: { ...selectedRec }
			},
			bubbles: true,
			composed: true
		};
		const oEvent = new CustomEvent("lookupselect", selectedRecordObj);
		this.dispatchEvent(oEvent);
	}

  removeRecord(event) {
    console.log("removeRecord...");
    console.log(event.detail);
    let selectRecId = [];
    this.selectedRecordsIds = [];
    for (let i = 0; i < this.selectedRecords.length; i++) {
      if (event.detail.name !== this.selectedRecords[i].Id) {
        selectRecId.push(this.selectedRecords[i]);
        this.selectedRecordsIds.push(this.selectedRecords[i].Id);
      }
    }
    this.selectedRecords = [...selectRecId];
    const oEvent = new CustomEvent("lookupupdate", {
      detail: this.selectedRecordsIds.join(", ")
    });
    this.dispatchEvent(oEvent);
  }

  get selectedRecordName() {
    if (this.hasCustomNameField && this.selectedRecordd) {
      return this.selectedRecordd[this.customNameField];
    } else if (this.selectedRecordd) {
      if (this.sObjectApiName == "User_Location__c") {
        return this.selectedRecordd["Sales_Rep_Name__c"];
      } else {
        return this.selectedRecordd["Name"];
      }
    } else {
      return "";
    }
  }

  @api get defaultRecord() {
    return this.defaultRecordId;
  }
  set defaultRecord(value) {
    this.defaultRecordId = value;
    if (this.sObjectApiName) {
      this.setDefaultSelection();
    }
  }

  //getter & setter for setting the selectedRecord attribute
  @api
  get selectedRecordObject() {
    return this.selectedRecordd;
  }
  set selectedRecordObject(value) {
    if (value && value.Id) {
      this.selectedRecordd = value;
      this.recordId = value.Id;
      this.handleSelectRecordHelper();
    } else {
      this.searchKey = "";
      this.selectedRecordd = {};
      this.recordId = "";

      // remove selected pill and display input field again
      const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
      if (searchBoxWrapper) {
        searchBoxWrapper.classList.remove("slds-hide");
        searchBoxWrapper.classList.add("slds-show");
      }

      const pillDiv = this.template.querySelector(".pillDiv");
      if (pillDiv) {
        pillDiv.classList.remove("slds-show");
        pillDiv.classList.add("slds-hide");
      }
    }
  }

  get seachIconAlignment() {
    return this.isMobile ? "slds-input__icon_right" : "";
  }
}