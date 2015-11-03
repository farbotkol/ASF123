public with sharing class ECO_ProjectAgreementController2 {
//

	public ProjectAgreement__c projectAgreement {get; set;}
	String recordTypeId;
	String recordToDelete;
	public String projectId {get; set;}
	public String selectedRecordType {get; set;}
	public pse__Proj__c theProject {get; set;}
	public list<Agreement__c> agreements {get; set;}
	
	
	public ECO_ProjectAgreementController2(ApexPages.StandardController controller)
	{
		projectAgreement = (ProjectAgreement__c)controller.getRecord();
	}
	
	public PageReference recordTypeSelected()
	{
		pse__Proj__c projectInfo = ECO_Service_Agreement.getProjectFromId(projectAgreement.Project__c);    
        Id accountId = ECO_Service_Agreement.getSiteAccountIdFromProjPrimBillAcct(projectInfo.PrimaryBillingClient__c);
        Id projectManagerId = ECO_Service_Agreement.getProjectManagerFromProjectTeam(projectInfo.Id);
        Integer projectAgreementCount = ECO_Service_Agreement.getNextProjectAgreementCount(projectInfo.Id);
        RecordType recordType = [select Id, Name from RecordType where Id = :selectedRecordType];
        	
        String projectAgreementNumber;
        	
        if(projectInfo.OracleProjectnumber__c != null && projectInfo.OracleProjectnumber__c != '') 
        	projectAgreementNumber = projectInfo.OracleProjectnumber__c + '-' + String.valueOf(projectAgreementCount);	
        else
        	projectAgreementNumber = null;
		Agreement__c newAgreement = new Agreement__c(Project__c = projectInfo.Id, 
													Account__c = accountId, 
													RecordTypeId = selectedRecordType, 
													//OUID__c = projectInfo.OUID__c, 
													AgreementNumber__c = projectAgreementNumber,
													ProjectAgreementRecordCount__c = projectAgreementCount,
													AgreementAmountEstimated__c = projectInfo.EstimatedContractValue__c,
													ProjectTeamMember__c = projectManagerId);													
		insert newAgreement;
			
		if(recordType.Name != 'Prime (MSA)'){
			ProjectAgreement__c newProjectAgreement = new ProjectAgreement__c();
			newProjectAgreement.Project__c = projectAgreement.Project__c;
			newProjectAgreement.Agreement__c = newAgreement.Id;
			insert newProjectAgreement;
		}
			
		PageReference newAgreementRef = new PageReference('/' + newAgreement.Id);
		newAgreementRef.getParameters().put('Mode', 'New');
		newAgreementRef.getParameters().put('ProjectId', projectId);
		newAgreementRef.getParameters().put('saveURL', '/' + newAgreement.Id + '?ProjectId='+ projectInfo.Id);
    	newAgreementRef.getParameters().put('retURL', '/apex/ECO_ProjectAgreementpage?ProjectId=' + projectInfo.Id + '&RecordToDelete='+ newAgreement.Id);
			
		return 	newAgreementRef;				
	}
	
	public PageReference init()
	{				
		PageReference returnPR;
		
		recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
		recordToDelete = ApexPages.currentPage().getParameters().get('RecordToDelete');
		projectId = projectAgreement.Project__c;

		
		
		//first time you come to the project agreement, redirect to the recordtype selector page
		if(recordToDelete == null || recordToDelete == '')
		{  
			theProject = [select Name, ProjectSectionHeaderName__c from pse__Proj__c where Id = :projectId limit 1]; 
			agreements = [select Id, Name, RecordType.Name, Amount__c, AgreementStatus__c, Account__c from Agreement__c where Id in (select Agreement__c from ProjectAgreement__c where Project__c = :theProject.Id)];  
			  
        	return null;			
		}
				
		//if you cancel new agreement from agreement screen, clear the records and go back to project
		if(recordToDelete != null && recordToDelete != '')
		{
			projectId = ApexPages.currentPage().getParameters().get('ProjectId');
			Agreement__c agreementToDelete = ECO_Service_Agreement.getAgreementFromId(recordToDelete);
			delete agreementToDelete;
			
			PageReference returnToProject = new PageReference('/' + projectId);
			return returnToProject;
		}
		
		return null;	
	}	
	
	public list<RecordType> getAgreementRecordTypes()
	{
		return [select Id, Name, Description from RecordType where sObjectType = 'Agreement__c' and Name != 'Prime (MSA)'];
	}
}