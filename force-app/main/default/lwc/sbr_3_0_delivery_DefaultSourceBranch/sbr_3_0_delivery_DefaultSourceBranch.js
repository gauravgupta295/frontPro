import { LightningElement, track, api } from "lwc";
import sbr_3_0_deliveryDefaultSourceBranchDesktop from "./sbr_3_0_delivery_DefaultSourceBranchDesktop.html";
import sbr_3_0_deliveryDefaultSourceBranchMobile from "./sbr_3_0_delivery_DefaultSourceBranchMobile.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import LOCATION_TEST_DATA from "@salesforce/label/c.SBR_3_0_LocationTestData";
import LOCATION_TEST_DATA1 from "@salesforce/label/c.SBR_3_0_LocationTestData1";

export default class Sbr_3_0_delivery_DefaultSourceBranch extends LightningElement {
  @api deliveryMethodValue;
  @api isMobile;
  @track tableColumns;
  @track tableData;
  @api sourcingBranchValue;
  label = LABELS;
  testdatalabel = LOCATION_TEST_DATA;
  testdatalabel1 = LOCATION_TEST_DATA1;
  deliveryColumns = [
    {
      label: LABELS.OTHERSOURCEBRANCHLOCATIONHEADER,
      fixedWidth: 100,
      fieldName: "Location",
      wrapText: true,
      cellAttributes: {
       // class: "successLink",
        headerColumn: true
      }
    },
    {
      label: LABELS.DISTANCE,
      fieldName: "Distance",
      type: "text",
      wrapText: true
    },
    {
      label: LABELS.FULFILLMENT,
      fieldName: "Fulfillment",
      type: "button",
      initialWidth: 110,
      cellAttributes: { class: "removeButtonStyling" },
      typeAttributes: {
        label: { fieldName: "Fulfillment" },
        name: "fulfillmentPercentage",
        title: "fulfillmentPercentage",
        disabled: false,
        value: "fulfillmentPercentage",
        class: "removeButtonStyling",
        onClick: "openFulfillmentMenu"
      },
      wrapText: true
    },
    {
      label: LABELS.ADDRESS,
      fieldName: "Address",
      type: "text",
      wrapText: true
    },
    {
      label: LABELS.PHONEHASH,
      fieldName: "Phone",
      type: "text",
      wrapText: true,
      cellAttributes: {
      //  class: "successLink"
      }
    },
    {
      label: LABELS.ESTIMATEDDELIVERY,
      fieldName: "EstDelivery",
      type: "text",
      wrapText: true
    }
  ];

  pickupColumns = [
    {
      label: LABELS.OTHERSOURCEBRANCHLOCATIONHEADER,
      fieldName: "Location",
      wrapText: true,
      cellAttributes: {
       // class: "successLink",
        headerColumn: true
      }
    },
    {
      label: LABELS.DISTANCE,
      fieldName: "Distance",
      type: "text",
      wrapText: true
    },
    {
      label: LABELS.FULFILLMENT,
      fieldName: "Fulfillment",
      type: "text",
      wrapText: true
    },
    {
      label: LABELS.ADDRESS,
      initialWidth: 300,
      fieldName: "Address",
      type: "text",
      wrapText: true
    },
    {
      label: LABELS.PHONEHASH,
      fieldName: "Phone",
      type: "text",
      wrapText: true,
      cellAttributes: {
       // class: "successLink"
      }
    }
  ];

  @track pickupData = [
    {
      id: this.testdatalabel1,
      Location: "0051",
      Distance: "7.0",
      Fulfillment: "100%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5555",
      linkColor: "successLink"
    },
    {
      id: this.testdatalabel,
      Location: "8007",
      Distance: "8.5",
      Fulfillment: "100%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5556",
      linkColor: "successLink"
    },
    {
      id: "1318L0000009G9EQAU",
      Location: "0003",
      Distance: "10.4",
      Fulfillment: "100%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5557",
      linkColor: "successLink"
    },
    {
      id: "3",
      Location: "0051",
      Distance: "2.0",
      Fulfillment: "80%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5558",
      linkColor: "successLink"
    },
    {
      id: "5",
      Location: "0005",
      Distance: "6.0",
      Fulfillment: "75%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5559",
      linkColor: "successLink"
    },
    {
      id: "6",
      Location: "0006",
      Distance: "10.8",
      Fulfillment: "60%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5560",
      linkColor: "successLink"
    },
    {
      id: "7",
      Location: "0007",
      Distance: "20.0",
      Fulfillment: "60%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5561",
      linkColor: "successLink"
    },
    {
      id: "8",
      Location: "0008",
      Distance: "30.0",
      Fulfillment: "55%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5562",
      linkColor: "successLink"
    }
  ];
 //Modified below static value for demo purpose.Gopal Raj
  @track deliveryData = [
    {
      id: this.testdatalabel1,
      Location: "0001",
      locationId: "01-0001",
      locationName: "NEW CASTLE AWP PC637",
      Distance: "7.0",
      Fulfillment: "100%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5555",
      EstDelivery: "10/01/23 02:00PM",
      linkColor: "successLink",
      cartItems: {
        "1111": {
            "fulfillQuantity": 1.0,
            "requestQuantity": 1.0,
            "productId": "0070025",
            // "productId": "0070010",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T17:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "0090315",
            // "productId": "0070008",
            "productType": "P",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: this.testdatalabel,
      Location: "0693",
      locationId: "01-0693",
      locationName: "GASTONIA PC051",
      Distance: "8.5",
      Fulfillment: "100%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5556",
      EstDelivery: "10/01/23 03:00PM",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 1.0,
            "requestQuantity": 1.0,
            "productId": "0070025",
            //"productId": "0580048",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "3",
      Location: "0003",
      locationId: "01-0003",
      locationName: "KANSAS CITY CC PC748",
      Distance: "10.4",
      Fulfillment: "70%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5557",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 1.0,
            "requestQuantity": 1.0,
            "productId": "0070025",
            "productType": "H",
            "EstimatedDeliverytime": ""
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "4",
      locationId: "01-0004",
      Location: "0004",
      locationName: "KANSAS CITY CC PC748",
      Distance: "10.5",
      Fulfillment: "80%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5558",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 8.0,
            "requestQuantity": 8.0,
            "productId": "01-0009",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "5",
      Location: "0005",
      locationId: "01-0005",
      locationName: "KANSAS CITY CC PC748",
      Distance: "10.7",
      Fulfillment: "75%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5559",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 8.0,
            "requestQuantity": 8.0,
            "productId": "01-0009",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "6",
      Location: "0006",
      locationId: "01-0006",
      locationName: "KANSAS CITY CC PC748",
      Distance: "10.8",
      Fulfillment: "60%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5560",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 8.0,
            "requestQuantity": 8.0,
            "productId": "01-0009",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "7",
      Location: "0007",
      locationId: "01-0007",
      locationName: "KANSAS CITY CC PC748",
      Distance: "20.0",
      Fulfillment: "60%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5561",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 8.0,
            "requestQuantity": 8.0,
            "productId": "01-0009",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    },
    {
      id: "8",
      Location: "0008",
      locationId: "01-0008",
      locationName: "KANSAS CITY CC PC748",
      Distance: "30.0",
      Fulfillment: "55%",
      Address: "1 Main st. New York, NY, 103927",
      Phone: "555-555-5562",
      EstDelivery: "-",
      linkColor: "successLink",
      "cartItems": {
        "1111": {
            "fulfillQuantity": 8.0,
            "requestQuantity": 8.0,
            "productId": "01-0009",
            "productType": "H",
            "EstimatedDeliverytime": "2023-01-04T18:00:00Z"
        },
        "2222": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 1.0,
            "productId": "10044906",
            "productType": "P",
            "EstimatedDeliverytime": "" 
        },
        "3333": {
            "fulfillQuantity": 0.0,
            "requestQuantity": 2.0,
            "productId": "10098327",
            "productType": "M",
            "EstimatedDeliverytime": ""
        }
    }
    }
  ];

  connectedCallback() {
    if (this.deliveryMethodValue === "Delivery") {
      this.tableColumns = this.deliveryColumns;
      this.tableData = this.deliveryData;
    } else {
      this.tableColumns = this.pickupColumns;
      this.tableData = this.pickupData;
    }
  }
  getSelectedName(event) {
    if (event.detail.selectedRows.length > 0) {
      const customEvent = new CustomEvent("eventnotification", {
        detail: {
          eventType: "enableConfirm",
          selectedRows: event.detail.selectedRows
        }
      });
      this.dispatchEvent(customEvent);
    }
  }

  handleRowAction(event) {
    const detailObj = {};
    try {
      if(this.deliveryMethodValue === "Delivery") {
        const catClassList = [];
        const catClassRequestedQtyMap = new Map();
        Object.keys(event.detail.row.cartItems).forEach((key) => {
          catClassList.push(event.detail.row.cartItems[key].productId);
          catClassRequestedQtyMap.set(event.detail.row.cartItems[key].productId, event.detail.row.cartItems[key].requestQuantity);
        });

        detailObj.detail = {
          fulfillmentId: event.detail.row.id,
          fulfillmentPercentage: event.detail.row.Fulfillment,
          locationId: event.detail.row.Location,
          catClassList: catClassList,
          catClassRequestedQtyMap: catClassRequestedQtyMap
        }
      } else {
        detailObj.detail = {
          fulfillmentId: event.detail.row.recordId,
          fulfillmentPercentage: event.detail.row.recordValue
        }
      }
      console.log("From hadnleRowAction event", JSON.stringify(event.detail), JSON.stringify(detailObj));
      const rowActionEvent = new CustomEvent("rowactionevent", detailObj);
      this.dispatchEvent(rowActionEvent);
    }
    catch(e) {
      console.log("error", e.toString());
    }
  }

  handleRowActionMobile(event) {
    const detailObj = {};
    try {
      if(this.deliveryMethodValue === "Delivery") {
        let selectedRow = {}
        this.deliveryData.forEach((item) => {
          if(item.id === event.detail.recordId) {
            selectedRow = item;
          }
        })
        const catClassList = [];
        const catClassRequestedQtyMap = new Map();
        Object.keys(selectedRow.cartItems).forEach((key) => {
          catClassList.push(selectedRow.cartItems[key].productId);
          catClassRequestedQtyMap.set(selectedRow.cartItems[key].productId, selectedRow.cartItems[key].requestQuantity);
        });

        detailObj.detail = {
          fulfillmentId: selectedRow.id,
          fulfillmentPercentage: selectedRow.Fulfillment,
          locationId: selectedRow.Location,
          catClassList: catClassList,
          catClassRequestedQtyMap: catClassRequestedQtyMap
        }
      } else {
        detailObj.detail = {
          fulfillmentId: selectedRow.recordId,
          fulfillmentPercentage: selectedRow.recordValue
        }
      }
      const rowActionEvent = new CustomEvent("rowactionmobileevent", detailObj);
      this.dispatchEvent(rowActionEvent);
    }
    catch(e) {
      console.log("error", e.toString());
    }
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = sbr_3_0_deliveryDefaultSourceBranchMobile;
    } else {
      renderTemplate = sbr_3_0_deliveryDefaultSourceBranchDesktop;
    }
    return renderTemplate;
  }
}