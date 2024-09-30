import { LightningElement, track } from "lwc";
import DESKTOPTEMPLATE from "./sbr_3_0_AssignAssetSourceComponentDesktop.html";
import MOBILETEMPLATE from "./sbr_3_0_AssignAssetSourceComponentMobile.html";
import FORM_FACTOR from "@salesforce/client/formFactor";
//Created For stories FRONT-6278,FRONT-7420
export default class Sbr_3_0_AssignAssetSourceComponent extends LightningElement {
  
  @track isMobile = false;

  activeSections = ["A", "C"];
  activeSectionsMessage = "";
  showViewMore = true;
  showViewLess = false;
  data = [];
  count = 2;
  reservationColumns = [
    { label: "Branch",fieldName: "Branch",wrapText: true },
    { label: "Distance (Miles)", fieldName: "Distance", type: "text",wrapText: true },
    { label: "Fulfillment %", fieldName: "Fulfillment", type: "text",wrapText: true }
  ];
  catClassColumns = [
    { label: "Branch",fieldName: "Branch" ,wrapText: true},
    { label: "Req | Alt",fieldName: "Req_Alt", type: "text",wrapText: true },
    { label: "Cat-Class",fieldName: "Cat_Class", type: "text",wrapText: true },
    { label: "Distance (Miles)",fieldName: "Distance", type: "text",wrapText: true },
    { label: "Description",fieldName: "Description", type: "text",wrapText: true },
    { label: "Avail",fieldName: "Avail", type: "text",wrapText: true },
    { label: "Inv.Type", fieldName: "Inv_Type", type: "text",wrapText: true }
  ];
  activeSectionsDesktop = ["X", "Y"];

  @track FulfillmentSourcingData = [
    {
      id: "1",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    },
    {
      id: "2",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    },
    {
      id: "3",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    },
    {
      id: "4",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    },
    {
      id: "5",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    },
    {
      id: "6",
      Branch: "003",
      Distance: "8.0",
      Fulfillment: "100%"
    }
  ];

  @track catClassData = [
    {
      id: "1",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    },

    {
      id: "2",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    },
    {
      id: "3",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    },
    {
      id: "4",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    },
    {
      id: "5",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    },
    {
      id: "6",
      Branch: "003",
      Req_Alt: "Req",
      Cat_Class: "55-310",
      Distance: "8.0",
      View_More: true,
      View_Less: false,
      Description: "20-25' Straight Mast Rough Terrain Forklift",
      Avail: "2",
      Inv_Type: "ATP"
    }
  ];

  viewLess(event) {
    let id = event.target.dataset.value;

    for (let i = 0; i < this.catClassData.length; i++) {
      if (this.catClassData[i].id == id) {
        this.catClassData[i].View_Less = false;
        this.catClassData[i].View_More = true;
      }
    }
    /*
      this.toggleFieldsOnMobile(id,true)
    */
  }

  viewMore(event) {
    let id = event.target.dataset.value;

    for (let i = 0; i < this.catClassData.length; i++) {
      if (this.catClassData[i].id == id) {
        this.catClassData[i].View_Less = true;
        this.catClassData[i].View_More = false;
      }
    }
    /*
      this.toggleFieldsOnMobile(id, false)
    */
  }

  toggleFieldsOnMobile(recordId, viewMore) {
    this.catClassData = this._tabs.map((data) => {
      if (data.id === recordId) {
        data.View_Less = !viewMore;
        data.View_More = viewMore;
      }
      return data;
    });
  }

  handleSectionToggle(event) {
    const openSections = event.detail.openSections;

    if (openSections.length === 0) {
      this.activeSectionsMessage = "All sections are closed";
    } else {
      this.activeSectionsMessage = "Open sections: " + openSections.join(", ");
    }
  }

  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }
}