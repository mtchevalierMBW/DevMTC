import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
//import VEHICLEINVENTORY_OBJ from '@salesforce/schema/dealer__VehicleInventory__c';
import STOCKNBR_FIELD from '@salesforce/schema/dealer__Vehicle_Inventory__c.dealer__Stock_Number__c';

const docuwareOrgId='34fb6615-0b78-422c-8316-05823806e5f4';
//const docuwareCabinetGuid='3821f170-ecc4-4b9d-bdec-d15f838338c1';
//const docuwareServerUrl1='https://docuware-online.com:443/DocuWare/Platform/WebClient/';
const docuwareServerUrl1='https://mobility-works.docuware.cloud:443/DocuWare/Platform/WebClient/';
const docuwareServerUrl2='/Integration';
//const docuwareResultListId='6cb70053-e999-4477-9697-853c205ebc3c';

export default class DocuwareSearchStockNbr extends LightningElement {
	@api recordId;
	@api docuwareViewer = 'RLV';
	@api docuwareCabinetGuid = '3821f170-ecc4-4b9d-bdec-d15f838338c1';
	@api docuwareResultListGuid = '6cb70053-e999-4477-9697-853c205ebc3c';
	@api docuwareSearchDialogGuid = '3ef0526d-051b-4150-b16a-8d0388452632';

	//vehicleInventory = VEHICLEINVENTORY_OBJ;
	@wire(getRecord, {recordId: '$recordId', fields: [STOCKNBR_FIELD]}) 
	record; 

	get stockNbrValue() {
		return this.record.data ? getFieldValue(this.record.data, STOCKNBR_FIELD) : '';
	}
	openDocuwareSearch() {
		console.log('openDocuwareSearch');
		console.log(this.docuwareViewer);
		let stocknbr = this.record.data ? getFieldValue(this.record.data, STOCKNBR_FIELD) : '';
		let query = this.record.data ? '[STOCK_NUMBER] LIKE "' + getFieldValue(this.record.data, STOCKNBR_FIELD) + '*" ' : '';
		console.log(query);
		console.log(btoa(query));
		let linkstr = docuwareServerUrl1 + docuwareOrgId + docuwareServerUrl2 
			+ '?p=' + this.docuwareViewer 
			+ '&fc=' + this.docuwareCabinetGuid 
			+ '&rl=' + this.docuwareResultListGuid;
		//if (this.docuwareViewer=='SRLV') {
			linkstr += '&sed=' + this.docuwareSearchDialogGuid;
			let datavalues = '[STOCK_NUMBER]=' + stocknbr + '*';
			linkstr += '&dv=' + btoa(datavalues);
		//}
		linkstr += '&q=' + btoa(query);
		console.log("Link: "+linkstr);
		if (this.record.data) window.open(linkstr, "_blank");
		else alert("Unable to search for stock#");
	}

}