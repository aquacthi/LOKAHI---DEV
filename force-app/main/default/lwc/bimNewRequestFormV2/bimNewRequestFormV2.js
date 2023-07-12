import { LightningElement,wire,track} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import REQUEST_OBJECT from '@salesforce/schema/BC_Request__c';
import ROLE_FIELD from '@salesforce/schema/BC_Request__c.BIM_360_Role__c';
import Id from '@salesforce/user/Id';
import isguest from '@salesforce/user/isGuest';
import NAME_FIELD from '@salesforce/schema/User.Name';
import FIRSTNAME_FIELD from '@salesforce/schema/User.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/User.LastName';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import createRequest from '@salesforce/apex/BIMNewRequestForm.createRequest';
import createRequest from '@salesforce/apex/BIMNewRequestForm.createRequestForMultipleProjects';
import getBIMProjects from '@salesforce/apex/BIMNewRequestForm.getBIMProjects';
import getBIMTemplateProjects from '@salesforce/apex/BIMNewRequestForm.getBIMTemplateProjects';
import { NavigationMixin } from 'lightning/navigation';


///////////////////////////////////////////////////////////////////////

const options = [
    {'label':'India','value':'India'},
    {'label':'USA','value':'USA'},
    {'label':'China','value':'China'},
    {'label':'Rusia','value':'Rusia'}
];

///////////////////////////////////////////////////////////////////////

const fields = [NAME_FIELD, EMAIL_FIELD,FIRSTNAME_FIELD,LASTNAME_FIELD];
export default class BIMNewRequestForm extends NavigationMixin(LightningElement) {
    userId = Id;
    isGuestUser = isguest;
    requesttype="";
    amazonian=false;
    formtypeselected=false;
    title="";
    user=undefined;
    //form fields
    firstname="";
    lastname="";
    email="";
    company="";
    firstnamer="";
    lastnamer="";
    emailr="";    
    companyr="";
    chcFirstName="";
    chcLastName="";
    chcEmail="";    
    alias="";
    costcenter="";
    projectcode="";
    role="";  
    facility="";  
    userType="";
    amazonRequestValue="";
    personNeedEmail="";
    personNeedFirstName="";
    personNeedLastName="";
    personNeedCompany="";
    enterFacilityNameInstead=false;
    BIMType="";
    vendorHasNDA="";
    
    companycontracted="";
    contractholdercompany="";
    amazonpointofcontact="";
    contractholdercompanyrequired=false;
    loginTypeSelected=false

    roleValues=undefined;
    requestObjectInfo;
    recordTypeIdBIM360Amazonian;
    recordTypeIdBIM360NonAmazonian;
    recordTypeIdTokenFlexLicense;
    objectInfo;
    projects = [];
    templateprojects = [];

    ///////////////////////////////////////////////////////////
    @track selectedValue;
    @track selectedValueList = [];
    @track options = options;
    
    
    @track selectedItemsToDisplay = ''; //to display items in comma-delimited way
    @track values = []; //stores the labels in this array
    @track projectValues = []; //stores the labels in this array
    @track newProjectValues = []; //stores the labels in this array
    @track isItemExists = false; //flag to check if message can be displayed

    //for single select picklist
    handleSelectOption(event){
        console.log(event.detail);
        this.selectedValue = event.detail;
    }

    //for multiselect picklist
    handleSelectOptionList(event){
        console.log(event.detail);
        this.selectedValueList = event.detail;
        console.log(this.selectedValueList);
    }

    ///////////////////////////////////////////////////////////

    @wire(getObjectInfo, { objectApiName: REQUEST_OBJECT })
    wiredObjectInfo({ error, data }) {
        console.log('wiredObjectInfo data===='+JSON.stringify(data));
        console.log('wiredObjectInfo error===='+JSON.stringify(error));   
        if (data) {
            this.objectInfo=data;
            const rtis = this.objectInfo.recordTypeInfos;
            this.recordTypeIdBIM360Amazonian=Object.keys(rtis).find(rti => rtis[rti].name === 'BIM 360 Amazonian'); 
            this.recordTypeIdBIM360NonAmazonian=Object.keys(rtis).find(rti => rtis[rti].name === 'BIM 360 Non-Amazonian'); 
            this.recordTypeIdTokenFlexLicense=Object.keys(rtis).find(rti => rtis[rti].name === 'Token Flex License'); 
            console.log('this.recordTypeIdBIM360Amazonian===='+this.recordTypeIdBIM360Amazonian);           
        //    this.roleValues = data.values;
        //    this.error = undefined;
        //    console.log('roleValues data===='+JSON.stringify(this.roleValues));
        } else if (error) {
            this.error = error;
            this.roleValues = undefined;
        }            
    }    

    @wire(getBIMProjects)
    wiredBIMProjects({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            console.log('getBIMProjects projects data===='+JSON.stringify(data));
            this.projects = [...this.projects ,{value: '', label: "--Select--"} ]; 
            for(var i=0; i<data.length; i++)  {
                this.projects = [...this.projects ,{value: data[i].Id , label: data[i].Facility_Name__c} ];                                   
            }
            console.log('getBIMProjects projects===='+JSON.stringify(this.projects));
        } else if (error) {
            console.log('getBIMProjects error===='+JSON.stringify(error));
        }
    }    

    @wire(getBIMTemplateProjects)
    wiredBIMTemplateProjects({ error, data }) {
        if (data) {

            //create array with elements which has been retrieved controller
            //here value will be Id and label of combobox will be Name
            console.log('getBIMTemplateProjects projects data===='+JSON.stringify(data));
            this.templateprojects = [...this.templateprojects ,{value: '', label: "--Select--"} ]; 
            for(var i=0; i<data.length; i++)  {
                this.templateprojects = [...this.templateprojects ,{value: data[i].Id , label: data[i].Project_Name__c} ];                                   
            }
            console.log('getBIMTemplateProjects projects===='+JSON.stringify(this.templateprojects));
        } else if (error) {
            console.log('getBIMTemplateProjects error===='+JSON.stringify(error));
        }
    }  
  /*  getrecordTypeId(recordtypename) {
        // Returns a map of record type Ids 
        const rtis = this.requestObjectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === recordtypename);
    }*/

    @wire(getRecord, { recordId: '$userId', fields })
    wiredUser({ error, data }) {
        console.log('data===='+JSON.stringify(data));
        if (data) {
            this.user = data;
            this.error = undefined;
            this.firstname=getFieldValue(this.user, FIRSTNAME_FIELD);
            this.lastname=getFieldValue(this.user, LASTNAME_FIELD);
            this.email=getFieldValue(this.user, EMAIL_FIELD);
            this.firstnamer=getFieldValue(this.user, FIRSTNAME_FIELD);
            this.lastnamer=getFieldValue(this.user, LASTNAME_FIELD);
            this.emailr=getFieldValue(this.user, EMAIL_FIELD);            
        } else if (error) {
            this.error = error;
            this.user = undefined;
        }
    }

    @wire(getPicklistValues,
        {
            recordTypeId:"$recordTypeIdBIM360Amazonian",
            fieldApiName: ROLE_FIELD
        }
    )
    wiredRoles({ error, data }) {
        console.log('role data===='+JSON.stringify(data));
        console.log('role error===='+JSON.stringify(error));
        if (data) {
            this.roleValues = data.values;
            this.error = undefined;
            console.log('roleValues data===='+JSON.stringify(this.roleValues));
        } else if (error) {
            this.error = error;
            this.roleValues = undefined;
        }        
    }

    connectedCallback() {
        if(this.title!=""){
            this.title;
        } else {
            this.title="Request";
        }        
        console.log('userid===='+this.userId);
        if(this.userId!=undefined){
            this.amazonian=true;
            this.formtypeselected=false;            
            this.loginTypeSelected=true;
        }
        // else{
        //     this.title="BIM 360 Construction Cloud Request";
        //     this.requesttype="BIM";
        //     this.amazonian=false;
        //     this.formtypeselected=true;
        // }
    }


    get userOptions() {
        return [
            { label: 'Amazon User', value: 'Amazon User' },
            { label: 'Vendor User', value: 'Vendor User' },
        ];
    }
    get amazonRequestOptions() {
        return [
            { label: 'Token Flex License', value: 'Token Flex' },
            { label: 'BIM360 Construction Cloud Access (Template Project)', value: 'BIM360 (Template Project)' },
            { label: 'BIM360 Construction Cloud Access (Site-Specific Project)', value: 'BIM360 (Site Specific Project)' },
            { label: 'BIM360 Site Specific 3rd Party Vendor', value: 'BIM360 Site Specific 3rd Party Vendor' },
        ];
    }
    get loginTypeIsNotSelected() {
        return !this.loginTypeSelected && !this.amazonian && !this.formtypeselected;
    }
    get displayformselection() {
        return this.amazonian && !this.formtypeselected;
    }  
    get isBMI() {
        return this.requesttype=="BIM";
    }   
    get isNotAmazonionBMI() {
        return ((!this.amazonian || this.amazonRequestValue == "BIM360 Site Specific 3rd Party Vendor") && this.requesttype=="BIM");
    }    
    get isAmazonionTokenFlex() {
        return (this.amazonian && this.requesttype!="BIM");
    } 
    get bimProjectCodeRequired() {
        return !this.enterFacilityNameInstead;
    } 
    get companycontractedoptions() {
        return [
            { label: '--Select--', value: '' },
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }            
    get displayAmazonContractHolderCompany() {
        return 
    }
    get templateBIM() {
        return this.BIMType == 'Template';
    }

    handleNavigate() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/login'
            }
        });
    }

    handleLoginNextClick() {
        console.log('this.userType = ' + this.userType);
        if(this.userType == 'Amazon User') {
            // SSO user
            this.handleNavigate();
        }
        else if(this.userType == 'Vendor User') {
            // Set page to go to BIM
            this.title="BIM 360 Construction Cloud Request";
            this.requesttype="BIM";
            this.amazonian=false;
            this.formtypeselected=true;
            this.loginTypeSelected=true;
        }
        else {
            // surface error to select the radio buttons
        }
    }

    handleAmazonNextClick() {
        console.log('this.amazonRequestValue = ' + this.amazonRequestValue);
        if(this.amazonRequestValue == 'Token Flex') {
            this.requesttype="TOKEN";
            this.title="Token Flex License Request";
            this.formtypeselected=true;
        }
        else if(this.amazonRequestValue == 'BIM360 (Template Project)') {
            this.requesttype="BIM";
            this.title="BIM360 Construction Cloud Request Template Project";
            this.formtypeselected=true;
            this.BIMType = "Template";
        }
        else if(this.amazonRequestValue == 'BIM360 (Site Specific Project)') {
            this.requesttype="BIM";
            this.title="BIM360 Construction Cloud Request Site Specific Project";
            this.formtypeselected=true;
            this.BIMType = "Site Specific";
        }
        else if(this.amazonRequestValue == 'BIM360 Site Specific 3rd Party Vendor') {
            this.requesttype="BIM";
            this.title="BIM360 Site Specific 3rd Party Vendor";
            this.formtypeselected=true;
            // this.BIMType = "Site Specific";
        }
        else {
            // surface error to select the radio buttons
        }
    }

    handleRequestOptionsChange(event) {
        const selectedOption = event.detail.value;
        console.log('amazonRequestValue = ' + selectedOption);
        this.amazonRequestValue=selectedOption;
    }

    handleUserOptionsChange(event) {
        const selectedOption = event.detail.value;
        console.log('userType = ' + selectedOption);
        this.userType=selectedOption;
    }

    handleVendorUserClick(event) {
        this.title="BIM 360 Construction Cloud Request";
        this.requesttype="BIM";
        this.amazonian=false;
        this.formtypeselected=true;
    }
    handleCompanyContractedChange(event) {
        this.companycontracted = event.detail.value;
        this.contractholdercompanyrequired=false;
        if(this.companycontracted && this.companycontracted=='No'){
            this.contractholdercompanyrequired=true;
        }
    }    
    handleNonDisclosureChange(event) {
        this.vendorHasNDA = event.detail.value;
    }  
    handleProjectChange(event) {
        this.projectcode = event.detail.value;
        console.log("projectcode===="+projectcode);
    }     
    handleTokenFlexClick(event) {
        this.requesttype="TOKEN";
        this.title="Token Flex License Request";
        this.formtypeselected=true;
    }    
    handleBMI360Click(event) {
        this.requesttype="BIM";
        this.title="BIM 360 Construction Cloud Request";
        this.formtypeselected=true;
    }     
    handleCancelClick(event) {
        console.log('cancel 1=====');
        window.location.reload();
        console.log('cancel 2=====');
    }      
    handleSubmitClick(event) {
       /* this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
        });*/
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
            console.log('isInputsCorrect====='+isInputsCorrect);
        const isComboboxesCorrect = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
            console.log('isComboboxesCorrect====='+isComboboxesCorrect);

        if (isInputsCorrect && isInputsCorrect==true && isComboboxesCorrect && isComboboxesCorrect == true) {
            // if (this.requesttype == "BIM" && isComboboxesCorrect && isComboboxesCorrect == false) {
            //     return;
            // }
           /* let selectedRecordType;
            if(this.requesttype && this.requesttype=="BMI"){
                selectedRecordType=
            }*/
            console.log('inside save=====');
            var rec = {
                Requestor_Email__c                    : this.email,
                Requestor_First_Name__c               : this.firstname,
                Requestor_Last_Name__c                : this.lastname,
                Requestor_Company_Entered__c          : this.company === "" ? 'Amazon' : this.company,
                Recipient_Email__c                    : this.personNeedEmail,
                Recipient_First_Name__c               : this.personNeedFirstName,
                Recipient_Last_Name__c                : this.personNeedLastName,                
                Recipient_Company_Entered__c          : this.personNeedCompany === "" ? 'Amazon' : this.personNeedCompany,
                Recipient_Cost_Center__c              : this.costcenter,
                Project_Name__c                       : this.facility,
                BIM_360_Role__c                       : this.role,
                Contract_with_Amazon__c               : this.companycontracted === "Yes" ? true : false,
                Amazon_Contract_Holder_Entered__c     : this.contractholdercompany,
                APOC_Email__c                         : this.amazonpointofcontact,
                BIM_Project__c                        : this.projectcode,
                Contract_Holder_Contact_Email__c      : this.chcEmail,
                Contract_Holder_Contact_First_Name__c : this.chcFirstName,
                Contract_Holder_Contact_Last_Name__c  : this.chcLastName,
                Vendor_Has_NDA__c                     : this.vendorHasNDA === "Yes" ? true : false,
                Enter_Project_Name__c                 : this.enterFacilityNameInstead
            }
            
            if (this.title == "Token Flex License Request") {
                rec.RecordTypeId = this.recordTypeIdTokenFlexLicense;
            } else if (this.title == "BIM360 Construction Cloud Request Site Specific Project" || 
                       this.title == "BIM360 Construction Cloud Request Template Project" ) {
                rec.RecordTypeId = this.recordTypeIdBIM360Amazonian;
            } else if (this.title == "BIM360 Site Specific 3rd Party Vendor") {
                rec.RecordTypeId = this.recordTypeIdBIM360NonAmazonian;
            }
            
            if (this.title == "BIM360 Construction Cloud Request Site Specific Project" ||
                this.title == "BIM 360 Construction Cloud Request" || 
                this.title == "BIM360 Site Specific 3rd Party Vendor") {
                rec.Project_Type__c = 'Site-Specific';
            }
            else if (this.title == "BIM360 Construction Cloud Request Template Project") {
                rec.Project_Type__c = 'Template';
            }
            console.log('rec====='+JSON.stringify(rec));

            createRequest({ objRecquest : rec, projects : this.projectValues, newProjects : this.newProjectValues })
            .then(result => {
                if(result !== undefined) {
                    const event = new ShowToastEvent({
                        "title"     : "Success",
                        "message"   : "Request submitted successfully!",
                        "variant"   :"success"
                    });
                    this.dispatchEvent(event);  
                    this.handleCancelClick(null);
                }                
                console.log('result======'+JSON.stringify(result));
            })
            .catch(error => {
                // this.error = reduceErrors(error);
                // console.log("this.error", this.error);

                this.dispatchEvent(
                    new ShowToastEvent({
                        "title"   : 'Error creating record',
                        "message" : error.body.message,
                        "variant" : 'error',
                    }),
                );
                console.log("error===", JSON.stringify(error));
                console.log("error body message===", JSON.stringify(error.body.message));
            });         
 
            
        }
        /*else{
            const event = new ShowToastEvent({
                "title": "Error",
                "message": "Please fill in all required fields.",
                "variant":"error"
            });
            this.dispatchEvent(event);            
        }   */     
    }
    changeFacilityName(event) {        
        var value = event.target.checked;
        console.log("value===="+value);
        this.enterFacilityNameInstead = value;
        this.projectcode = "";
        // const inputName = event.target.dataset.id;
        // if (inputName === 'projectcode') {
        //     this.serialNumber = event.target.value;
        // } else if (inputName === 'infoToggle') {
        //     //it gets set to true when checked and isRequired sets to false
        //     this.infoToggleValue = event.target.checked;
        // }
        // Revalidate projectcode
        Promise.resolve().then(() => {
            const inputEle = this.template.querySelector('.projectcode');
            
            console.log("inputEle===="+inputEle);
            inputEle.reportValidity();
        });
    }
    
    changePersonNeedingInfo(event) {        
        var value = event.target.checked;
        console.log("value===="+value);

        if (value == true) {
            this.personNeedEmail = this.email;
            this.personNeedFirstName = this.firstname;
            this.personNeedLastName = this.lastname;
            this.personNeedCompany = this.company;
        } else {
            this.personNeedEmail = "";
            this.personNeedFirstName = "";
            this.personNeedLastName = "";
            this.personNeedCompany = "";
        }
    }
    
    changeFieldHandler(event) {
        var value = event.target.value;
        console.log("value===="+value);
        if(event.target.dataset.id === 'firstname'){
            this.firstname = value;
        }else if(event.target.dataset.id === 'lastname'){
            this.lastname = value;
        }else if(event.target.dataset.id === 'email'){
            this.email = value;
        }else if(event.target.dataset.id === 'company'){
            this.company = value;
        }else if(event.target.dataset.id === 'firstnamer'){
            this.personNeedFirstName = value;
        }else if(event.target.dataset.id === 'lastnamer'){
            this.personNeedLastName = value;
        }else if(event.target.dataset.id === 'emailr'){
            this.personNeedEmail = value;
        }else if(event.target.dataset.id === 'chcfirstname'){
            this.chcFirstName = value;
        }else if(event.target.dataset.id === 'chclastname'){
            this.chcLastName = value;
        }else if(event.target.dataset.id === 'chcemail'){
            this.chcEmail = value;
        }else if(event.target.dataset.id === 'companyr'){
            this.personNeedCompany = value;
        }else if(event.target.dataset.id === 'costcenter'){
            this.costcenter = value;
        }else if(event.target.dataset.id === 'alias'){
            this.alias = value;
        }else if(event.target.dataset.id === 'projectcode'){
            this.projectcode = value;
        }else if(event.target.dataset.id === 'role'){
            this.role = value;
        }else if(event.target.dataset.id === 'facility'){
            this.facility = value;
        }else if(event.target.dataset.id === 'companycontracted'){
            this.companycontracted = value;
        }else if(event.target.dataset.id === 'contractholdercompany'){
            this.contractholdercompany = value;
        }else if(event.target.dataset.id === 'amazonpointofcontact'){
            this.amazonpointofcontact = value;
        }          
    }    

    //captures the retrieve event propagated from lookup component
    selectItemEventHandlerLookup(event){
        console.log(' in selectItemEventHandlerLookup ');
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args, 'lookup');        
    }

    //captures the remove event propagated from lookup component
    deleteItemEventHandlerLookup(event){
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args, 'lookup');
    }

    //captures the retrieve event propagated from textbox component
    selectItemEventHandlerTextBox(event){
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args, 'textbox');        
    }

    //captures the remove event propagated from textbox component
    deleteItemEventHandlerTextBox(event){
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args, 'textbox');
    }

    //displays the items in comma-delimited way
    displayItem(args, componentType){
        console.log(' in displayItem ');

        this.values = []; //initialize first
        this.projectsById = []; //initialize first
        // args.map(element=>{
        //     this.values.push(element.label);
        //     this.projectsById.push(id = element.value, value = element.label);
        // });
        console.log('values ' + this.values);
        console.log('args ' + JSON.stringify(args));


        if (componentType == 'lookup') {

            this.isItemExists = (args.length>0);
            console.log('isItemExists ' + this.isItemExists);
            this.projectValues = args; 
            console.log('projectValues ' +  JSON.stringify(this.projectValues));

        }
        else if (componentType == 'textbox') {
            this.newProjectValues = args;           
            console.log('newProjectValues ' +  JSON.stringify(this.newProjectValues));  
        }
        this.selectedItemsToDisplay = this.values.join(', ');
        console.log('selectedItemsToDisplay ' + this.selectedItemsToDisplay);

    }
}