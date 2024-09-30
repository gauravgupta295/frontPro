import LightningDatatable from 'lightning/datatable';
import picklistColumn from './sbr_3_0_picklistColumn.html';
import pickliststatic from './sbr_3_0_picklistStatic.html'
 
export default class sbr_3_0_datatableType extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: pickliststatic,
            editTemplate: picklistColumn,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
        }
    };
}