import LightningDatatable from "lightning/datatable";
import imageTableItemType from "./imageTableItemTemplate.html";
import kitTableItemType from "./kitTableItemTemplate.html";
import customQuantityTemplate from "./customQuantityTemplate.html";
import customIconTooltip from "./customIconTemplate.html"; /* Start ----  FRONT-1639 */
import customButtonIcon from "./customButtonIconTemplate.html";
import recordQuickViewTemplate from "./recordQuickViewTemplate.html";

export default class Sbr_3_0_customDataTableCmp extends LightningDatatable {
  static customTypes = {
    image: {
      template: imageTableItemType,
      typeAttributes: ["imgUrl", "altText"]
    },
    kit: {
      template: kitTableItemType,
      typeAttributes: ["kits"]
    },
    customQuantity: {
      template: customQuantityTemplate,
      standardCellLayout: true,
      typeAttributes: [
        "isEditableFlag",
        "createdQuantity",
        "pickupQuantity",
        "itemRecord"
      ]
    },
    /* Start ----  FRONT-1639,FRONT-10473 */
    iconTooltip: {
      template: customIconTooltip,
      typeAttributes: ["iconName", "iconVariant", "tooltip", "iconSize"]
    },
    /* End ----  FRONT-1639,FRONT-10473 */

    buttonIcon: {
      template: customButtonIcon,
      typeAttributes: [
        "iconName",
        "iconVariant",
        "tooltip",
        "iconSize",
        "name",
        "class",
        "rowId"
      ]
    },

    // FRONT-10860
    recordQuickViewTemplate: {
      template: recordQuickViewTemplate,
      typeAttributes: [
        "variant",
        "recordId",
        "config",
        "objectApiName",
        "iconName", 
        "fields"
      ]
    }
  };
}