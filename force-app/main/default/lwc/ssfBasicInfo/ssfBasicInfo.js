import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import formFactorName from '@salesforce/client/formFactor';
import companyShortName from '@salesforce/label/c.SSF_Company_Short_Name';
import companyPrivacyPolicyLink from '@salesforce/label/c.SSF_Company_Privacy_Policy_Link';
import partnerSSSSelectionEnabled from '@salesforce/apex/SimpleSignupFormController.partnerSSSSelectionEnabled';
import { postReadyStateEvent } from 'c/ssfShared';
import {
    onLoad,
    getFinDocFileTypes,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    handleUnderwritingChange,
    verifyUtilityAccountEntry,
    validateServiceZipCode,
    findDuplicateUAL,
    verifyPODEntry,
    getText,
    submitApplication,
    validateContactEmail,
    handleAccountNumberInputMask,
    handleValidateAccountNumber
} from 'c/ssfBasicInfoShared';

export default class SsfBasicInfo extends NavigationMixin(LightningElement) {
    @api leadJson;
    @api resiApplicationType;
    @api customerType;
    @api zipCheckResponse;
    @api underwritingOptions;
    @api partnerId;
    @api salesRepId;
    @api campaignId;
    @api mock;

    @track zipinput;
    @track collectRateClass;
    @track selectedUtility;
    @track selectedProduct;
    @track rateClassOptions;
    @track rateClassObj;
    @track utilityId;
    @track restLead;
    @track propertyAccount;
    @track stateOptions;
    @track selectedRateClasses = [];
    @track sameBillingAddress;
    @track utilityAccountSection;
    @track isFileUpload;
    @track showUnderwritingOptions;
    @track showAddress;
    @track underwritingHelpTextVisible;
    @track disableUnderwritingFields = false;
    @track showModal;
    @track duplicateLeadId;
    @track underwriting = 'FICO'; // Defaulted to FICO
    @track uanPrefix;
    @track podPrefix;
    @track uanLength;
    @track podLength;
    @track showProjectSelection = false;

    lmiSystems = [];
    smallCSSystems = [];

    collectPOD = false;
    utilityAccountCount = 0;
    resumedApp = false;
    finDocFileTypes = getFinDocFileTypes();
    label = {
        companyPrivacyPolicyLink,
        companyShortName,
    }

    connectedCallback() {
        onLoad(this);
        postReadyStateEvent(this, null);
        if(this.partnerId != null) {
            this.checkProjectSelection();
        }
    }

    checkProjectSelection() {
        partnerSSSSelectionEnabled({partnerId: this.partnerId})
        .then(result => {
            if (result) {
                this.setupProjectSelection();
            }
        }).catch(error => {
            this.showProjectSelection = false;
        })
    }

    setupProjectSelection() {
        this.parseSystemsList();

        if (this.customerType === 'LMI' && this.lmiSystems.length > 1) {
            if (this.setDefaultProject()) {
                this.restLead.partnerSystemSelection = this.lmiSystems[0].value;
            }
            this.projectOptions = this.lmiSystems;
            this.showProjectSelection = true;
        } else if (this.smallCSSystems.length > 1) {
            if (this.setDefaultProject()) {
                this.restLead.partnerSystemSelection = this.smallCSSystems[0].value;
            }
            this.projectOptions = this.smallCSSystems;
            this.showProjectSelection = true;
        } else {
            this.showProjectSelection = false;
        }
    }

    parseSystemsList() {
        let systems = this.zipCheckResponse.solarSystems;

        systems.forEach(sss => {
            if (sss.smallCsCapacityAvailable) {
                let csOption = {label: sss.name, value: sss.sssId};
                this.smallCSSystems.push(csOption);
            }
            if (sss.lmiCapacityAvailable) {
                let lmiOption = {label: sss.name, value: sss.sssId};
                this.lmiSystems.push(lmiOption);
            }
        });
    }

    // feature to allow a partner to change project on continue application is not currently being used
    // since we currently don't want to return SSS information after initial application submission (5/18/2022)
    // leaving front end in case we decide to implement this feature in the future
    setDefaultProject() {
        return (this.restLead.partnerSystemSelection != null && !this.projectStillAvailable()) || this.restLead.partnerSystemSelection == null;
    }

    projectStillAvailable() {
        let previouslySelectedSystem = this.restLead.partnerSystemSelection;
        let availableSystems = this.customerType === 'LMI' ? this.lmiSystems : this.smallCSSystems;
        let availableSystemIds = [];

        availableSystems.forEach(sss => {
            availableSystemIds.push(sss.value);
        });
        return availableSystemIds.includes(previouslySelectedSystem);
    }

    // handle changes in form entries
    genericOnChange(event) {
        this.restLead[event.target.name] = event.target.value;
        if (event.target.name === 'underwritingCriteria') {
            // Set application and Lead to use specified underwriting selection
            this.underwriting = event.target.value;
            handleUnderwritingChange(this);
        }
    }

    phoneOnChange(event) {
        const strippedPhone = event.target.value.replace(/\D/g,'');
        event.target.setCustomValidity("");
        if(strippedPhone.length === 10) {
            this.restLead[event.target.name] = strippedPhone.substr(0,3) + '-' + strippedPhone.substr(3,3) + '-' + strippedPhone.substr(6,4);
        } else {
            this.restLead[event.target.name] = strippedPhone;
            event.target.setCustomValidity("Please enter a 10-digit phone number");
        }
    }

    preventDefaultEvent(event) {
        event.preventDefault();
    }

    utilityAccountOnChange(event) {
        let eventField = event.target.name;
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex][eventField] = event.target.value;
        if (eventField === 'utilityAccountNumber' || eventField === 'utilityAccountNumberReentry') {
            handleAccountNumberInputMask(this, event, 'uan');
            verifyUtilityAccountEntry(this, event, eventField);
        } else if (eventField === 'servicePostalCode' && event.target.value.length === 5) {
            validateServiceZipCode(this, event);
        } else if (eventField === 'podId' || eventField === 'podIdReentry') {
            handleAccountNumberInputMask(this, event, 'podId');
            verifyPODEntry(this, event, eventField);
        }
    }

    setAndValidateContactEmail(event) {
        this.restLead.email = event.target.value;
        validateContactEmail(this);
    }

    handleZipEntry(event) {
        validateServiceZipCode(this, event);
    }

    validateUtilityAccount(event) {
        handleValidateAccountNumber(this, event);
    }

    rateClassOnChange(event) {
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex].rateClass = event.target.value;
        this.selectedRateClasses.push(this.rateClassObj[event.target.value]);
    }

    propertyAccountOnChange(event) {
        this.propertyAccount[event.target.name] = event.target.value;
    }

    billingAddressToggle(event) {
        this.sameBillingAddress = event.target.checked;
    }

    addAnotherUtilityAccount() {
        if (!this.lastUtilityAccountValid()) {
            return;
        }
        this.addUtilityAccount();
    }

    addUtilityAccount() {
        this.utilityAccountCount++;
        this.propertyAccount.utilityAccountLogs.push(getNewRestUtilityAccountLog(this));
        setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
    }

    handleUtilityAccountMenu(event) {
        const selectedItemValue = event.detail.value;
        const utilityAccountIndex = event.target.name;
        if (selectedItemValue === 'remove') {
            this.propertyAccount.utilityAccountLogs.splice(utilityAccountIndex, 1);
            this.utilityAccountCount -= 1;
            setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
        }
    }

    replacementCapacityOnChange(event) {
        this.restLead.replacementCapacity = event.target.checked;
    }

    submit() {
        submitApplication(this, true);
    }

    // perform validations
    lastUtilityAccountValid() {
        let index = this.utilityAccountCount - 1;
        if (validateUtilityAccountLog(this, index)) {
            return true;
        }
        this.showWarningToast('Warning', 'Please complete this utility account before adding another');
        return false;
    }

    handleUtilityBillUpload(event) {
        let files = event.detail;
        let index = event.target.dataset.rowIndex;
        let ual = this.propertyAccount.utilityAccountLogs[index];
        files.forEach(file => {
            ual.utilityBills.push({
                id: file
            });
        });
    }

    handleFinancialDocsUpload(event) {
        let files = event.detail;
        files.forEach(file => {
            this.restLead.financialDocs.push({
                id: file
            });
        });
    }

    toggleUnderwritingHelp() {
        this.underwritingHelpTextVisible = !this.underwritingHelpTextVisible;
    }

    get formFactor() {
        return formFactorName;
    }

    get isPhone() {
        return formFactorName === 'Small';
    }

    get underwritingHelpText() {
        return getText(this, 'underwritingHelptext');
    }

    get underwritingReadOnly() {
        return this.disableUnderwritingFields;
    }

    get isFicoUnderwriting() {
        return this.underwriting === 'FICO';
    }

    get isFinDocsUnderwriting() {
        return this.underwriting === 'Financial Review';
    }

    get ualNumFieldLabel() {
        return getText(this, 'ualNumLabel');
    }

    get ualNumReentryFieldLabel() {
        return getText(this, 'ualNumReentryLabel');
    }

    get podEntryFieldLabel() {
        return getText(this, 'podLabel');
    }

    get podReentryFieldLabel() {
        return getText(this, 'podReentryLabel');
    }

    get businessNameFieldLabel() {
        return getText(this, 'businessNameLabel');
    }

    get businessTitleFieldLabel() {
        return getText(this, 'businessTitleLabel');
    }

    get billingInfoFieldLevelHelp() {
        return `This is the address the ${this.label.companyShortName} bill will be sent to.`;
    }

    get sssSelectionFieldLevelHelp() {
        return 'Your customer will be placed on the system you select as long as there is sufficient capacity when the application is approved.';
    }

}