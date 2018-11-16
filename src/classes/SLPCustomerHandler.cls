/*************************************************************************************
 * Created By:  Cole Swain - colemswain@gmail.com | 508-320-5794
 *
 * Description: The SLPCustomerHandler class services the SLP Customer
 * tab and customer window. For the most part, it returns data for
 * display; however it also allows the user to update system information
 * and loan information. It returns disubrsal information, updates disbursals 
 * as confirmed and returns equipment information.
 *
 * Tested By: SLPControllersTestclass
 *************************************************************************************/

public without sharing class SLPCustomerHandler {

  public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
  static {
    profile = SLPUserHelper.getPartnerProfile();
  }

  @AuraEnabled
  public static String getLicenseType() {
      return profile.licenseType;
  }

  @AuraEnabled
  public static String getLicenseTypeandReferralCode() {
      String partnerProfileString = profile.licenseType + '/' + profile.referralCode + '/' + profile.csEnabled;
      return partnerProfileString;
  }

  //The getCustomerInformation method returns an equipment list to show system information, and other customer information on the customer window
  @AuraEnabled
  public static Residential_Equipment__c getCustomerInformation (String loanId) {
	String equipQuery = 'SELECT Id, Name, Loan__r.Name, Loan__r.Opportunity__r.Update_Dummy__c, Loan__r.Opportunity_Stage__c, Loan__r.Opportunity__r.Contract_Status__c, ' +
		'Loan__r.State__c, Opportunity__r.Lead_Id__c, Auto_Reporting_to_PTS__c, Interconnection_Update_Dummy__c, GE_Serial_Number__c, ' +
		'Opportunity__r.Id, Loan__r.Lead__r.Update_Dummy__c, Annual_Production_kWh_kW__c, Loan__r.Lead__r.Annual_Income_Currency__c, ' +
		'Loan__r.Lead__r.Id, Loan__r.Product__r.Name,Loan__r.Requested_Loan_Amount__c,  Loan__r.Commencement_Datee__c, ' +
		'Loan__r.Principall__c, Loan__r.Principal__c, Loan__r.Product__r.Program__c, Loan__r.Id, Loan__r.DOER_Solar_Loann__c,' +
		'Loan__r.Total_Funds_Disbursed__c, Loan__r.Sales_Agent__r.Name, Loan__r.Product__r.External_Name__c, Loan__r.Partner__r.Name, ' +
		'Billing_City__c, Billing_Zip__c, CEC_Production_Tracking_System_ID_Number__c, Commonwealth_Solar_Rebate_Program__c, ' +
		'Concatenated_Inverter_Type__c, Concatenated_Module_Type__c, Contract_Execution_Date__c, DOER_Solar_Loan__c, ' +
		'Estimated_On_Site_Behind_the_Meter_Load__c, Generator_Energized_Online_Date__c, Generator_Installation_Date__c, ' +
		'Generator_Interconnection_Date__c, Generator_Nameplate_Capacity__c, Generator_Type__c, Initial_Solar_Meter_Reading__c, ' +
		'Initial_Solar_Meter_Reading_Date__c, Interconnected__c, Interconnection_Date__c, Inverter_Manufacturer__c, Storage_Inverter_Model__c, ' +
		'Inverter_Model_Number__c, Lead__c, Loan__c, MA_Facility_Sector__c, MA_Facility_Type__c, Mechanical_Installation_Date__c, ' +
		'Mechanically_Installed__c, Module_Array_Azimuth__c, Module_Array_Mounting_Type__c, Module_Array_Tilt__c, Module_Manufacturer__c, ' +
		'Module_Model_Number__c, Module_Mounting_Location__c, Module_Power_Rating__c, Number_of_Inverters__c, Number_of_Meters__c, ' +
        'Storage_Grid_Hybrid__c, Storage_Full_or_Partial_Home__c, Storage_Capacity__c, Storage_Model__c, Storage_Inverter_Manufacturer__c, ' +
		'Number_of_Modules__c, Opportunity__c, Opportunity_Custom_ID__c, Opportunity_Name__c, Percentage_of_System_Shaded__c, ' +
		'PowerClerk_Application_ID__c, Remote_Monitorin_Systegm_Identifier__c, Remote_Monitoring_System_Vendor__c, Solar_Meter_Manufacturer__c, ' +
		'Solar_Meter_Model__c, Solar_Meter_Serial_Number__c, SREC_Opt_In_Calendar_Quarter__c, System_Size_from_Opp__c, ' +
		'System_Size_Differs__c, Type_of_Inverter__c, Type_of_Module__c, Unique_ID__c, Labor_Performed__c, Materials_Supplied__c,' +
		'Other_Labor_Performed__c, Other_Materials_Supplied__c, Opportunity__r.BlueWave_Signature_Status__c, ' +
		'Loan__r.Lead__r.System_Cost__c, Loan__r.Lead__r.Requested_Loan_Amount__c, Opportunity__r.Loan_Principle__c, ' +
		'Loan__r.Lead__r.Loan_System_Information__c, Loan__r.Lead__r.Change_Order_Status__c, Loan__r.Opportunity__c, ' +
        'Loan__r.Lead__r.Email, Loan__r.Sales_Agent__r.Email__c, Loan__r.Lead__c, Loan__r.Lead__r.FirstName, Loan__r.Lead__r.ConvertedContactId, ' +
        'Loan__r.Lead__r.CAP_Stage__c, Loan__r.Estimated_Completion_Date__c, Loan__r.Lead__r.Storage__c, Storage_Manufacturer__c, ' +
		'(SELECT Id, Name, Description from Attachments) ' ;
	equipQuery += '      FROM Residential_Equipment__c' ;
	equipQuery += '      WHERE Loan__r.Id  =  \'' + loanId +  '\' ';
	equipQuery += '      AND Loan__r.Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
	if (profile.licenseType != 'Executive') {
	  equipQuery += '    AND Loan__r.Sales_Agent__r.Id  =  \'' + profile.salesRepId +  '\' ';
	}
	equipQuery += '      LIMIT 1 ';
    return (Residential_Equipment__c) Database.query(equipQuery)[0];
  }

  //the getLoanCustomerTasks returns the list of tasks for the customer window
  @AuraEnabled
  public static List<Partner_Task__c> getLoanCustomerTasks(String loanId) {
    List<Partner_Task__c>  taskList = new List<Partner_Task__c>();
    String taskQuery = 'SELECT Id, Name, Completion_Date__c, SubTasks__c, Loan__r.DOER_Solar_Loann__c, ' +
        'Effective_Status__c, Loan__r.Id, Loan__c, Task_Sequence__c, Task_Type__c, Loan__r.State__c, ' +
        'Owner__c, Action_Label__c, Task_Label__c, Help_Text__c ';
    taskQuery += '      FROM Partner_Task__c' ;
    taskQuery += '      WHERE (Loan__c  =  \'' + loanId +  '\' ';
    taskQuery += '      OR Parent_Task__r.Loan__c = \'' + loanId +  '\' ';
    taskQuery += '      OR Parent_Task__r.Parent_Task__r.Loan__c = \'' + loanId +  '\') ';
    taskQuery += '      AND SubTasks__c  =  false ';
    taskQuery += '      AND Partner__r.Id  =  \'' + profile.partnerId +  '\' ';
    if (profile.licenseType != 'Executive') {
      taskQuery += '    AND Sales_Representative__r.Id  =  \'' + profile.salesRepId +  '\' ';
    }
    taskQuery += '      ORDER BY Full_Tree_Sequence__c ASC';
    for(Partner_Task__c taskRecord : Database.query(taskQuery)) {
      taskList.add(taskRecord);
    }
    return taskList;
  }

  //the getCompleteDisbursals method returns the completed disbursals for the disbursals tab and for the customer window, depending on the
  // parameters provided by the lightning component
  @AuraEnabled
  public static List<Disbursal__c> getCompleteLoanDisbursals(String loanId, String searchValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c, Disbursal_Method__c, Date_of_Disbursal__c, Loan__r.Name, Disbursal_Percentage__c, Status__c, Amount__c, Type__c, Loan__r.Sales_Agent__r.Id ' ;
    disbursalQuery += '      FROM Disbursal__c' ;
    disbursalQuery += '      WHERE Status__c = \'' + 'Disbursed' + '\' ' ;
    disbursalQuery += '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search
      disbursalQuery += '    AND Loan__c = \'' + loanId +  '\' ' ;
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += '    AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;
    }
    disbursalQuery += '      ORDER BY createdDate ASC' ;
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursalList.add(disbursal);
    }
    return disbursalList;
  }

  //the getIncompleteDisbursals method returns the incomplete disbursals for the disbursals tab and for the customer window, depending on the
  // parameters provided by the lightning component. This could be blended with the above method by adding an incomplete/compelete parameter
  @AuraEnabled
  public static List<Disbursal__c> getIncompleteLoanDisbursals(String loanId, String searchValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 'SELECT Id, Name, Partner_Confirmation__c, Disbursal_Method__c, Date_of_Disbursal__c, Loan__r.Name, Disbursal_Percentage__c, Status__c, Amount__c, Type__c, Loan__r.Sales_Agent__r.Id ' ;
    disbursalQuery += '      FROM Disbursal__c' ;
    disbursalQuery += '      WHERE Status__c != \'' + 'Disbursed' + '\' ' ;
    disbursalQuery += '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;

    if (loanId != null && searchValue == null) {
      //query for the records on the customer window disbursal page with no search
      disbursalQuery += '    AND Loan__c = \'' + loanId +  '\' ' ;
    } else if (loanId == null && searchValue != null) {
      //query for the records on the all disbursal page with a search value
      disbursalQuery += '    AND Loan__r.Name LIKE \'' + '%' + String.escapeSingleQuotes(searchValue) + '%' + '\'' ;
    }
    disbursalQuery += '      ORDER BY createdDate ASC' ;
    for(Disbursal__c disbursal : Database.query(disbursalQuery)){
      disbursalList.add(disbursal);
    }
    return disbursalList;
  }

  //the updateDisbursals method updates the confirmation field on the disbursal on partner action within the SLP
  @AuraEnabled
  public static void updateDisbursals(String disbursalId, Boolean disbursalValue) {
    List<Disbursal__c> disbursalList = new List<Disbursal__c>();
    String disbursalQuery = 
        '      SELECT Id, Name, Partner_Confirmation__c  ' +
        '      FROM Disbursal__c' +
        '      WHERE Id =  \'' + disbursalId +  '\' ' +
        '      AND Partner__r.Id =  \'' + profile.partnerId +  '\' ' ;
    if (profile.LicenseType != 'Executive') {
      disbursalQuery += '    AND Sales_Representative__r.Id =  \'' + profile.salesRepId +  '\' ' ;
    }
    disbursalQuery += '      LIMIT 1' ;
    for (Disbursal__c disbursal : Database.query(disbursalQuery)) {
      disbursal.Partner_Confirmation__c = disbursalValue;
      disbursalList.add(disbursal);
    }
    update disbursalList;
  }
    
  //the saveCustomerInformation method allows the user to enter in the customer's system information/commencement date to the SLP and save it to SF
  @AuraEnabled
  public static void saveCustomerInformation(Residential_Equipment__c equipmentFromComponent, String equipmentId, String loanId, Loan__c loan) {
	String nameVar;
	Boolean interconnectionUpdateDummy;

	Residential_Equipment__c equipmentRecord = [
        SELECT Id, Lead__r.Id, Loan__r.Name, Name, Loan__r.Sales_Agent__r.Partner__r.Id, Auto_Reporting_to_PTS__c,
            GE_Serial_Number__c, Interconnection_Update_Dummy__c, Loan__r.State__c, Loan__r.Sales_Agent__r.Id,
            Loan__r.Sales_Agent__r.Name, Billing_City__c, Billing_Zip__c, CEC_Production_Tracking_System_ID_Number__c,
            Commonwealth_Solar_Rebate_Program__c, Concatenated_Inverter_Type__c, Concatenated_Module_Type__c,
            Contract_Execution_Date__c, DOER_Solar_Loan__c, Estimated_On_Site_Behind_the_Meter_Load__c,
            Generator_Energized_Online_Date__c, Generator_Installation_Date__c, Generator_Interconnection_Date__c,
            Generator_Nameplate_Capacity__c, Generator_Type__c, Initial_Solar_Meter_Reading__c, Annual_Production_kWh_kW__c,
            Initial_Solar_Meter_Reading_Date__c, Interconnected__c, Interconnection_Date__c, Inverter_Manufacturer__c,
            Inverter_Model_Number__c, Lead__c, Loan__c, MA_Facility_Sector__c, MA_Facility_Type__c, Mechanical_Installation_Date__c,
            Mechanically_Installed__c, Module_Array_Azimuth__c, Module_Array_Mounting_Type__c, Module_Array_Tilt__c,
            Module_Manufacturer__c, Module_Model_Number__c, Module_Mounting_Location__c, Module_Power_Rating__c,
            Number_of_Inverters__c, Number_of_Meters__c, Number_of_Modules__c, Opportunity__c, Opportunity_Custom_ID__c,
            Opportunity_Name__c, Percentage_of_System_Shaded__c, PowerClerk_Application_ID__c, Remote_Monitorin_Systegm_Identifier__c,
            Remote_Monitoring_System_Vendor__c, Solar_Meter_Manufacturer__c, Solar_Meter_Model__c, Solar_Meter_Serial_Number__c,
            SREC_Opt_In_Calendar_Quarter__c, System_Size_from_Opp__c, System_Size_Differs__c, Type_of_Inverter__c,
            Type_of_Module__c, Unique_ID__c, Loan__r.DOER_Solar_Loann__c
        FROM Residential_Equipment__c
        WHERE Id = : equipmentId];

	if (String.isNotBlank(equipmentFromComponent.Module_Manufacturer__c)
		&& String.isNotBlank(equipmentFromComponent.Inverter_Manufacturer__c)) {
		nameVar = equipmentRecord.Loan__r.Name + ' ' + equipmentFromComponent.Module_Manufacturer__c + '/' + equipmentFromComponent.Inverter_Manufacturer__c;
		if (nameVar.length() >= 80) {
		  nameVar = nameVar.substring(0,80);
		}
		equipmentRecord.Name = nameVar;
	}
	updateEquipmentFieldFromInput(equipmentFromComponent, equipmentRecord);
	if (equipmentRecord.Interconnection_Update_Dummy__c && (equipmentRecord.Interconnected__c || equipmentFromComponent.Interconnected__c)) {
	  interconnectionUpdateDummy = false;
	} else {
	  interconnectionUpdateDummy = true;
	}
	equipmentRecord.Interconnection_Update_Dummy__c = interconnectionUpdateDummy;
	update equipmentRecord;

	if (loan.Estimated_Completion_Date__c != null) {
        Loan__c loanRecord = new Loan__c(
            Id = loanId,
            Commencement_Datee__c = loan.Estimated_Completion_Date__c + (equipmentRecord.Loan__r.DOER_Solar_Loann__c?45:30),
            Estimated_Completion_Date__c = loan.Estimated_Completion_Date__c
        );
        update loanRecord;
	}

	//update the lead record update dummy to run the partner task validation to update the status of the customer's process.
	Lead leadRecord = [SELECT Id, Update_Dummy__c, Requested_Loan_Amount__c
					   FROM Lead
					   WHERE Id = : equipmentRecord.Lead__r.Id];

	leadRecord.Update_Dummy__c = !leadRecord.Update_Dummy__c;
	leadRecord.System_Size_kW_DC__c = equipmentFromComponent.Generator_Nameplate_Capacity__c;
	update leadRecord;
  }

  @AuraEnabled
  public static void updateBuildingPermit(Residential_Equipment__c equipment) {
    update equipment;
  }

  @AuraEnabled
  public static void updateEquipmentFieldFromInput(Residential_Equipment__c equipmentFromComponent, Residential_Equipment__c equipmentToBeUpdated) {
    Map<String, Object> equipmentFieldMap = new Map<String,Object>(equipmentFromComponent.getPopulatedFieldsAsMap());
    for (String fieldName : equipmentFieldMap.keySet()) {
      if (equipmentFieldMap.get(fieldName) instanceof Integer || equipmentFieldMap.get(fieldName) instanceof Double) {
        if (equipmentFieldMap.get(fieldName) != null) {
          equipmentToBeUpdated.put(fieldName, equipmentFromComponent.get(fieldName));
        }
      } else if (equipmentFieldMap.get(fieldName) instanceof String) {
          if (String.isNotBlank((String)equipmentFieldMap.get(fieldName))) {
            equipmentToBeUpdated.put(fieldName, equipmentFromComponent.get(fieldName));
          }
      } else if (equipmentFieldMap.get(fieldName) instanceof Boolean) {
          equipmentToBeUpdated.put(fieldName, equipmentFromComponent.get(fieldName));
      } else if (equipmentFieldMap.get(fieldName) instanceof Date) {
          if (equipmentFieldMap.get(fieldName) != null) {
            equipmentToBeUpdated.put(fieldName, equipmentFromComponent.get(fieldName));
          }
      }
    }
    update equipmentToBeUpdated;
  }

  @AuraEnabled
  public static SLPortal_Settings__c getSLPortalSettings() {
      return BlueWaveParent.getSLPortalCustomSetting()[0];
  }

  @AuraEnabled
  public static Decimal getFirstDisbursal(Id loanId) {
      Loan__c loan = [
          SELECT Id, Name, Product__r.Disbursal_Terms__c, Partner__r.Name, Partner__r.Id, Sales_Agent__r.Id,
              Requested_Loan_Amount__c
          FROM Loan__c
          WHERE Id = :loanId];
      return DisbursalHandler.createDisbursalsFromDisbursalTermsField(loan)[0].Amount__c;
  }

    @AuraEnabled
    public static Boolean sendCommunitySolarApplication (String[] emailAddress) {
        String startApplicationUrl;

        String host = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        startApplicationUrl = host + 'apply/s/csap';
        if (profile.partnerId != null && profile.salesRepId != null) {
            startApplicationUrl += '?partnerId=' + profile.partnerId + '&salesRepId=' + profile.salesRepId;
        }

        return MessagingService.createAndSendDynamicTemplateEmail('SLP_Community_Solar_Application', 'customercare@bluewavesolar.com', 'Start Your Community Solar Application Here',
                                                                     emailAddress, 'applicationURL', startApplicationUrl);
    }

    @AuraEnabled
    public static String getCommunitySolarApplicationURL() {
        String startApplicationUrl;

        String host = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        startApplicationUrl = host + 'slportal/s/community-solar-application';
        if (profile.partnerId != null && profile.salesRepId != null) {
            startApplicationUrl += '?partnerId=' + profile.partnerId + '&salesRepId=' + profile.salesRepId;
        }

        return startApplicationUrl;
    }

    @AuraEnabled
    public static Residential_Equipment__c saveChangeOrder(Id loanId, String loanSystemInformation) {
        Residential_Equipment__c re = getCustomerInformation(loanId);

        Map<String, Object> changeOrder = (Map<String, Object>) JSON.deserializeUntyped(loanSystemInformation);
        if (requiresCustomerAuthorization(re, changeOrder)) {
            changeOrder.put('RequestedBy__change', UserInfo.getName());
            changeOrder.put('RequestedDate__change', Datetime.now().format('MM/dd/yyyy HH:mm'));
            re.Loan__r.Lead__r.Change_Order_Status__c = 'Requested';
            re.Loan__r.Lead__r.Loan_System_Information__c = JSON.serializePretty(changeOrder);
            re.Loan__r.Lead__r.Storage__c = (Boolean) changeOrder.get('Storage__change');
            update re.Loan__r.Lead__r;
            MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
            ee.emailTemplateName = 'RS_SLP_Review_Change_Order';
            ee.orgWideEmail = 'customercare@bluewavesolar.com';
            ee.subjectLine = 'BlueWave Solar Loan - Review a Change';
            ee.addressList = new List<String>{re.Loan__r.Lead__r.Email};
            ee.replacementTexts = new List<MessagingService.ReplacementText>();
            ee.replacementTexts.add(new MessagingService.ReplacementText('{!Lead.FirstName}', re.Loan__r.Lead__r.FirstName));
            ee.replacementTexts.add(new MessagingService.ReplacementText('{!partnerName}', re.Loan__r.Partner__r.Name));
            ee.replacementTexts.add(new MessagingService.ReplacementText('{!startApplication}', SLPAddCustomer.getCAPUrl(re.Loan__r.Lead__c)));
            ee.sobjectId = re.Loan__r.Lead__r.ConvertedContactId!=null?re.Loan__r.Lead__r.ConvertedContactId:re.Loan__r.Lead__c;
            MessagingService.sendEmailTemplate(ee);
            return re;
        } else {
            re.Generator_Nameplate_Capacity__c = (Decimal) changeOrder.get('Generator_Nameplate_Capacity__change');
            re.Module_Manufacturer__c = (String) changeOrder.get('Module_Manufacturer__change');
            re.Module_Model_Number__c = (String) changeOrder.get('Module_Model_Number__change');
            re.Number_of_Modules__c = (Integer) changeOrder.get('Number_of_Modules__change');
            re.Inverter_Manufacturer__c = (String) changeOrder.get('Inverter_Manufacturer__change');
            re.Inverter_Model_Number__c = (String) changeOrder.get('Inverter_Model_Number__change');
            re.Number_of_Inverters__c = (Integer) changeOrder.get('Number_of_Inverters__change');
            if ((Boolean) changeOrder.get('Storage__change')) {
                re.Storage_Full_or_Partial_Home__c = (String) changeOrder.get('Storage_Full_or_Partial_Home__change');
                re.Storage_Capacity__c = (Integer) changeOrder.get('Storage_Capacity__change');
                re.Storage_Manufacturer__c = (String) changeOrder.get('Storage_Manufacturer__change');
                re.Storage_Model__c = (String) changeOrder.get('Storage_Model__change');
                re.Storage_Inverter_Manufacturer__c = (String) changeOrder.get('Storage_Inverter_Manufacturer__change');
                re.Storage_Inverter_Model__c = (String) changeOrder.get('Storage_Inverter_Model__change');
                re.Loan__r.Lead__r.Storage__c = (Boolean) changeOrder.get('Storage__change');
                if (changeOrder.get('Storage_Grid_Hybrid__change') == 'Yes') {
                    re.Storage_Grid_Hybrid__c = true;
                } else {
                    re.Storage_Grid_Hybrid__c = false;
                    re.Storage_Full_or_Partial_Home__c = null;
                }
                update re.Loan__r.Lead__r;
            } else {
                re.Storage_Grid_Hybrid__c = false;
                re.Storage_Full_or_Partial_Home__c = null;
                re.Storage_Capacity__c = null;
                re.Storage_Manufacturer__c = null;
                re.Storage_Model__c = null;
                re.Storage_Inverter_Manufacturer__c = null;
                re.Storage_Inverter_Model__c = null;
                re.Loan__r.Lead__r.Storage__c = false;
                update re.Loan__r.Lead__r;
            }
            if (changeOrder.get('Estimated_Completion_Date__change') != '') {
                re.Loan__r.Estimated_Completion_Date__c = Date.parse((String) changeOrder.get('Estimated_Completion_Date__change'));
                Loan__c loan = re.Loan__r;
                loan.Commencement_Datee__c = re.Loan__r.Estimated_Completion_Date__c + (re.Loan__r.DOER_Solar_Loann__c?45:30);
                update loan;
            } else {
                re.Loan__r.Commencement_Datee__c = null;
                re.Loan__r.Estimated_Completion_Date__c = null;
                update re.Loan__r;
            }
            update re;

            // Toggling Update Dummy on Lead checks RE and closes out the Provide System Info task if complete
            Lead lead = new Lead(
                Id = re.Loan__r.Lead__c,
                Update_Dummy__c = !re.Loan__r.Lead__r.Update_Dummy__c
            );
            update lead;
            re.Loan__r.Lead__r.Loan_System_Information__c = JSON.serializePretty(changeOrder);

            if (LoanHandler.equipmentPopulated(re) &&
                (re.Loan__r.Lead__r.CAP_Stage__c == 'NAV_Confirmations' ||
                    re.Loan__r.Lead__r.CAP_Stage__c == 'NAV_Income_Doc')) {
                DocuSignHelper.sendLoanPackageFuture(re.Opportunity__c);
            }
            return re;
        }
    }

    public static Boolean requiresCustomerAuthorization(Residential_Equipment__c re, Map<String, Object> changeOrder) {
        // If there's no change to Requested Loan Amount, System Cost, or Equipment info, or if DocuSign hasn't been
        // sent, there's no need for customer authorization
        if (re.Loan__r.Lead__r.Requested_Loan_Amount__c == (Decimal) changeOrder.get('System_Cost__change') - Util.nullToZero((Decimal) changeOrder.get('Down_Payment__change')) &&
            re.Loan__r.Lead__r.System_Cost__c == changeOrder.get('System_Cost__change')) {
            if (re.Loan__r.Opportunity__c == null ||
                (re.Loan__r.Opportunity__c != null && !docuSignPresent(re.Loan__r.Opportunity__c))) { // There's no DocuSign yet
                return false;
            }
        }
        return true;
    }

    @AuraEnabled
    public static Boolean docuSignPresent(Id oppId) {
        if (oppId == null) {
            throw new Util.BWException('SLPCustomerHandler.docuSignPresent called with null OppId');
        }
        List<dsfs__DocuSign_Status__c> docuSignStatuses = [
            SELECT Id, dsfs__Envelope_Status__c
            FROM dsfs__DocuSign_Status__c
            WHERE dsfs__Opportunity__c = : oppId
        ];
        return !docuSignStatuses.isEmpty();
    }

    @AuraEnabled
    public static Residential_Equipment__c withdrawChangeOrder(Id loanId) {
        Residential_Equipment__c re = getCustomerInformation(loanId);
        String loanSystemInformation = re.Loan__r.Lead__r.Loan_System_Information__c;
        Map<String, Object> changeOrder = (Map<String, Object>) JSON.deserializeUntyped(loanSystemInformation);
        if (changeOrder == null) {
            return null;
        }
        for (String s : changeOrder.keySet()) {
            if (s.contains('__change')) {
                changeOrder.remove(s);
            }
        }
        re.Loan__r.Lead__r.Change_Order_Status__c = 'Installer Withdrawn';
        re.Loan__r.Lead__r.Loan_System_Information__c = JSON.serializePretty(changeOrder);
        update re.Loan__r.Lead__r;

        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = 'RS_SLP_Withdraw_Change_Order';
        ee.orgWideEmail = 'customercare@bluewavesolar.com';
        ee.subjectLine = 'BlueWave Solar Loan - Withdraw a Change';
        ee.addressList = new List<String>{re.Loan__r.Lead__r.Email, re.Loan__r.Sales_Agent__r.Email__c};
        ee.replacementTexts = new List<MessagingService.ReplacementText>();
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!Lead.FirstName}', re.Loan__r.Lead__r.FirstName));
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!partnerName}', re.Loan__r.Partner__r.Name));
        ee.replacementTexts.add(new MessagingService.ReplacementText('{!startApplication}', SLPAddCustomer.getCAPUrl(re.Loan__r.Lead__c)));
        ee.sobjectId = re.Loan__r.Lead__r.ConvertedContactId!=null?re.Loan__r.Lead__r.ConvertedContactId:re.Loan__r.Lead__c;
        MessagingService.sendEmailTemplate(ee);
        return re;
    }

    @AuraEnabled
    public static Decimal getMaximumLoanAmount(Id loanId) {
        Loan__c loan = [
            SELECT Id, Product__r.Name, Product__r.Loan_Interest_Rate__c, Product__r.Loan_Term__c,
                Product__r.Debt_To_Income_Maximum__c, Product__r.DTI_After_Rate_Gross_Up__c, Product__r.Program__c,
                Requested_Loan_Amount__c, Product__r.Maximum_Loan_Size__c,
                Lead__r.Personal_Credit_Report__c,
                Lead__r.Personal_Credit_Report__r.Adjusted_Income__c, Lead__r.Annual_Income_Currency__c,
                Lead__r.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c,
                Lead__r.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c,
                Lead__r.Personal_Credit_Report_Co_Applicant__c,
                Lead__r.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c, Lead__r.CoApplicant_Contact__r.Income__c,
                Lead__r.Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c,
                Lead__r.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c
            FROM Loan__c
            WHERE Id = :loanId];
        Decimal maxDTI = loan.Product__r.Debt_To_Income_Maximum__c / 100;
        if (loan.Product__r.Program__c == 'MSLP') {
            Decimal maxFICO = Integer.valueOf(loan.Lead__r.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c);
            if (loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c != null &&
                Integer.valueOf(loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c) > maxFICO) {
                maxFICO = Integer.valueOf(loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c);
            }
            if (maxFICO >= 700) {
                maxDTI = .50;
            } else if (maxFICO >= 690) {
                maxDTI = .45;
            } else if (maxFICO >= 680) {
                maxDTI = .40;
            }
        }
        Decimal monthlyRate = (loan.Product__r.Loan_Interest_Rate__c + Util.nullToZero(loan.Product__r.DTI_After_Rate_Gross_Up__c)) / 12 / 100;
        Decimal monthlyIncome = 0;
        if (loan.Lead__r.Personal_Credit_Report__c != null) {
            if (loan.Lead__r.Personal_Credit_Report__r.Adjusted_Income__c == null) {
                monthlyIncome = loan.Lead__r.Annual_Income_Currency__c/12;
            } else {
                monthlyIncome = Util.nullToZero(loan.Lead__r.Personal_Credit_Report__r.Adjusted_Income__c)/12;
            }
        }
        if (loan.Lead__r.Personal_Credit_Report_Co_Applicant__r != null) {
            if (loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c != null) {
                monthlyIncome += loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c/12;
            } else {
                monthlyIncome += Util.nullToZero(loan.Lead__r.CoApplicant_Contact__r.Income__c)/12;
            }
        }
        Decimal monthlyDebt = 0;
        if (loan.Lead__r.Personal_Credit_Report__c != null) {
            monthlyDebt = loan.Lead__r.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c;
        }
        if (loan.Lead__r.Personal_Credit_Report_Co_Applicant__r != null) {
            monthlyDebt += loan.Lead__r.Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c;
        }
        Decimal maxMonthlyPayment = maxDTI * monthlyIncome - monthlyDebt;
        // from http://www.iotafinance.com/en/Formula-Maximum-Loan-Amount.html
        Decimal maxLoanAmount =
            maxMonthlyPayment * (1 - Math.pow((Double)(1 + monthlyRate), (Integer) -loan.Product__r.Loan_Term__c)) / monthlyRate;

        if (loan.Product__r.Maximum_Loan_Size__c != null) {
            return Math.min(loan.Product__r.Maximum_Loan_Size__c, maxLoanAmount);
        } else {
            return maxLoanAmount;
        }
    }

    @AuraEnabled
    public static Boolean getStorageEnabled() {
        SLPUserHelper.PartnerProfile profile = SLPUserHelper.getPartnerProfile();
        return profile.storageEnabled;
    }
}