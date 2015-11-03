/*
	Purpose: - Controller for the ECO_DelegateManager Visualforce Page

	Created By: Aaron Pettitt (NTT Data)

	Revision Log: 
		v1.0 - (AP 09/17/2015) -- created 
*/
public class ECO_DelegateManagerController {
	public Contact contact {get; set;} //contact details for the selected contact
	public Boolean isError {get; set;} //if the page is in an error condition
	public Delegate__c delegate {get; set;} //the new delegate record to be added
	public Map<String, Id> delegateRecordTypeMap {get; set;}//map to store the record type name to the id for the delegate object
	public String currentRecordType {get; set;}//the current record type selected on the tab
	public ECO_Delegate_Limits__c delegateLimitSettings{get; set;}//the delegate limit setting amounts for the current contact
	public List<RecordType> recordTypes{get; set;}//the list of recordTypes for the Delegate object
	public String agreementAmountBypass{get; set;}
	public String projectRevenueBudgetBypass{get; set;}
	public String projectRevenueBudgetBypassLT{get; set;}
	public String backlogValueBypass{get; set;}
	public String backlogValueBypassLT{get; set;}
	public String projectNetMarginValueBypass{get; set;}
	public String projectNetMarginValueBypassLT{get; set;}
	public String projectNetMarginNSRBypass{get; set;}
	public String projectNetMarginNSRBypassLT{get; set;}
	public String percentageChangeInForecastBypass{get; set;}
	public String percentageChangeInForecastBypassLT{get; set;}
	public String valueChangeInForecastNetMarginBypass{get; set;}
	public String valueChangeInForecastNetMarginBypassLT{get; set;}
	public List<owningOrganization> owningOrganizations{get; set;}
	public String c0Bypass{get; set;}
	public String c1Bypass{get; set;}
	public String c2Bypass{get; set;}
	public String c3Bypass{get; set;}
	public String c4Bypass{get; set;}
	private Id keyRolesRecordType;
	private String redirectUrl;  //stores the url of the page to return to
	private String contactId; //stores the contactId from the query parameter
	private String query; //stores the contact query text
	private List<PermissionSetAssignment> currentUserPermissionSets = new List<PermissionSetAssignment>(); //a list of the current logged in user permission sets

	//constructor
	public ECO_DelegateManagerController(){
		isError = false;

		if(ApexPages.currentPage().getParameters().get('retUrl') != null){
			redirectUrl = ApexPages.currentPage().getParameters().get('retUrl');
		}

		if(ApexPages.currentPage().getParameters().get('contactId') != null){
			contactId = ApexPages.currentPage().getParameters().get('contactId');
		}

		//retrieve the record types for the tab panel
		delegateRecordTypeMap = new Map<String, Id>();
		recordTypes = [Select Id, Name from RecordType where SobjectType = 'Delegate__c'];
		for(RecordType recordType : recordTypes){
			delegateRecordTypeMap.put(recordType.Name, recordType.Id);
			if(recordType.Name == 'Key Roles'){
				keyRolesRecordType = recordType.Id;
			}
		}

		try{
			currentUserPermissionSets = [select PermissionSet.Name from PermissionSetAssignment where Assignee.Id =: UserInfo.getUserId() AND PermissionSet.Name = 'ECO_Delegations_Adminstrator'];
		}
		catch(Exception ex){
			//this user doesn't have the required permission set
		}

		currentRecordType = 'Key Roles';
		//retrieve contact and delegates info
		//try{
			queryContact(keyRolesRecordType);

			//retrieve the delegate amount limits
			if(contact.pse__Salesforce_User__c != null && ECO_Delegate_Limits__c.getInstance(contact.pse__Salesforce_User__c) != null){
				delegateLimitSettings = ECO_Delegate_Limits__c.getInstance(contact.pse__Salesforce_User__c);
			}
			else{
				delegateLimitSettings = ECO_Delegate_Limits__c.getOrgDefaults();
			}
		//}
		/*catch(Exception ex){
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The contact Id is either null or invalid. ' + ex.getMessage()));
			system.debug(ex.getMessage());

		}*/
	}

	//returns the current user's currency format
	public String currentCurrency{
		get{
			return UserInfo.getDefaultCurrency();
		}
		set;
	}

	//returns the select options for the yes/no radio buttons
	public List<SelectOption> yesNoOptions{
		get{
			List<SelectOption> options = new List<SelectOption>();
			options.add(new SelectOption('Yes', 'Yes'));
			options.add(new SelectOption('No', 'No'));
			return options;
		}
		set;
	}

	//if the current user can edit values on the page
	public Boolean canEdit{
		get{
			if(canCreateAlternate || currentUserPermissionSets.size() > 0){
				return true;
			}
			return false;
		}
		set;
	}

	//if the current user can create an alternate delegate for themself
	public Boolean canCreateAlternate{
		get{
			if(contact != null && UserInfo.getUserId() == contact.pse__Salesforce_User__c){
				return true;
			}
			return false;
		}
		set;
	}

	//sets the currentRecordType viewstate variable to the proper recordtype for the tab panel.
	public PageReference changeTabFields(){
		String recordTypeId = ApexPages.currentPage().getParameters().get('recordTypeId');
		for(String delegateRecordType : delegateRecordTypeMap.keySet()){
			if(delegateRecordTypeMap.get(delegateRecordType) == recordTypeId){
				currentRecordType = delegateRecordType;
			}
		}
		queryContact(recordTypeId);
		return null;
	}

	//adds a new delegate entry for the contact
	public PageReference addNewDelegate(){
		try{
			setYesNoFieldValues();
			if(isValid()){
				Boolean anyOrgChecked = false;
				//save all of the selected organizations
				if(delegate.recordTypeId == keyRolesRecordType && owningOrganizations.size() > 0){
					delegate.Allowed_Organizations__c = '';
					
					for(owningOrganization organization : owningOrganizations){
						if(organization.checked){
							delegate.Allowed_Organizations__c += organization.organization.Id + ';';
							anyOrgChecked = true;
						}
					}
				}
				else{
					anyOrgChecked = true;
				}
				if(anyOrgChecked){
					insert delegate;
					queryContact(delegateRecordTypeMap.get(currentRecordType));
				}
				else{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one organization for the key member'));
				}
			}
		}
		catch(Exception ex){
			//we don't want to have duplicate error messages on the page
			if(!ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Inserting Delegate: ' + ex.getMessage()));
			}
		}
		return null;
	}

	//verifies the limit values are less than the maximum amount
	private Boolean isValid(){
		Boolean valid = true;
		if(delegate.Agreement_Amount_estimated__c > delegateLimitSettings.Agreement_Amount__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Agreement Amount is greater than allowed Maximum'));
		}
		if(delegate.Project_Revenue_Budget__c > delegateLimitSettings.Project_Revenue_Budget__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Revenue Budget is greater than allowed Maximum'));
		}
		if(delegate.Project_Revenue_Budget_lt__c < delegateLimitSettings.Project_Revenue_Budget_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Revenue Budget is less than allowed Minimum'));
		}
		if(delegate.Backlog_Value__c > delegateLimitSettings.Backlog_Value__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Backlog Value is greater than allowed Maximum'));
		}
		if(delegate.Backlog_Value_lt__c < delegateLimitSettings.Backlog_Value_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Backlog Value is less than allowed Minimum'));
		}
		if(delegate.Project_Net_Margin_Value__c > delegateLimitSettings.Project_Net_Margin_Value__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Net Margin Value is greater than allowed Maximum'));
		}
		if(delegate.Project_Net_Margin_Value_lt__c < delegateLimitSettings.Project_Net_Margin_Value_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Net Margin Value is less than allowed Minimum'));
		}
		if(delegate.Project_Net_Margin_age_of_NSR__c > delegateLimitSettings.Project_Net_Margin_age_of_NSR__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Net Margin Percentage of NSR is greater than allowed Maximum'));
		}
		if(delegate.Project_Net_Margin_age_of_NSR_lt__c < delegateLimitSettings.Project_Net_Margin_age_of_NSR_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project Net Margin Percentage of NSR is less than allowed Minimum'));
		}
		if(delegate.age_Change_in_Forecast_Net_Margin__c > delegateLimitSettings.age_Change_in_Forecast_Net_Margin__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Percentage Change in Forecast Net Margin is greater than allowed Maximum'));
		}
		if(delegate.age_Change_in_Forecast_Net_Margin_lt__c < delegateLimitSettings.age_Change_in_Forecast_Net_Margin_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Percentage Change in Forecast Net Margin is less than allowed Minimum'));
		}
		if(delegate.Value_change_in_Forecast_Net_Margin__c > delegateLimitSettings.Value_change_in_Forecast_Net_Margin__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Value Change in Forecast Net Margin is greater than allowed Maximum'));
		}
		if(delegate.Value_change_in_Forecast_Net_Margin_lt__c < delegateLimitSettings.Value_change_in_Forecast_Net_Margin_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Value Change in Forecast Net Margin is less than allowed Minimum'));
		}
		if(delegate.Value_change_in_Forecast_Net_Margin__c > delegateLimitSettings.Value_change_in_Forecast_Net_Margin__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Value Change in Forecast Net Margin is greater than allowed Maximum'));
		}
		if(delegate.Value_change_in_Forecast_Net_Margin_lt__c < delegateLimitSettings.Value_change_in_Forecast_Net_Margin_lt__c){
			valid = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Value Change in Forecast Net Margin is less than allowed Minimum'));
		}
		return valid;
	}

	//converts the yes/no field questions to the associated delegate field checkbox
	private void setYesNoFieldValues(){
		if(agreementAmountBypass == 'Yes'){
			delegate.Agreement_Amount_estimated_Bypass__c = true;
		}
		else{
			delegate.Agreement_Amount_estimated_Bypass__c = false;
		}

		if(projectRevenueBudgetBypass == 'Yes'){
			delegate.Project_Revenue_Budget_Bypass__c = true;
		}
		else{
			delegate.Project_Revenue_Budget_Bypass__c = false;
		}

		if(projectRevenueBudgetBypassLT == 'Yes'){
			delegate.Project_Revenue_Budget_Bypass_lt__c = true;
		}
		else{
			delegate.Project_Revenue_Budget_Bypass_lt__c = false;
		}

		if(backlogValueBypass == 'Yes'){
			delegate.Backlog_Value_Bypass__c = true;
		}
		else{
			delegate.Backlog_Value_Bypass__c = false;
		}

		if(backlogValueBypassLT == 'Yes'){
			delegate.Backlog_Value_Bypass_lt__c = true;
		}
		else{
			delegate.Backlog_Value_Bypass_lt__c = false;
		}


		if(projectNetMarginValueBypass == 'Yes'){
			delegate.Project_Net_Margin_Value_Bypass__c = true;
		}
		else{
			delegate.Project_Net_Margin_Value_Bypass__c = false;
		}

		if(projectNetMarginValueBypassLT == 'Yes'){
			delegate.Project_Net_Margin_Value_Bypass_lt__c = true;
		}
		else{
			delegate.Project_Net_Margin_Value_Bypass_lt__c = false;
		}

		if(projectNetMarginNSRBypass == 'Yes'){
			delegate.Project_Net_Margin_age_of_NSR_Bypass__c = true;
		}
		else{
			delegate.Project_Net_Margin_age_of_NSR_Bypass__c = false;
		}

		if(projectNetMarginNSRBypassLT == 'Yes'){
			delegate.Project_Net_Margin_of_NSR_Bypass_lt__c = true;
		}
		else{
			delegate.Project_Net_Margin_of_NSR_Bypass_lt__c = false;
		}

		if(percentageChangeInForecastBypass == 'Yes'){
			delegate.age_Change_in_Forecast_Net_Margin_Bypass__c = true;
		}
		else{
			delegate.age_Change_in_Forecast_Net_Margin_Bypass__c = false;
		}

		if(percentageChangeInForecastBypassLT == 'Yes'){
			delegate.age_Change_in_Forecast_Net_Margin_Byp_lt__c = true;
		}
		else{
			delegate.age_Change_in_Forecast_Net_Margin_Byp_lt__c = false;
		}

		if(valueChangeInForecastNetMarginBypass == 'Yes'){
			delegate.Value_change_in_Forecast_Net_Margin_Byps__c = true;
		}
		else{
			delegate.Value_change_in_Forecast_Net_Margin_Byps__c = false;
		}

		if(valueChangeInForecastNetMarginBypassLT == 'Yes'){
			delegate.Value_change_Forecast_Nt_Margn_Byps_lt__c = true;
		}
		else{
			delegate.Value_change_Forecast_Nt_Margn_Byps_lt__c = false;
		}

		if(c0Bypass == 'Yes'){
			delegate.Project_Review_Category_C_0_Bypass__c = true;
		}
		else{
			delegate.Project_Review_Category_C_0_Bypass__c = false;
		}

		if(c1Bypass == 'Yes'){
			delegate.Project_Review_Category_C_1_Bypass__c = true;
		}
		else{
			delegate.Project_Review_Category_C_1_Bypass__c = false;
		}


		if(c2Bypass == 'Yes'){
			delegate.Project_Review_Category_C_2_Bypass__c = true;
		}
		else{
			delegate.Project_Review_Category_C_2_Bypass__c = false;
		}

		if(c3Bypass == 'Yes'){
			delegate.Project_Review_Category_C_3_Bypass__c = true;
		}
		else{
			delegate.Project_Review_Category_C_3_Bypass__c = false;
		}

		if(c4Bypass == 'Yes'){
			delegate.Project_Review_Category_C_4_Bypass__c = true;
		}
		else{
			delegate.Project_Review_Category_C_4_Bypass__c = false;
		}


	}

	//runs the query for the contact and delegates.  Initializes the delegate so a new one can be added
	private void queryContact(String recordTypeId){
		contact = Database.query(buildSOQL(recordTypeId));
		delegate = new Delegate__c(Delegator__c = contact.Id, 
									RecordTypeId = keyRolesRecordType,
									Project_Review_Category_C_0__c = true,
									Project_Review_Category_C_1__c = true,
									Project_Review_Category_C_2__c = true,
									Project_Review_Category_C_3__c = true,
									Project_Review_Category_C_4__c = true);
		
		if(recordTypeId == keyRolesRecordType){
			resetBypassYesNoFields();
			populateOwningOrganizations();
		}
	}

	//loads the list owningOrganization wrapper for the owning organization table
	private void populateOwningOrganizations(){
		//retrieve field string from fieldset
		owningOrganizations = new List<owningOrganization>();
		List<ProjectTeamMember__c> projectTeamMembers = new List<ProjectTeamMember__c>();
		if(contactId != null){
			projectTeamMembers = [Select Id, Project__c from ProjectTeamMember__c where Contact__c =: contactId and (ProjectRole__r.Name = 'Project Approver 2' OR ProjectRole__r.Name = 'Finance Lead')];
		}
		else{
			projectTeamMembers = [Select Id, Project__c from ProjectTeamMember__c where Contact__r.pse__Salesforce_User__c =: UserInfo.getUserId() and (ProjectRole__r.Name = 'Project Approver 2' OR ProjectRole__r.Name = 'Finance Lead')];
		}
		Set<Id> projectIds = new Set<Id>();
		for(ProjectTeamMember__c projectTeamMember : projectTeamMembers){
			projectIds.add(projectTeamMember.Project__c);
		}
		if(projectIds.size() > 0){
			Set<String> organizationStringFields = ECO_Utils_sObject.getFieldSetMembers('Delegate_Owning_Organization_Table', 'OrganizationString__c');
			
			if(organizationStringFields.size() > 0){
				String queryFields = '';

				//create the query field string 
				for(String organizationStringField : organizationStringFields){
					queryFields += 'CarryingOutOrganization__r.' + organizationStringField + ', ';
				}

				//query string
				String query = 'Select Id, CarryingOutOrganization__c, ' + queryFields.removeEnd(', ') + ' From pse__Proj__c where Id IN : projectIds';
				List<pse__Proj__c> projects = Database.query(query);
				Set<Id> organizationIdsUsed = new Set<Id>();

				//load the owningOrganizations wrapper from query results
				for(pse__Proj__c project : projects){
					if(!organizationIdsUsed.contains(project.CarryingOutOrganization__c)){
						organizationIdsUsed.add(project.CarryingOutOrganization__c);
						owningOrganizations.add(new owningOrganization(project.CarryingOutOrganization__r));
					}
				}
			}
		}
	}

	//resets all of the yes/no bypass delegate fields to yes
	private void resetBypassYesNoFields(){
		agreementAmountBypass = 'Yes';
		projectRevenueBudgetBypass = 'Yes';
		projectRevenueBudgetBypassLT = 'Yes';
		backlogValueBypass = 'Yes';
		backlogValueBypassLT = 'Yes';
		projectNetMarginValueBypass = 'Yes';
		projectNetMarginValueBypassLT = 'Yes';
		projectNetMarginNSRBypass = 'Yes';
		projectNetMarginNSRBypassLT = 'Yes';
		percentageChangeInForecastBypass = 'Yes';
		percentageChangeInForecastBypassLT = 'Yes';
		valueChangeInForecastNetMarginBypass = 'Yes';
		valueChangeInForecastNetMarginBypassLT = 'Yes';
		c0Bypass = 'Yes';
		c1Bypass = 'Yes';
		c2Bypass = 'Yes';
		c3Bypass = 'Yes';
		c4Bypass = 'Yes';
	}

	//returns the query string for the delegate table
	private String buildSOQL(String recordTypeId){
		//retrieve all of the fieldset fields to define the contact query
		Set<String> fieldSetFields = ECO_Utils_sObject.getFieldSetMembers('DelegationModuleContactDetails', 'Contact');
		String queryFields = '';
		Boolean foundName = false;
		Boolean foundUser = false;

		//create a soql compatible string of field names to select
		for(String fieldSetField : fieldSetFields){
			if(fieldSetField == 'Name'){
				foundName = true;
			}
			if(fieldSetField == 'pse__Salesforce_User__c'){
				foundUser = true;
			}
			queryFields += fieldSetField + ', ';
		}

		//remove the last comma so we don't receive a SOQL error
		queryFields = queryFields.removeEnd(', ');

		//the name field was not found in the field set but we need it anyway
		if(!foundName){
			queryFields += ', Name';
		}
		if(!foundUser){
			queryFields += ', pse__Salesforce_User__c';
		}

		query = 'Select ' + queryFields + ', (Select Delegate__c, End_Date__c, RecordType.Name, Key_Member_Role__c, Notes__c, Start_Date__c, CreatedBy.Name, LastModifiedDate From Delegates1__r where RecordTypeId = \'' + recordTypeId + '\') From Contact Where ';
		
		//if the contactId is passed in the query parameter			    
		if(contactId != null){
			query += 'Id = \'' + contactId + '\'';
		}
		//instead, get the current user's contact info
		else{
			query += 'pse__Salesforce_User__c = \'' + UserInfo.getUserId() + '\'';
		}
		system.debug('***recordTypeId ' + recordTypeId);
		system.debug('***query ' + query);
		return query;
	}

	//wrapper that holds the information for the owning organization table
	public class owningOrganization{
		public Boolean checked{get; set;}
		public OrganizationString__c organization{get; set;}

		public owningOrganization(OrganizationString__c org){
			checked = false;
			organization = org;
		}
	}

}